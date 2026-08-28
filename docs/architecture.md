# System Architecture Specifications

This document defines the **technical architecture**, **operational layers**, **execution flow**, **directory organization**, and **data isolation mechanisms** for the Service Tenant ERP platform. It acts as the definitive engineering blueprint for building the platform's core engine.


## HTTP Requests Lifecycle & Backend Layer Architecture

The backend engine processes incoming requests thought a sequence of **decoupled layers**. Each layer has a singular responsibility and can only communicate with the layer beneath it.

The application adopts a **Clean Request Pipeline**, consisting of a **Infrastructural Middleware Chain** feeding into a **Pragmatic 2-Layer Model** (Controller &rarr; Use Case). This design decouples HTTP transport mechanics and multi-tenant routing from domain business while keeping data access straightforward via Prisma ORM.

### Request Lifecycle Diagram

```mermaid
flowchart TD
    classDef layerStyle fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef boundaryStyle stroke-dasharray: 5 5, fill:#ffffff, stroke:#666;

    Client[React Client / Frontend] -->|1. HTTP Request + Auth Cookie| Middleware

    subgraph Express_Backend [Express Backend App Boundary]
        Middleware["Express Middleware Chain
        - Verifies Cookie Session
        - Enforces req.tenantId Scope
        - Global Error Catching"]

        Middleware -->|2. Secure Context & Raw Payload| Controller["Controller Layer
        - Executes Zod Input Validation
        - Maps incoming parameters
        - Formats HTTP JSON Responses"]

        %% The Unified Layer combining logic and data access via Prisma
        subgraph UseCase_Layer [Pragmatic Use Case Layer]
            DirectionalBusiness["Core Domain Logic
            - State Machine Changes
            - Workflow Rules
            - Data Mutations"]
            
            PrismaEngine["Prisma Client Engine
            - Native SQL Generation
            - Isolated Transactions
            - Type-Safe Relational Data Mapping"]
            
            DirectionalBusiness <==> PrismaEngine
        end

        Controller -->|3. Triggers Execution DTO| DirectionalBusiness
    end

    PrismaEngine <-->|4. Direct Database Connection| DB[(PostgreSQL Database)]
    Controller -->|5. HTTP JSON Response| Client
```

### Layer Responsabilities

* **Express Middleware Chain:** Handles session extraction, tenant verification (binding `req.tenantId`), and global exception catching. 
* **Controller Layer:** Executes structural validation via *Zod*, transforms raw parameters into type-safe DTOs, and sets HTTP status responses.
* **Pragmatic Use Case Layer:** Executes core domain logic and runs direct *Prisma Client* queries.

