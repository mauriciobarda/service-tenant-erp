-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "citext";

-- CreateEnum
CREATE TYPE "membership_role" AS ENUM ('owner', 'employee');

-- CreateEnum
CREATE TYPE "project_priority" AS ENUM ('low', 'medium', 'high');

-- CreateEnum
CREATE TYPE "project_status" AS ENUM ('planning', 'scheduled', 'in_progress', 'on_hold', 'cancelled', 'completed');

-- CreateEnum
CREATE TYPE "task_status" AS ENUM ('todo', 'in_progress', 'cancelled', 'done');

-- CreateEnum
CREATE TYPE "task_priority" AS ENUM ('low', 'medium', 'high');

-- CreateEnum
CREATE TYPE "billable_item_type" AS ENUM ('task', 'expense', 'direct');

-- CreateEnum
CREATE TYPE "invoice_status" AS ENUM ('draft', 'sent', 'paid', 'void');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(150) NOT NULL,
    "email" CITEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "organizations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" VARCHAR(100) NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "organizations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "organization_memberships" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "role" "membership_role" NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "notes" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "organization_memberships_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "phone_number" VARCHAR(30) NOT NULL,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "projects" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "manager_membership_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" TEXT,
    "priority" "project_priority" NOT NULL,
    "status" "project_status" NOT NULL,
    "planned_start_date" TIMESTAMPTZ(0),
    "planned_end_date" TIMESTAMPTZ(0),
    "actual_start_date" TIMESTAMPTZ(0),
    "actual_end_date" TIMESTAMPTZ(0),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "projects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tasks" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "project_id" UUID NOT NULL,
    "title" VARCHAR(300) NOT NULL,
    "description" TEXT,
    "status" "task_status" NOT NULL,
    "priority" "task_priority" NOT NULL,
    "labor_cost_in_cents" BIGINT,
    "due_date" TIMESTAMPTZ(0),
    "completed_at" TIMESTAMPTZ(0),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "tasks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "task_assignments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "project_id" UUID NOT NULL,
    "task_id" UUID NOT NULL,
    "membership_id" UUID NOT NULL,
    "assigned_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "unassigned_at" TIMESTAMPTZ(6),

    CONSTRAINT "task_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "expenses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "project_id" UUID NOT NULL,
    "material_cost_in_cents" BIGINT NOT NULL,
    "incurred_at" TIMESTAMPTZ(0) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "expenses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "billable_items" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "project_id" UUID NOT NULL,
    "task_id" UUID,
    "expense_id" UUID,
    "type" "billable_item_type" NOT NULL,
    "description" TEXT,
    "total_value_in_cents" BIGINT NOT NULL,
    "is_written_off" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "billable_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "project_id" UUID NOT NULL,
    "invoice_number" VARCHAR(50) NOT NULL,
    "status" "invoice_status" NOT NULL,
    "issued_at" TIMESTAMPTZ(0),
    "due_date" TIMESTAMPTZ(0),
    "paid_at" TIMESTAMPTZ(0),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "billable_item_portions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" UUID NOT NULL,
    "billable_item_id" UUID NOT NULL,
    "invoice_id" UUID NOT NULL,
    "amount_in_cents" BIGINT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "billable_item_portions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "organizations_slug_key" ON "organizations"("slug");

