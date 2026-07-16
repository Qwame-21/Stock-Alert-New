# Staging acceptance checklist

- [ ] All migrations are applied in timestamp order.
- [ ] Backend readiness returns HTTP 200.
- [ ] CORS accepts only expected Flutter web origins.
- [ ] Patient and pharmacy registration both succeed.
- [ ] Duplicate registration is rejected.
- [ ] Role-specific profile fields are enforced.
- [ ] Pharmacy membership is required for inventory writes.
- [ ] Duplicate inventory mutation IDs are idempotent.
- [ ] Negative stock is rejected.
- [ ] Concurrent stock versions return a conflict.
- [ ] Appointment overlaps are rejected.
- [ ] Patients cannot update pharmacy-managed booking fields.
- [ ] Sync pull returns only participant-visible events.
- [ ] Rate limits return HTTP 429 at their thresholds.
- [ ] Request and audit logs contain matching request IDs.
- [ ] Flutter falls back to SQLite when remote flags are disabled.
- [ ] Offline mutations drain after connectivity returns.
- [ ] Backup restoration and container rollback are rehearsed.
