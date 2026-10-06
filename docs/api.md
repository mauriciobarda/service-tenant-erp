# REST API Specifications

This document defines the REST API contract for the platform, detailing endpoint paths, required request bodies, query parameters and JSON response structures.

## Conventions & Global Constraints

* **Base URL:** `api/v1`
* **Content-Type:** `application/json`
* **Monetary Values:** Represented as *integer cents* (e.g., `12500` = `$125.00`).
* **Pagination:** List endpoints accept `limit` and `cursor` query parameters and return a wrapped `{ data: [...], next_cursor }` structure.
* **Error Format:** Standardized error responses follow this structure:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Detailed description of this failure.",
    "details": [
      {
        "field": "string (the path to the invalid field)",
        "issue": "string (machine-readable issue key)",
        "message": "string (human-readable field error message)"
      }
    ]
  }
}
```

## 1. Public & Global Endpoints (No Tenant Required)

These routes handle global user identity creation and session management.

| Method | Path | Purpose | Auth Requirement |
| :--- | :--- | :--- | :--- |
| **POST** | `/auth/register` | Creates a global user credential profile. | Public |
| **POST** | `/auth/login` | Authenticates user globally and issues session cookie. | Public |
| **POST** | `/auth/logout` | Destroys current session cookie. | Authenticated Session |
| **GET** | `/auth/me` | Returns the currently authenticated global user profile. | Authenticated Session |

#### POST `/auth/login`

**Request Body:**
```json
{
  "email": "jane@example.com",
  "password": "SecurePassword123"
}
```

**Success Response (200 OK):** *(Sets HTTP-Only Cookie)*
```json
{
  "user": {
    "id": "4f8b2a1c-9e3d-4b7a-8f5c-6d2e1a3b4f5e",
    "name": "Jane Doe",
    "email": "jane@example.com"
  }
}
```
---

## 2. User-Scoped Workspace Routing

These routes operate on the authenticated user's global session to manage workspace membership and organization creation before a specific tenant context is locked in.

| Method | Path | Purpose | Auth Requirement |
| :--- | :--- | :--- | :--- |
| **GET** | `/organizations` | Lists all organizations the user has active memberships (with roles). | Authenticated Session |
| **POST** | `/organizations` | Creates a new organization and assigns the user as owner. | Authenticated Session |
| **PATCH** | `/organizations/:id` | Updates organization details (Name, settings, etc.). | Authenticated Session (Owner Role) |
| **DELETE** | `/organizations/:id` | Deletes an organization workspace (fails if dependent records exist). | Authenticated Session (Owner Role) |



---

## 3. Tenant-Scoped Operational Endpoints

All routes in this section require both an authenticated session cookie **AND** the active workspace identifier passed via the `X-Organization-Id` header.

### Organization Membership Module

| Method | Path | Purpose |
| :--- | :--- | :--- |
| **GET**	| `/members` | Lists all active members and their roles in the current tenant workspace. |
| **POST**	| `/members` | Invites or add an existing global user account to the current tenant workspace. |
| **PATCH**	| `/members/:id` | Updates a member's role, name, notes or status. |
| **DELETE**	| `/members/:id` | Revokes a user's membership access from the workspace. |

### Customers Module

| Method | Path | Purpose |
| :--- | :--- | :--- | :--- |
| **GET** | `/customers` | Lists or filters organization clients (supports pagination). |
| **POST** | `/customers` | Creates a new client profile. |
| **GET** | `/customers/:id` | Gets detailed client profile by ID. |
| **PATCH** | `/customers/:id` | Updates client details or active status. |
| **DELETE** | `/customers/:id` | Deletes a client (restricted if referenced by projects or invoices). |

#### POST `customers`

**Request Body:**
```json
{
  "name": "Acme Industrial Corp",
  "phone_number": "+1 (555) 234-5678",
  "notes": "preferred client"
}
```

**Success Response (201 Created):**
```json
{
  "id": "f8c3bbd0-9a3c-4a37-889d-721245fa8b32",
  "organization_id": "org_uuid_here",
  "name": "Acme Industrial Corp",
  "phone_number": "+15552345678",
  "notes": "Preferred client",
  "is_active": true,
  "created_at": "2026-10-01T12:00:00Z",
  "updated_at": "2026-10-01T12:00:00Z"
}
```
#### Permissive Field Validation
**customers.phone_number:** Validated via `^\+?[0-9\s\-()]+$`. Permissive of spaces, dashes, and parenthesis to optimize user experience. The API sanitizes this input to strict E.164 format.

### Projects Module

| Method | Path | Purpose |
| :--- | :--- | :--- | :--- |
| **GET** | `/projects` | Lists projects for the active tenant. |
| **POST** | `/projects` | Creates a new project container. |
| **GET** | `/projects/:id` | Get project details. |
| **PATCH** | `/projects/:id` | Updates project information. |
| **DELETE** | `/projects/:id` | Deletes a project container (restricted if referenced by financial records). |

### Tasks & Task Assignments Module

| Method | Path | Purpose |
| :--- | :--- | :--- | :--- |
| **GET** | `/projects/:id/tasks` | Lists tasks under a specific project. |
| **POST** | `/projects/:id/tasks` | Creates a new task unit. |
| **PATCH** | `/tasks/:id` | Updates task details. |
| **DELETE** |  `/tasks/:id` | Deletes a task unit (restrict if referenced by a billable item). |
| **POST** | `/tasks/:id/assignments` | Assigns a workspace user to a task. |
| **DELETE** | `/assignments/:assignmentId` | Removes a task assignment to an user. |

### Expenses Module

| Method | Path | Purpose |
| :--- | :--- | :--- | :--- |
| **GET** | `/projects/:id/expenses` | Lists operational and material costs incurred on a project. |
| **POST** | `/projects/:id/expenses` | Logs a direct project expense. |
| **DELETE** | `/expenses/:id` | Removes an incorrectly logged expense (restrict if referenced by a billable item). |

### Billable Items Module

| Method | Path | Purpose |
| :--- | :--- | :--- | :--- |
| **GET** | `/projects/:id/billable-items` | Lists billable items linked to a project. |
| **POST** | `/projects/:id/billable-items` | Generates a manual or source-linked billable charge. |
| **POST** | `/billable-items/:id/write-off` | Marks a billable item as written off. |

### Invoices Modules

| Method | Path | Purpose |
| :--- | :--- | :--- | :--- |
| **GET** | `/invoices` | Lists invoices issued to customers. |
| **POST** | `/invoices` | Creates a new `draft` invoice shell (customer, project, due date). |
| **GET** | `/invoices/:id` | Shows invoice details, line items (portions) and current lifecycle state. |
| **PATCH** | `/invoices/:id` | Updates invoice metadata (due_date, invoice_number, billing customer) while in `draft`. |
| **DELETE** | `/invoices/:id` | Deletes a `draft` invoice. |
| **POST** | `/invoices/:id/portions` | Adds a billable item portion to a `draft` invoice. |
| **DELETE** | `/billable-item-portions/:id` | Removes a portion to a `draft` invoice (restores unbilled balance). |
| **POST** | `/invoices/:id/send` |	Transitions invoice state from `draft` to `sent` (`issued_at` populated). |
| **POST** | `/invoices/:id/pay` |	Transitions invoice state from `sent` to `paid` (`paid_at` populated). |
| **POST** | `/invoices/:id/void` |	Cancels (void) an invoice for financial audit preservation. |