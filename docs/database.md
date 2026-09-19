# Database Architecture

This document specifies the physical data relationships and core implementation decisions designed to support the Service Tenant ERP.

## Core Design Decisions

* **Strict Multi-Tenancy Isolation:** To guarantee data privacy, every operational record is tied to a single root `Organization`. Tenants can never access or view data belonging to another organization.
* **Single-Tenant User Profile:** For the initial version of this system, a `User` record is strictly linked to exactly one `Organization` and is assigned a single unique `role`. Supporting a single user profile that can connect to multiple independent organizations is a feature left for future development.
* **Target Database Engine:** The physical schema is designed specifically for **PostgreSQL**. The implementation leverages Postgre-native capabilities such as explicit Foreign keys.
* **Pragmatic Denormalization:** The physical schema intentionally violates the **Third Normal Form (3NF)** of normalization by cascading the `organization_id` down to every single table, to prevent deep, expensive relational joins and safely filter all tenant data in a single, fast operation.
* **Global Metadata Omission:** For clarity, `created_at`, `updated_at`, `organization_id`, `notes`, `description` and `is_active` (soft-delete flag) columns are omitted from visual **ERD diagrams**. This keeps the focus on core business data and relationships.
* **Unified Role-Based Authorization:** The `User` entity serves as a single unified table representing all internal actors, including both `Owner` and `Employee`. Functional permissions and access controls are dynamically determined at runtime by evaluating the user's assigned role.
* **Financial Audit Preservation:** In accordance with standard accounting principles, `Invoice` records are never physically deleted from the system. If an invoice is cancelled, its status column is mutated to `void`.
* **Tenant-scoped Authentication Credentials:** To support identical usernames or duplicate emails accros diferent tenants, the authentication system requires a unique organization `slug` alongside individual credentials at login. The application resolves the tenant by this slug first, ensuring usernames only need to be unique within their respective organization boundaries.
* **Decoupled Financial Valuation:** To protect financial integrity, a `BillableItem` generated from an `Expense` or `Task` stores and independent mutable pricing value. If the cost attributes of the task of expense changes, the contracted value remains securely unaffected.
* **Inmutable Invoicing Portions:** Once a `BillableItemPortion` is allocated to an `Invoice`, its `amount_allocated` is completely immutable. This acts as a permanent historical audit trail, allowing the system to safely recalculate remaining unbilled item balances dynamically without risking cross-document mutation.
* **Physical Table Naming Convention:** While domain entities in documentation and ERD diagrams are represented in singular form (`USER`, `PROJECT`), physical PostgreSQL tables are mapped to plural lowercase identifiers (`users`, `projects`) to aovid SQL reserved keyword collitions (such as `USER`).
* **Tenant Deletion Policy:** To prevent accidental data loss, the `organizations` table enforces `ON DELETE RESTRICT`. A tenant cannot be deleted if dependant data exist.

## Entity-Relationship Diagram (ERD)

