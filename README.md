# Service Tenant ERP

A multi-tenant Enterprise Resource Planning (ERP) platform designed for service-oriented business. It enables organizations to manage client workflows, assign employees to project tasks, and monitor financial perfomance through integrated invoice and expense tracking.

## Core Modules & Features

- **Organization & Access Control:** Multi-tenant architecture isolating data by organization, supporting user authentication and role-based permission.
- **Client and Project Management:** Customer directory, project lifecycles & status pipelines.
- **Task and Resource Allocation:** Task breakdown within projects, priority levels, and employee assignment workflows.
- **Finantial Operations:** Invoice generation, expense logging, and real-time project profitability (`Invoices-Expenses`).
- **Reporting and Analytics:** Ovierview dashboard displaying active project health, overdue task alerts, and financial summaries.

## Tech Stack

- **Front-End:** React, TypeScript, Material UI, React Query, React Router
- **Back-End:** Node.js, Express, TypeScript
- **Database** PostgreSQL (Chosen for ACID compliance, strict foreign keys constraints, and relational aggregations)
- **Testing:** Vitest, React Testing Library, Supertest, Playwright
- **DevOps and tooling:** Docker Compose, GitHub Actions, ESLint, Prettier

## System Architecture and Documentation

Detailed technical specifications are maintained in the `/docs` directory:


- [Business Process and Workflows](docs/business-process.md)
- [System Architecture](docs/architecture.md)
- [Database Schema & ERD](docs/database.md)
- [API Specifications](docs/api.md)
- [Development Roadmap](docs/roadmap.md)