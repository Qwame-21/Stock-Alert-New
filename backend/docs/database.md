# StockAlert database

The canonical schema is managed by timestamped SQL migrations in
`supabase/migrations`.

## Domain ownership

- `profiles` stores shared identity and routing fields.
- `patients` stores health and emergency-contact fields.
- `pharmacies` stores pharmacy business and verification fields.
- `pharmacy_staff` grants pharmacy-scoped access.
- `medicines` is the shared medicine catalogue.
- `inventory_items` stores batches and current quantities.
- `inventory_movements` is the immutable stock audit trail.
- `appointments` stores patient consultations.
- `notification_preferences` stores user-controlled delivery preferences.
- `verification_documents` stores private object-storage references.
- `sync_events` provides mutation idempotency and cursor-based synchronization.

## Applying migrations

Review the migration against a staging project first. With the Supabase CLI:

```sh
supabase link --project-ref <staging-project-ref>
supabase db push
```

This is an external database mutation and is intentionally not performed by
the repository build.

## Registration

`create_account_profile` atomically writes the shared profile and its
role-specific patient or pharmacy data. Execute permission is restricted to
`service_role`.

The `profiles_sync_domain` trigger also backfills role records for legacy
Flutter clients that still write directly to `profiles` during the migration.

Inventory writes use service-role-only commands:

- `create_inventory_item`
- `adjust_inventory_stock`
- `update_inventory_item`

These functions validate pharmacy membership, record sync mutations, lock
stock rows, and enforce optimistic versions.

Appointment writes use `create_appointment`, `update_appointment`, and
`cancel_appointment`. Advisory transaction locks serialize competing provider
and patient time slots before overlap checks.

`pull_sync_events` exposes ordered changes to the original actor, the patient
in an appointment, and current staff of a related pharmacy. It remains
service-role-only; the API authenticates callers before invoking it.

`consume_rate_limit` provides deployment-wide atomic throttling without storing
raw IP addresses. `audit_events` stores security-relevant actions with request
IDs and deliberately excludes credentials, tokens, and health payloads.

## Security

Every application table has row-level security enabled. The Next.js backend
uses the service-role client only after independently validating the caller.
Client-side access remains constrained by ownership and pharmacy membership.