```mermaid
erDiagram
    ORGANIZATION ||--o{ USER : has
    ORGANIZATION ||--o{ CUSTOMER : manages
    CUSTOMER ||--o{ PROJECT : orders

    PROJECT ||--o{ TASK : contains
    PROJECT ||--o{ EXPENSE : incurs
    PROJECT ||--o{ BILLABLE_ITEM : tracks
    PROJECT ||--o{ INVOICE : generates

    TASK |o--o{ BILLABLE_ITEM : converts_to
    EXPENSE |o--o{ BILLABLE_ITEM : converts_to

    BILLABLE_ITEM ||--o{ BILLABLE_ITEM_PORTION : distributes_to
    INVOICE ||--o{ BILLABLE_ITEM_PORTION : contains

    %% Task assignment and project management links
    USER ||--o{ PROJECT : manage_as_pm   
    USER ||--o{ TASK_ASSIGNMENT : receives
    TASK ||--o{ TASK_ASSIGNMENT : allocates

    ORGANIZATION {
        uuid id PK
        varchar slug UK
        varchar name
    }

    USER {
        uuid id PK
        uuid organization_id FK
        varchar name
        varchar email
        varchar role "ENUM: 'owner', 'employee'"
    }

    CUSTOMER {
        uuid id PK
        uuid organization_id FK
        varchar name
        varchar phone_number
    }

    PROJECT {
        uuid id PK
        uuid customer_id FK
        uuid manager_id FK "Reference USER.id"
        varchar name
        varchar priority "ENUM: 'low', 'medium', 'high'"       
        varchar status "ENUM: 'active', 'completed', 'on_hold', 'cancelled'"
        date start_date
        date end_date "Nullable"
    }

    TASK {
        uuid id PK
        uuid project_id FK
        varchar title
        varchar status "ENUM: 'todo', 'in_progress', 'cancelled', 'done'"
        varchar priority "ENUM: 'low', 'medium', 'high'"
        bigint labor_cost_in_cents "Nullable: Internal human resource cost"
        date due_date "Nullable"
        timestamp completed_at "Nullable"
    }

    TASK_ASSIGNMENT {
        uuid id PK
        uuid task_id FK
        uuid user_id FK
    }

    EXPENSE {
        uuid id PK
        uuid project_id FK
        bigint material_cost_in_cents "Cost regarding materials and third party tools"
        timestampsz incurred_at 
    }

    BILLABLE_ITEM {
        uuid id PK
        uuid project_id FK
        uuid task_id FK "Nullable"
        uuid expense_id FK "Nullable"
        bigint total_value_in_cents
        boolean is_written_off "Default: false"
    }

    BILLABLE_ITEM_PORTION {
        uuid id PK
        uuid billable_item_id FK
        uuid invoice_id FK
        bigint amount_allocated_in_cents
    }

    INVOICE {
        uuid id PK
        uuid project_id FK 
        uuid customer_id FK
        varchar invoice_number
        varchar status "ENUM: 'draft', 'sent', 'paid', 'void'"
        timestamptz issued_at
        date due_date "payment due date"
        timestamptz paid_at
    }
```

## Data Dictionay & Schema Specifications

### 1. `organizations`
Root tenant entity defining isolation boundaries.

| Column | PostgreSQL Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Unique tenant identifier. |
| `slug` | `VARCHAR(50)` | `NOT NULL`, `UNIQUE`, `CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')` | URL-friendly tenant key for `X-Tenant-Slug` Header. Enforces lowercase, numbers, and single-hyphen separators. |
| `name` | `VARCHAR(100)` | `NOT NULL`, `CHECK(LENGTH(TRIM(name)) >= 2)` | Legal or display name of the business. Enforces a minimum length of 2 printable characters. |
| `description` | `TEXT` | `NULLABLE` | Optional summary or overview of the organization. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

### 2. `users`
Tenant-scoped user profiles.