-- CreateIndex
CREATE INDEX "organization_memberships_user_id_is_active_idx" ON "organization_memberships"("user_id", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "organization_memberships_organization_id_user_id_key" ON "organization_memberships"("organization_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "organization_memberships_organization_id_id_key" ON "organization_memberships"("organization_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "customers_organization_id_phone_number_key" ON "customers"("organization_id", "phone_number");

-- CreateIndex
CREATE UNIQUE INDEX "customers_organization_id_id_key" ON "customers"("organization_id", "id");

-- CreateIndex
CREATE INDEX "projects_organization_id_customer_id_idx" ON "projects"("organization_id", "customer_id");

-- CreateIndex
CREATE INDEX "projects_organization_id_manager_membership_id_idx" ON "projects"("organization_id", "manager_membership_id");

-- CreateIndex
CREATE UNIQUE INDEX "projects_organization_id_id_key" ON "projects"("organization_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "tasks_organization_id_project_id_id_key" ON "tasks"("organization_id", "project_id", "id");

-- CreateIndex
CREATE INDEX "task_assignments_organization_id_project_id_task_id_idx" ON "task_assignments"("organization_id", "project_id", "task_id");

-- CreateIndex
CREATE INDEX "task_assignments_organization_id_membership_id_idx" ON "task_assignments"("organization_id", "membership_id");

-- CreateIndex
CREATE UNIQUE INDEX "expenses_organization_id_project_id_id_key" ON "expenses"("organization_id", "project_id", "id");

-- CreateIndex
CREATE INDEX "billable_items_organization_id_project_id_task_id_idx" ON "billable_items"("organization_id", "project_id", "task_id");

-- CreateIndex
CREATE INDEX "billable_items_organization_id_project_id_expense_id_idx" ON "billable_items"("organization_id", "project_id", "expense_id");

-- CreateIndex
CREATE UNIQUE INDEX "billable_items_organization_id_id_key" ON "billable_items"("organization_id", "id");

-- CreateIndex
CREATE INDEX "invoices_organization_id_customer_id_idx" ON "invoices"("organization_id", "customer_id");

-- CreateIndex
CREATE INDEX "invoices_organization_id_project_id_idx" ON "invoices"("organization_id", "project_id");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_organization_id_invoice_number_key" ON "invoices"("organization_id", "invoice_number");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_organization_id_id_key" ON "invoices"("organization_id", "id");

-- CreateIndex
CREATE INDEX "billable_item_portions_organization_id_billable_item_id_idx" ON "billable_item_portions"("organization_id", "billable_item_id");

-- CreateIndex
CREATE INDEX "billable_item_portions_organization_id_invoice_id_idx" ON "billable_item_portions"("organization_id", "invoice_id");

-- AddForeignKey
ALTER TABLE "organization_memberships" ADD CONSTRAINT "organization_memberships_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "organization_memberships" ADD CONSTRAINT "organization_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "customers" ADD CONSTRAINT "customers_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "projects" ADD CONSTRAINT "projects_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "projects" ADD CONSTRAINT "projects_organization_id_customer_id_fkey" FOREIGN KEY ("organization_id", "customer_id") REFERENCES "customers"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "projects" ADD CONSTRAINT "projects_organization_id_manager_membership_id_fkey" FOREIGN KEY ("organization_id", "manager_membership_id") REFERENCES "organization_memberships"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_organization_id_project_id_fkey" FOREIGN KEY ("organization_id", "project_id") REFERENCES "projects"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "task_assignments" ADD CONSTRAINT "task_assignments_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "task_assignments" ADD CONSTRAINT "task_assignments_organization_id_project_id_fkey" FOREIGN KEY ("organization_id", "project_id") REFERENCES "projects"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "task_assignments" ADD CONSTRAINT "task_assignments_organization_id_project_id_task_id_fkey" FOREIGN KEY ("organization_id", "project_id", "task_id") REFERENCES "tasks"("organization_id", "project_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "task_assignments" ADD CONSTRAINT "task_assignments_organization_id_membership_id_fkey" FOREIGN KEY ("organization_id", "membership_id") REFERENCES "organization_memberships"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_organization_id_project_id_fkey" FOREIGN KEY ("organization_id", "project_id") REFERENCES "projects"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billable_items" ADD CONSTRAINT "billable_items_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billable_items" ADD CONSTRAINT "billable_items_organization_id_project_id_fkey" FOREIGN KEY ("organization_id", "project_id") REFERENCES "projects"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billable_items" ADD CONSTRAINT "billable_items_organization_id_project_id_task_id_fkey" FOREIGN KEY ("organization_id", "project_id", "task_id") REFERENCES "tasks"("organization_id", "project_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billable_items" ADD CONSTRAINT "billable_items_organization_id_project_id_expense_id_fkey" FOREIGN KEY ("organization_id", "project_id", "expense_id") REFERENCES "expenses"("organization_id", "project_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_organization_id_customer_id_fkey" FOREIGN KEY ("organization_id", "customer_id") REFERENCES "customers"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_organization_id_project_id_fkey" FOREIGN KEY ("organization_id", "project_id") REFERENCES "projects"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billable_item_portions" ADD CONSTRAINT "billable_item_portions_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billable_item_portions" ADD CONSTRAINT "billable_item_portions_organization_id_billable_item_id_fkey" FOREIGN KEY ("organization_id", "billable_item_id") REFERENCES "billable_items"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "billable_item_portions" ADD CONSTRAINT "billable_item_portions_organization_id_invoice_id_fkey" FOREIGN KEY ("organization_id", "invoice_id") REFERENCES "invoices"("organization_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- ==================================
-- CUSTOM DATABASE ENHANCEMENTS
-- ==================================

-- ----------------------------------
-- Custom Functions & Triggers
-- ----------------------------------

-- task_assignments immutability of unnasigned tasks
CREATE OR REPLACE FUNCTION enforce_task_assingment_immutability()
RETURNS TRIGGER AS $$
BEGIN
    -- Block all deletions to preserve temporal history
    IF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'Task assignments cannot be deleted; close the assignment by setting unassigned_at instead.';
    END IF;

    -- Once closed, the entire row is read-only
    IF OLD."unassigned_at" IS NOT NULL THEN
        RAISE EXCEPTION 'Task assignment is closed and read-only. Create a new assignment instead.';
    END IF;

    -- While open, only unassigned_at may change
    IF NEW.id IS DISTINCT FROM OLD.id
        OR NEW.organization_id IS DISTINCT FROM OLD.organization_id
        OR NEW.task_id IS DISTINCT FROM OLD.task_id
        OR NEW.membership_id IS DISTINCT FROM OLD.membership_id
        OR NEW.project_id IS DISTINCT FROM OLD.project_id
        OR NEW.assigned_at IS DISTINCT FROM OLD.assigned_at THEN
            RAISE EXCEPTION 'Task assignment core fields are immutable.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_task_assignment_immutability_trg
BEFORE UPDATE OR DELETE ON "task_assignments"
FOR EACH ROW
EXECUTE FUNCTION enforce_task_assingment_immutability();


-- billable_item_portions Immutability & Lifecycle Constraints
-- -------------------------------------------------------------

-- 1. Block all updates so existing rows are completely immutable
CREATE OR REPLACE FUNCTION prevent_portion_update()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Portions are immutable once created and cannot be updated';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_portion_immutability_trg
BEFORE UPDATE ON "billable_item_portions"
FOR EACH ROW
EXECUTE FUNCTION prevent_portion_update();

-- 2. Allow INSERT and DELETE only when the parent invoice status is 'draft'
CREATE OR REPLACE FUNCTION enforce_invoice_draft_status()
RETURNS TRIGGER AS $$
DECLARE
    target_invoice_id UUID;
    current_status TEXT;
BEGIN
    -- Get the target_invoice_id
    IF (TG_OP = 'DELETE') THEN
        target_invoice_id := OLD.invoice_id;
    ELSE
        target_invoice_id := NEW.invoice_id;
    END IF;

    -- Lock the parent invoice row to prevent race conditions
    SELECT status::TEXT INTO current_status
    FROM "invoices"
    WHERE id = target_invoice_id
    FOR SHARE;

    IF current_status IS DISTINCT FROM 'draft' THEN
        RAISE EXCEPTION 'Portions can only be inserted or deleted while the invoice status is draft (current status: %).', COALESCE(current_status, 'NOT FOUND');
    END IF;

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_invoice_draft_status_trg
BEFORE INSERT OR DELETE ON "billable_item_portions"
FOR EACH ROW
EXECUTE FUNCTION enforce_invoice_draft_status();

-- ----------------------------------
-- Check Constraints
-- ----------------------------------

ALTER TABLE "users"
ADD CONSTRAINT "users_name_length_check"
CHECK (char_length(btrim("name")) >= 2);

ALTER TABLE "users"
ADD CONSTRAINT "users_email_format_check"
CHECK ("email" ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$');

ALTER TABLE "organizations"
ADD CONSTRAINT "organizations_name_length_check"
CHECK (char_length(btrim("name")) >= 2);

ALTER TABLE "organizations"
ADD CONSTRAINT "organizations_slug_format_check"
CHECK ("slug" ~ '^[a-z0-9]+(-[a-z0-9]+)*$');

ALTER TABLE "organization_memberships"
ADD CONSTRAINT "organization_memberships_name_length_check"
CHECK (char_length(btrim("name")) >= 2);

ALTER TABLE "customers"
ADD CONSTRAINT "customers_name_length_check"
CHECK (char_length(btrim("name")) >= 2);

ALTER TABLE "customers"
ADD CONSTRAINT "customers_phone_number_format_check"
CHECK ("phone_number" ~ '^\+[1-9][0-9]{7,14}$');

ALTER TABLE "projects"
ADD CONSTRAINT "projects_name_length_check"
CHECK (char_length(btrim("name")) >= 2);

-- projects status dates consistency
ALTER TABLE "projects"
ADD CONSTRAINT "projects_status_dates_consistency_check"
CHECK (
    ("status" = 'planning'
        AND "planned_start_date" IS NULL
        AND "actual_start_date" IS NULL
        AND "actual_end_date" IS NULL)
    OR
    ("status" = 'scheduled'
        AND "planned_start_date" IS NOT NULL
        AND "actual_start_date" IS NULL
        AND "actual_end_date" IS NULL)
    OR
    ("status" = 'in_progress'
        AND "actual_start_date" IS NOT NULL
        AND "actual_end_date" IS NULL)
    OR
    ("status" = 'completed'
        AND "actual_end_date" IS NOT NULL)
    OR
    (("status" = 'on_hold' OR "status" = 'cancelled')
        AND "actual_end_date" IS NULL)
);

ALTER TABLE "tasks"
ADD CONSTRAINT "tasks_title_length_check"
CHECK (char_length(btrim("title")) >= 2);

ALTER TABLE "tasks"
ADD CONSTRAINT "tasks_labor_cost_nonnegative_check"
CHECK ("labor_cost_in_cents" >= 0);

ALTER TABLE "expenses"
ADD CONSTRAINT "expenses_material_cost_nonnegative_check"
CHECK ("material_cost_in_cents" >= 0);

ALTER TABLE "billable_items"
ADD CONSTRAINT "billable_items_total_value_nonnegative_check"
CHECK ("total_value_in_cents" >= 0);

-- billable_items source type consistency
ALTER TABLE "billable_items"
ADD CONSTRAINT "billable_items_source_type_consistency_check"
CHECK (
    ("type" = 'task' AND "task_id" IS NOT NULL AND "expense_id" IS NULL)
    OR
    ("type" = 'expense' AND "task_id" IS NULL AND "expense_id" IS NOT NULL)
    OR
    ("type" = 'direct' AND "task_id" IS NULL AND "expense_id" IS NULL)
);

-- invoices status timestamps consistency
ALTER TABLE "invoices"
ADD CONSTRAINT "invoices_status_timestamps_consistency_check"
CHECK (
    ("status" = 'draft' AND "issued_at" IS NULL AND "paid_at" IS NULL)
    OR
    ("status" = 'sent' AND "issued_at" IS NOT NULL AND "paid_at" IS NULL)
    OR
    ("status" = 'void' AND "issued_at" IS NOT NULL AND "paid_at" IS NULL)
    OR
    ("status" = 'paid' AND "issued_at" IS NOT NULL AND "paid_at" IS NOT NULL)
);

ALTER TABLE "billable_item_portions"
ADD CONSTRAINT "billable_item_portions_amount_positive_check"
CHECK ("amount_in_cents" > 0);

-- ----------------------------------
-- Partial indexes
-- ----------------------------------

-- tasks_assignments unique active assigment per task per member
CREATE UNIQUE INDEX "uq_task_assignments_active_member_task" ON "task_assignments"("organization_id", "task_id", "membership_id") WHERE "unassigned_at" IS NULL;

-- billable_items unique non-written-off per task
CREATE UNIQUE INDEX "uq_billable_items_active_task" ON "billable_items"("organization_id", "task_id") WHERE "is_written_off" = FALSE AND "task_id" IS NOT NULL;

-- billable_items unique non-written-off per expense 
CREATE UNIQUE INDEX "uq_billable_items_active_expense" ON "billable_items"("organization_id", "expense_id") WHERE "is_written_off" = FALSE AND "expense_id" IS NOT NULL;
