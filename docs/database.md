# Database Architecture

This document specifies the physical data relationships and core implementation decisions designed to support the Service Tenant ERP.

## Core Design Decisions

* **Strict Multi-Tenancy Isolation:** To guarantee data privacy, every operational record is tied to a single root `Organization`. Tenants can never access or view data belonging to another organization.
* **Single-Tenant User Profile:** For the initial version of this system, a `User` record is strictly linked to exactly one `Organization` and is assigned a single unique `role`. Supporting a single user profile that can connect to multiple independent organizations is a feature left for future development.
* **Target Database Engine:** The physical schema is designed specifically for **PostgreSQL**. The implementation leverages Postgre-native capabilities such as explicit Foreign keys.
* **Pragmatic Denormalization:** The physical schema intentionally violates the **Third Normal Form (3NF)** of normalization by cascading the `organization_id` down to every single table, to prevent deep, expensive relational joins and safely filter all tenant data in a single, fast operation.
* **Global Metadata Omission:** For clarity, `created_at`, `updated_at`, `organization_id`, `notes`, and `description` columns are omitted from visual ERD diagrams to keep the focus on core business data and relationships.
* **Unified Role-Based Authorization:** The `User` entity serves as a single unified table representing all internal actors, including both `Owner` and `Employee`. Functional permissions and access controls are dynamically determined at runtime by evaluating the user's assigned role.
* **Financial Audit Preservation:** In accordance with standard accounting principles, `Invoice` records are never physically deleted from the system. If an invoice is cancelled, its status column is mutated to `void`.
* **Tenant-scoped Authentication Credentials:** To support identical usernames or duplicate emails accros diferent tenants, the authentication system requires a unique organization `slug` alongside individual credentials at login. The application resolves the tenant by this slug first, ensuring usernames only need to be unique within their respective organization boundaries.
* **Decoupled Financial Valuation:** To protect financial integrity, a `BillableItem` generated from an `Expense` or `Task` stores and independent mutable pricing value. If the cost attributes of the task of expense changes, the contracted value remains securely unaffected.
* **Inmutable Invoicing Portions:** Once a `BillableItemPortion` is allocated to an `Invoice`, its `amount_allocated` is completely immutable. This acts as a permanent historical audit trail, allowing the system to safely recalculate remaining unbilled item balances dynamically without risking cross-document mutation.

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

    TASK |o--o| BILLABLE_ITEM : converts_to
    EXPENSE |o--o| BILLABLE_ITEM : converts_to

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
        numeric labor_cost "Nullable: Internal human resource cost"
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
        numeric internal_cost
    }

    BILLABLE_ITEM {
        uuid id PK
        uuid project_id FK
        uuid task_id FK "Nullable, Unique"
        uuid expense_id FK "Nullable, Unique"
        numeric total_value
        boolean is_written_off "Default: false"
    }

    BILLABLE_ITEM_PORTION {
        uuid id PK
        uuid billable_item_id FK
        uuid invoice_id FK
        numeric amount_allocated
    }

    INVOICE {
        uuid id PK
        uuid project_id FK 
        uuid customer_id FK
        varchar invoice_number
        varchar status "ENUM: 'draft', 'sent', 'paid', 'void'"
    }
```