| Column | PostgreSQL Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Unique user identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCES organizations(id) ON DELETE RESTRICT` | Tenant FK boundary indentifier. |
| `name` | `VARCHAR(150)` | `NOT NULL`, `CHECK(LENGTH(TRIM(name)) >= 2)` | Full display name. Prevents empty or whitespace-only names. |
| `email` | `VARCHAR(254)` | `NOT NULL`, `CHECK (email ~* '^[a-z0-9._%+-]+@[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$')` | Login email identifier. Validates basic email formatting via case-insensitive regex. |
| `role` | `VARCHAR(20)` | `NOT NULL`, `CHECK (role IN ('owner', 'employee'))` | Authorization role. |
| `password_hash` | `TEXT` | `NOT NULL` | Hashed credential. |
| `is_active`| `BOOLEAN` | `NOT NULL`, `DEFAULT TRUE` | Soft-deletion flag. |
| `notes` | `TEXT` | `NULLABLE` | Internal administrative notes regarding the user profile. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

> **Composite Constraint:** `UNIQUE (organization_id, email)` enforces email uniqueness per tenant, allowing identical email addresses across separate organizations.

### 3. `customers`
External client profiles managed by the organization.

| Column | PostgreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Unique customer identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCES organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `name` | `VARCHAR(150)` | `NOT NULL`, `CHECK(LENGTH(TRIM(name)) >= 2)` | Display or legal name of the client company. Prevents empty or whitespace-only names. |
| `phone_number` | `VARCHAR(30)` | `NOT NULL`, `CHECK (phone_number ~ '^\+?[0-9\s\-()]+$')` | Primary contact number. Must include a '+' followed by the country code and digits only. |
| `notes` | `TEXT` | `NULLABLE` | Internal CRM notes. |
| `is_active`| `BOOLEAN` | `NOT NULL`, `DEFAULT TRUE` | Soft-deletion flag. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

> **Composite Constraint:** `UNIQUE (`organization_id`, `name`)` prevents duplicated customer profiles from being created within the same business environment.

### 4. `projects`
Primary operation container for tasks, costs, and invoicing.

| Column | PostgreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Unique project identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCES organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `customer_id` | `UUID` | `NOT NULL`, `REFERENCES customers(id) ON DELETE RESTRICT` | External client sponsoring the project. |
| `manager_id` | `UUID` | `NOT NULL`, `REFERENCES users(id) ON DELETE RESTRICT` | Designated internal manager (Owner or Employee). |
| `name` | `VARCHAR(150)` | `NOT NULL`, `CHECK(LENGTH(TRIM(name)) >= 2)` | Project title. Ensures descriptive names. |
| `description` | `TEXT` | `NULLABLE` | Additional information on project scope, objectives and workflow. |
| `priority` | `VARCHAR(10)` | `NOT NULL`, `CHECK (priority IN ('low', 'medium', 'high'))` | Business urgency level in completing the project. |
| `status` | `VARCHAR(15)` | `NOT NULL`, `CHECK (status IN ('active', 'completed', 'on_hold', 'cancelled'))` | Lifecycle state. |
| `start_date` | `DATE` | `NULLABLE` | Planned start. |
| `end_date` | `DATE` | `NULLABLE` | Planned end. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

### 5. `tasks`
Work unit, may convert to billable items.

| Column | PostgreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Unique task identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCES organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `project_id` | `UUID` | `NOT NULL`, `REFERENCES projects(id) ON DELETE CASCADE ` | Parent project container. |
| `title` | `VARCHAR(300)` | `NOT NULL`, `CHECK(LENGTH(TRIM(title)) >= 2)` | Short summary of the work unit. |
| `description` | `TEXT` | `NULLABLE` | Task execution details. |
| `status` | `VARCHAR(15)` | `NOT NULL`, `CHECK (status IN ('todo', 'in_progress', 'cancelled', 'done'))` | Task execution state. |
| `priority` | `VARCHAR(10)` | `NOT NULL`, `CHECK (priority IN ('low', 'medium', 'high'))` | Task urgency classification. |
| `labor_cost` |`BIGINT` | `NULLABLE`, `CHECK(labor_cost >= 0)` | Internal human resource cost. |
| `due_date` | `DATE` | `NULLABLE` | Target completion date. |
| `completed_at` | `TIMESTAMPZ` | `NULLABLE` | Timestamp when task reach `done` state. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

### 6. `task_assignment`
Mapping junction table linking users to tasks.

| Column | PostgreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT gen_random_uuid()` | Unique assignment identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCES organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `task_id` | `UUID` | `NOT NULL`, `REFERENCES tasks(id) ON DELETE CASCADE` | Assigned task. Deleting a task purges its assignments. |
| `user_id` | `UUID` | `NOT NULL`, `REFERENCES users(id) ON DELETE CASCADE` | Assigned user. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

### 7. `expenses`
Direct project-level cost incurred during operation.

| Column | PostgreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT get_random_uuid()` | Unique expense identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCE organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `project_id` | `UUID` | `NOT NULL`, `REFERENCE projects(id) ON DELETE RESTRICT` | Parent project container. |
| `material_cost_in_cents` | `BIGINT` | `NOT NULL`, `CHECK (material_cost_in_cents >= 0)` | Cost of physical items or third-party tools. |
| `incurred_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Timestamp when the expense ocurred. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

### 8. `billable_items`
Financial charge generated for client billing. Can be split across multiple invoicing.

