# Project Development Roadmap

This document outlines the planned execution phases, technical milestones, and completion status for the Service Tenant ERP.

The project follows a **Domain-first** implementation strategy: establishing relational data integrity, core business processes, and contract specification before writing application code.

---

## Phase 0: System Architecture & Specifications
*Goal: Establish technical specifications, data contracts, and project scope prior to implementation.*

- [x] Define core project vision and high-level goals (`README.md`)
- [x] Document core business processes and domain nouns (`docs/business-process.md`)
- [x] Select the technical stack and document it (`README.md`)
- [x] Establish data architectural decisions and draw high-level ERD (`docs/database.md`)
- [] Define global software layers, directory tree, and data flow (`docs/architecture.md`)
- [] Document low-level table schemas, data types, and structural field rules (`docs/database.md`)
- [] Outline initial REST API endpoints for seeding and core loop validation (`docs/api.md`)

## Phase 1: Environment Setup & Database Foundations
*Goal: Create a runnable local environment with isolated database containers and migration management.*

- [] Set up global and container-level configurations for Prettier, ESLint and Typescript
- [] Write `compose.yaml` for local PostgreSQL containerization
- [] Initialize Prisma ORM, map out ERD constraints, and execute the initial migration
- [] Build automated database seed scripts using Prisma Client to hydrate mock tenant data