# Deployment and rollout

## Release order

1. Back up the staging database.
2. Apply migrations in timestamp order.
3. Deploy the backend container.
4. Verify `/api/v1/health` and `/api/v1/health/ready`.
5. Exercise registration, profile, inventory, booking, and sync flows in staging.
6. Release Flutter with remote feature flags disabled.
7. Enable remote bookings for internal users.
8. Enable remote inventory for one pharmacy cohort.
9. Enable background sync after conflict metrics remain acceptable.
10. Repeat the same sequence in production.

## Flutter rollout flags

```env
REMOTE_INVENTORY_ENABLED=false
REMOTE_BOOKINGS_ENABLED=false
BACKGROUND_SYNC_ENABLED=false
```

These flags retain SQLite behavior while a remote feature is disabled. Profile
and authentication migration is mandatory and therefore not feature-flagged.

## Required backend configuration

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `API_ALLOWED_ORIGINS`

Secrets must come from the deployment platform's encrypted secret store.

## Release gates

- CI succeeds for backend and Flutter.
- `npm audit --omit=dev` reports no known production vulnerabilities.
- Database migrations succeed in staging.
- Readiness remains healthy during a smoke-test window.
- Registration produces both shared and role-specific records.
- Replayed mutation IDs do not duplicate stock or appointments.
- Version conflicts appear as `409`, not silent overwrites.
- Audit logs contain request IDs without tokens or medical payloads.
- Database backup restoration has been tested.

## Rollback

1. Disable Flutter remote feature flags.
2. Stop routing new traffic to the affected backend release.
3. Redeploy the last known-good container image.
4. Keep additive migrations in place unless a reviewed corrective migration is
   safer than application rollback.
5. Replay only mutations whose IDs are not present in `sync_events`.
6. Document the affected request IDs and audit events.

Never roll back with destructive ad-hoc SQL against production.