| Column | PostgreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT get_random_uuid()` | Unique billable item identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCE organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `project_id` | `UUID` | `NOT NULL`, `REFERENCE projects(id) ON DELETE RESTRICT` | Parent project container. |
| `task_id` | `NULLABLE`, `REFERENCE tasks(id) ON DELETE RESTRICT` | Source task reference. |
| `expense_id` | `NULLABLE`, `REFERENCE expense(id) ON DELETE RESTRICT` | Source expense reference. |
| `total_value_in_cents` | `BIGINT` | `NOT NULL`, `CHECK(total_value_in_cents >= 0)` | Amount to be charged to the client. |
| `is_written_off` | `BOOLEAN` | `NOT NULL`, `DEFAULT FALSE` | Status flag marking a billing attempt as cancelled or written off, allowing a new billable item to be generated for the source. | 
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

> **Check Constraint:** `CHECK (task_id IS NULL OR expense_id IS NULL)` enforces that a billable item originates from only one source type (task, expense or direct charge).
> **Partial Unique Index:** `CREATE UNIQUE INDEX indx_billable_items_unique_active_task ON billable_items (task_id) WHERE is_written_off = FALSE AND task_id IS NOT NULL`  ensures a task can only have one active non-written-off billable item at a time.
> **Partial Unique Index:** `CREATE UNIQUE INDEX indx_billable_items_unique_active_expense ON billable_items (expense_id) WHERE is_written_off = FALSE AND expense_id IS NOT NULL`  ensures a expense can only have one active non-written-off billable item at a time.

### 9. `billable_item_portions`
Line-item splits for billing. Links a specific dollar amount of a billable item to a specific invoice.

| Column | PostgreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT get_random_uuid()` | Unique portion identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCE organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `billable_item_id` | `UUID` | `NOT NULL`, `REFERENCE billable_items(id) ON DELETE RESTRICT` | Parent billable item. |
| `invoice_id` | `UUID` | `NOT NULL`, `REFERENCE invoices(id) ON DELETE RESTRICT` | Target invoice record. |
| `amount_allocated_in_cents` | `BIGINT` | `NOT NULL`, `CHECK(amount_allocated_in_cents > 0)` | Exact amount allocated to the target invoice. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

> **Business Invariant (Use Case Layer/Trigger):** `SUM(amount_allocated_in_cents)` across all active (non-void invoice) portions belonging to a single `billable_item_id` must not exceed `billable_items.total_value_in_cents`.
> **Lifecycle & Immutability Invariant:** Rows may only be inserted or deleted while the target `invoice_id.status` is `draft`. Once created portions are completely immutable. Corrections must be performed by deleting the row on a `draft` invoice and re-allocating.

### 10. `invoices`
Formal billing document issued to customers.

| Column | PostreSQL Type | Constraints | Description |
| : --- | : --- | : --- | : --- |
| `id` | `UUID` | `PRIMARY KEY`, `DEFAULT get_random_uuid()` | Unique invoice identifier. |
| `organization_id` | `UUID` | `NOT NULL`, `REFERENCE organizations(id) ON DELETE RESTRICT` | Tenant ownership key. |
| `customer_id` | `UUID` | `NOT NULL`, `REFERENCES customers(id) ON DELETE RESTRICT` | Target client billed. |
| `project_id` | `UUID` | `NOT NULL`, `REFERENCES projects(id) ON DELETE RESTRICT` | Parent associated project. |
| `invoice_number` | `VARCHAR(50)` | `NOT NULL` | Unique invoice code per tenant. |
| `status` | `VARCHAR(15)` | `NOT NULL`, `CHECK (status IN ('draft', 'sent', 'paid', 'void'))` | Lifecycle state. |
| `issued_at` | `TIMESTAMPTZ` | `NULLABLE` | Timestamp when the invoice transitioned to 'sent'. |
| `due_date` | `DATE` | `NULLABLE` | Payment due date. |
| `issued_at` | `TIMESTAMPTZ` | `NULLABLE` | Timestamp when payment was confirmed. |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Creation audit timestamp. |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL`, `DEFAULT NOW()` | Modification audit timestamp. |

> **Composite Constraint:** `UNIQUE (organization_id, invoice_number)` guarantees unique invoice numbers per tenant organization.
> **State Consistencia Check:** `Enforces valid timestamp combinations accross the invoice lifecycle:
* `status = 'draft'` &rarr; `issued_at IS NULL AND paid_at IS NULL`
* `status = 'sent'` &rarr; `issued_at IS NOT NULL AND paid_at IS NULL`
* `status = 'paid'` &rarr; `issued_at IS NOT NULL AND paid_at IS NOT NULL`