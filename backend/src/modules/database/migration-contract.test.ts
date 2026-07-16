import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const migration = readFileSync(
  resolve(
    process.cwd(),
    "supabase/migrations/20260716160000_create_stockalert_domain.sql",
  ),
  "utf8",
);

const inventoryCommands = readFileSync(
  resolve(
    process.cwd(),
    "supabase/migrations/20260716170000_add_inventory_commands.sql",
  ),
  "utf8",
);

const appointmentCommands = readFileSync(
  resolve(
    process.cwd(),
    "supabase/migrations/20260716180000_add_appointment_commands.sql",
  ),
  "utf8",
);

const syncCommands = readFileSync(
  resolve(
    process.cwd(),
    "supabase/migrations/20260716190000_add_sync_pull.sql",
  ),
  "utf8",
);

const securityOperations = readFileSync(
  resolve(
    process.cwd(),
    "supabase/migrations/20260716200000_add_security_operations.sql",
  ),
  "utf8",
);

const rateLimitFix = readFileSync(
  resolve(
    process.cwd(),
    "supabase/migrations/20260716210000_fix_rate_limit_timestamp.sql",
  ),
  "utf8",
);

const domainTables = [
  "patients",
  "pharmacies",
  "pharmacy_staff",
  "medicines",
  "inventory_items",
  "inventory_movements",
  "appointments",
  "notification_preferences",
  "verification_documents",
  "sync_events",
];

describe("database migration contract", () => {
  it.each(domainTables)("creates and protects the %s table", (table) => {
    expect(migration).toContain(`create table if not exists public.${table}`);
    expect(migration).toContain(
      `alter table public.${table} enable row level security`,
    );
  });

  it("restricts the atomic registration RPC to service role", () => {
    expect(migration).toContain(
      "revoke all on function public.create_account_profile(uuid, jsonb, jsonb)",
    );
    expect(migration).toContain("to service_role");
  });

  it("uses mutation IDs for idempotency", () => {
    expect(migration).toContain("mutation_id uuid not null unique");
  });

  it("wraps the migration in a transaction", () => {
    expect(migration.trimStart().startsWith("begin;")).toBe(true);
    expect(migration.trimEnd().endsWith("commit;")).toBe(true);
  });
});

describe("inventory command migration", () => {
  it.each([
    "create_inventory_item",
    "adjust_inventory_stock",
    "update_inventory_item",
  ])("restricts %s to the service role", (command) => {
    expect(inventoryCommands).toContain(
      `create or replace function public.${command}`,
    );
    expect(inventoryCommands).toContain("to service_role");
  });

  it("locks inventory rows before stock adjustments", () => {
    expect(inventoryCommands).toContain("for update;");
    expect(inventoryCommands).toContain("Inventory version conflict");
  });
});

describe("appointment command migration", () => {
  it.each([
    "create_appointment",
    "update_appointment",
    "cancel_appointment",
  ])("restricts %s to the service role", (command) => {
    expect(appointmentCommands).toContain(
      `create or replace function public.${command}`,
    );
    expect(appointmentCommands).toContain("to service_role");
  });

  it("serializes competing time-slot writes", () => {
    expect(appointmentCommands).toContain("pg_advisory_xact_lock");
    expect(appointmentCommands).toContain("Provider time conflict");
    expect(appointmentCommands).toContain("Patient time conflict");
  });
});

describe("sync pull migration", () => {
  it("restricts sync event reads to the service role", () => {
    expect(syncCommands).toContain(
      "create or replace function public.pull_sync_events",
    );
    expect(syncCommands).toContain("to service_role");
  });

  it("includes patient and pharmacy participant visibility", () => {
    expect(syncCommands).toContain("event.actor_profile_id = actor_id");
    expect(syncCommands).toContain("from public.pharmacy_staff staff");
    expect(syncCommands).toContain("appointment.patient_profile_id = actor_id");
  });
});

describe("security operations migration", () => {
  it("creates rate-limit and audit storage with RLS", () => {
    for (const table of ["api_rate_limits", "audit_events"]) {
      expect(securityOperations).toContain(
        `create table if not exists public.${table}`,
      );
      expect(securityOperations).toContain(
        `alter table public.${table} enable row level security`,
      );
    }
  });

  it.each(["consume_rate_limit", "record_audit_event"])(
    "restricts %s to service role",
    (command) => {
      expect(securityOperations).toContain(
        `create or replace function public.${command}`,
      );
      expect(securityOperations).toContain("to service_role");
    },
  );
});

describe("rate-limit timestamp correction", () => {
  it("uses an unambiguous timestamptz variable", () => {
    expect(rateLimitFix).toContain("now_at timestamptz := now()");
    expect(rateLimitFix).not.toContain("current_time timestamptz");
  });
});
