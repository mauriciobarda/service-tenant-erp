# Database Architecture

This document specifies the physical data relationships, implementation decisions and storage constraints designed to support the Service Tenant ERP.

## Core Design Decisions

* **Strict Multi-Tenancy Isolation:** To guarantee data privacy, every operational record is tied to a single root `Organization`. Tenants can never access or view data belonging to another organization.
* **Target Database Engine:** The physical schema is designed specifically for **PostgreSQL**. The implementation leverages Postgre-native capabilities such as explicit Foreign keys and `jsonb` data type for historical snapshots.
* **Pragmatic Denormalization:** The physical schema intentionally violates the **Third Normal Form (3NF)** of normalization by cascading the `organization_id` down to every single table, to prevent deep, expensive relational joins and safely filter all tenant data in a single, fast operation.
* **Global Metadata Omission:** For clarity, `created_at`, `updated_at`, and `organization_id` columns are omitted from visual ERD diagrams to keep the focus on core business data and relationships.
* **Single-Tenant User Profile:** For the initial version of this system, a `User` record is strictly linked to exactly one `Organization` and is assigned a single unique `role`. Supporting a single user profile that can connect to multiple independent organizations is a feature left for future development.
* **Unified Role-Based Authorization:** The `User` entity serves as a single unified table representing all internal actors, including both `Owner` and `Employee`. Functional permissions and access controls are dynamically determined at runtime by evaluating the user's assigned role.
* **Financial Audit Preservation:** In accordance with standard accounting principles, `Invoice` records are never physically deleted from the system. If an invoice is cancelled, its status column is mutated to `void`.
* **Tenant-scoped Authentication Credentials:** To support identical usernames or duplicate emails accros diferent tenants, the authentication system requires a unique organization `slug` alongside individual credentials at login. The application resolves the tenant by this slug first, ensuring usernames only need to be unique within their respective organization boundaries.
