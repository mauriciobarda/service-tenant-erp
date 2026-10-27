## Business Processes & Workflows

This document outlines the core business capabilities and user journeys supported by the current Service Tenant ERP.

These workflows shape the architectural boundaries, database relationships, and API contracts, reflecting the real-world operations carried out by future users.

## 1. Core Value Loop: Project Delivery to Billing

The foundational lifecycle of a business engagement, mapping how client demands are structured into trackable tasks, assigned to employees, monitored for expenses, and ultimately invoiced.

- **Primary Actor:** Organization Owner, Project Manager (PM) and Assigned Employees.
- **Pre-Conditions:** A `Customer` profile exists in the system directory.
- **Success State:** The project is completed, an invoice is generated, and the financial dashboard is updated.

### Core Lifecycle and Dynamic Operations

**Note on Operation State:** While the list below represents the foundational setup lifecycle of a project, as long as the project remains within an **Active State** (`planning`, `scheduled`, or `in_progress`) its data, parameters, and structural components can be updated independently at any time.

1. **Project Initiation & Configuration (Owner):** The Owner creates a new `Project` record in the `planning` state, linking it to a `Customer` profile and setting its `priority` level (`Low`, `Medium`, `High`).
2. **Manager Designation (Owner):** The Owner designates a manager from among themselves and their employees.
3. **Setting Planned Dates (Manager):** The designated Project Manager sets a planned start date making the project transition into an `scheduled` status. A planned end date can also be set.
4. **Work Breakdown Structure (Manager):** The Manager outlines the project scope by creating distinct `Tasks`.
5. **Task Priority Setting (Manager):** The Manager assigns a `priority` level (`Low`, `Medium`, `High`) to each task. New tasks default to `Medium`.
6. **Employee Assignment (Manager):** The Manager links one or more `Employee` records to each task, automatically populating the respective employees' work queues with the assigned tasks.
7. **Project Execution Kick-off (Manager)**: When operational work begins, the status transitions to `in_progress`. The system automatically stamps the `actual_start_date` with the current timestamp to track operational baseline deviations.
8. **Expense Tracking (Manager):** The Manager logs optional labor costs to `Task` records and creates operational or material `Expense` records against the `Project` to track internal costs.
9. **Creation of Billable Items (Manager):** The Manager can generate `Billable Item` from tasks, expenses or as an independent flat-fee structure with no source. A `Billable Item` can be split and distributed across one or multiple `Invoice` records via `Billable Item Portion`.
10. **Independent Invoicing (Owner):** The Owner generates an `Invoice` at any point composed of one or more `Billable Item Portion`. The billing recipient could be the linked `Customer` or any other billing entity defined at that time.
11. **Payment Processing (Owner):** Upon receiving client payment, the Owner updates the invoice status to `Paid`, which automatically refreshes the organization's revenue metrics.
12. **Lifecycle State Transitions (Owner):** At any point, the Owner can update the `Project` status to `on_hold`, `cancelled`, or `completed`. The system dynamically filters those tasks from the assigned employees' work queues without altering individual task histories. The Owner can also reactivate the project if not `completed`.

### Core Lifecycle Diagram

```mermaid
flowchart TD
    classDef stateMachine stroke-width:2px;

    %% Phase 1: Initialization
    S0[1. Project Initiation] -->|Enters Active State in `planning` status | Active_Project_State

    %% Active Lifecycle Pool (Everything can happen concurrently)
    subgraph Active_Project_State [Active Project Execution Pool]
        S1("1. Project Configuration:\nSet Customer / priority")
        S2("2. Manager Designation:\nAssign / Reassign PM")
        S3("3. Setting Planned Dates\nTransition status to `scheduled`")
        S4("4. Work Breakdown Structure:\nTask Creation")
        S5("5. Task Priority Setting")
        S6("6. Employee Assignment")
        S7("7. Project Execution Kick-off\nTransition status to `in_progress`")
        S8("8. Expense Tracking")
        S9("9. Creation of Billable Items")
        S10("10. Independent Invoicing")
        S11("11. Payment Processing")
    end

    %% Global Interrupt pulling OUT of the active state
    Active_Project_State -.->|"Changing status to\non_hold / cancelled / completed"| S12{{"Non-Active States:\nFilters tasks out of active queues"}}

    %% Return path to Active State
    S12 ==>|"Reactivating state\n from on_hold / cancelled \n back to Active state"| Active_Project_State

    class S10 stateMachine;
```

### Billing Diagram Flow

```mermaid
flowchart LR
    Task[1. Task] -->|1:1 Link| BI1[3. Billable Item 1]
    Expense[2. Expense] -->|1:1 Link| BI2[4. Billable Item 2]

    subgraph Billing_Bridge [The Billing Bridge]
        BI1
        BI2
        BI3[5. Billable Item 3]
    end

    BI1 -->|Splits into 1:N| Inv1[Invoice A]
    BI1 -->|Splits into 1:N| Inv2[Invoice B]

    BI2 -->|Splits into 1:N| Inv1[Invoice A]
    BI2 -->|Splits into 1:N| Inv2[Invoice B]

    BI3 -->|Splits into 1:N| Inv1[Invoice A]
    BI3 -->|Splits into 1:N| Inv2[Invoice B]
```

### Core Domain Nouns & Actions

- **`Project`**: Serves as the primary operational container. Tracks mutable global properties (`customer`, `manager`, and `priority`) and transitions through states (`planning`, `scheduled`, `in_progress`, `on_hold`, `completed`, `cancelled`).
- **`Owner`**: A User with admin permissions over the Organization. Creates new projects, sets global properties, designates Managers, and generates or updates Invoices. Can invite other Users as employees and create Customers.
- **`Organization`**: Centralizes and contains all projects, history, employee staff, and customer list.
- **`Manager`**: A User linked to an Organization with a Manager role over a specific Project. Can create tasks, assign employees to them, and log expenses.
- **`Task`**: The minimal unit of work to be done. Generated continuously during project execution, each task has a `priority` level and an optional `labor_cost`, and transitions through states (`todo`, `in_progress`, `cancelled`, `done`).
- **`Expense`**: An operational or material cost record. Any number of expenses can be logged into a Project.
- **`Billable Item`**: A financial representation of an expense, task, or arbitrary concept generated to be charged to a client. It acts as a value container that can be divided into distinct portions and distributed across one or multiple invoices.
- **`Invoice`**: An on-demand billing record composed of Billable Items. Any number of invoices can be generated and linked to a Project, remaining completely independent of expenses. Transitions through states (`draft`, `sent`, `paid`, `void`, where `void` represents an issued invoice that was subsequently cancelled).
- **`Employee`**: A User linked to an Organization who was invited by the Owner. Maintains a personal queue of tasks to be done and can be set as the Manager of any number of projects.
- **`Customer`**: An external client profile sponsoring the business engagement. Serves as the default relationship linked to the Project and can be set as the billing recipient.
