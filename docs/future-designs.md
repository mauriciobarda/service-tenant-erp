# Future Features and Design Considerations

This document records proposed features and implementation ideas that are not part of the current version of the App. These notes are exploratory and do not describe existing system behavior.

## Global User Deactivation Workflows

Add a `user.is_active` field and implement a propagation workflow throughout tenants.

### Goals

- **Administrative Control:** Allow system administrators to deactivate users, revoking access across the system.
- **Tenant Continuity:** Enable tenant owners and managers to identify deactivated employees and reassign pending work.
- **Prevent Misassignments:** Ensure that deactivated users cannot be assigned new tasks or responsibilities.

### Out of Scope for This Feature

- **User Self-Deletion:** End-user account closure, data deletion requests, or GDPR compliance flows will not be handled by this feature.

### Proposed Approach

- Implement an asynchronous event hook that fires whenever `user.is_active` transitions to `false`.
- Propagate this status change down to the tenant level by automatically updating related `organization_membership.is_active` records to `false`.
- Prevent users with `is_active = false` from being added to new organization memberships or having all their `is_active = false` memberships flipped back to `true`.
- Design and implement a reassignment system for active tasks (`todo` or `in_progress`) assigned to the deactivated global User.

## Operational Status Active Flag for Organizations

### Goal

Allow platform administrators or automated billing systems to temporaly suspend tenant workspace access without destroying underlying data.

### Proposed Approach

- Add a boolean `is_active` field to the `organizations` records.
- Integrate an operational check into the Express tenant resolution middleware to block requests from suspended organizations.
- Keep data fully intact to allow easy activation.

### Revisit When

Integrating payment gateways or implementing multi-tenant administrative controls.

## Soft Deletion and Recycle Bin

### Goal

Allow users to recover records they delete.

### Proposed Approach

- Add a nullable `deleted_at` timestamp to selected models.
- Treat records with `deleted_at = NULL` as live.
- Use a Prisma Client wrapper or extension to filter soft-deleted records from existing queries.
- Add dedicated queries for listing, restoring, and permanently deleting records in the recycle bin.
