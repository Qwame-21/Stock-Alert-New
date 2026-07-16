# StockAlert API contract

All application endpoints are versioned under `/api/v1`.

## Authentication

Protected endpoints require the current Supabase access token:

```http
Authorization: Bearer <access-token>
```

The backend validates the token with Supabase Auth. User IDs and roles supplied
inside request bodies are never treated as authoritative.

## Request IDs

Clients may send `X-Request-ID` using letters, numbers, `.`, `_`, `:`, or `-`.
Otherwise the backend generates a UUID. The value is returned in both the
response header and `meta.requestId`.

## Response envelope

Success:

```json
{
  "data": {},
  "error": null,
  "meta": {
    "requestId": "..."
  }
}
```

Failure:

```json
{
  "data": null,
  "error": {
    "code": "UNAUTHENTICATED",
    "message": "An access token is required."
  },
  "meta": {
    "requestId": "..."
  }
}
```

## Endpoints

### `GET /api/v1/health`

Public service-health check.

### `GET /api/v1/auth/me`

Returns the authenticated user's safe identity fields and current StockAlert
profile. A missing profile is represented as `profile: null`.

### `POST /api/v1/auth/register`

Creates a patient or pharmacy Supabase account and its profile. The request
uses a role-discriminated body, so patient fields cannot accidentally be
submitted as a pharmacy account. When Supabase email confirmation is enabled,
`confirmationRequired` is `true` and `session` is `null`.

### `GET /api/v1/profile`

Returns the authenticated user's profile, or `PROFILE_NOT_FOUND`.

### `PATCH /api/v1/profile`

Updates the authenticated user's editable profile fields. The account role
cannot be changed through this endpoint.

Registration now writes shared and role-specific data through the
service-role-only `create_account_profile` database function.

### `GET /api/v1/inventory`

Lists active inventory for a required `pharmacyId`. Supports `search`, `limit`,
`offset`, and `includeOutOfStock`.

### `POST /api/v1/inventory`

Creates an inventory batch. Requires pharmacy membership and a UUID
`mutationId`. A caller may reference an existing medicine or create catalogue
data with the inventory record.

### `GET /api/v1/inventory/:id`

Returns one active inventory batch with its medicine details.

### `PATCH /api/v1/inventory/:id`

Updates batch metadata using `mutationId` and `expectedVersion`.

### `DELETE /api/v1/inventory/:id`

Soft-deletes a batch using `mutationId` and `expectedVersion`.

### `POST /api/v1/inventory/:id/adjustments`

Atomically changes stock and appends an immutable movement. Duplicate
`mutationId` values are idempotent; stale `expectedVersion` values return
`VERSION_CONFLICT`.

### `GET /api/v1/bookings`

Lists appointments where the caller is the patient or belongs to the linked
pharmacy. Supports `status`, `upcoming`, `limit`, and `offset`.

### `POST /api/v1/bookings`

Creates a patient appointment. Provider and patient overlap checks are
performed inside the database transaction.

### `GET /api/v1/bookings/:id`

Returns an appointment only to its patient or linked pharmacy staff.

### `PATCH /api/v1/bookings/:id`

Reschedules or updates an appointment using optimistic version checking.
Patients cannot change pharmacy-managed status or video-link fields.

### `DELETE /api/v1/bookings/:id`

Cancels an appointment while retaining its audit history.

### `POST /api/v1/sync/push`

Pushes up to 50 ordered inventory or booking mutations. Each mutation receives
an independent `synced`, `conflict`, or `failed` result so successfully applied
operations can be removed from the device outbox.

### `GET /api/v1/sync/pull`

Returns participant-visible events after a numeric `cursor`. Results are
ordered and include `nextCursor` and `hasMore` metadata. Cursor values are
returned as strings to avoid JavaScript integer precision loss.

### `GET /api/v1/health/ready`

Checks validated server configuration and database connectivity. Returns
`503 NOT_READY` when the service should not receive production traffic.

## Operational limits

- JSON request bodies are limited to 1 MiB.
- Registration is limited by hashed client address.
- Profile, inventory, booking, and synchronization writes are limited by
  authenticated user ID.
- Rate-limit state is atomic and shared through PostgreSQL.
- Responses include defensive browser security headers.
