# StockAlert backend

This Next.js application is the server-side boundary for StockAlert. It
provides configuration validation, Supabase server clients, versioned API
responses, authenticated route middleware, request tracing, and test tooling.

## Setup

```sh
cp .env.example .env.local
npm install
npm run dev
```

Check the service at `GET /api/v1/health`.

Protected endpoints use a Supabase access token:

```sh
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <access-token>"
```

See [`docs/api-contract.md`](docs/api-contract.md) for the current contract.

Phase 3 adds backend-owned patient/pharmacy registration and protected profile
read/update endpoints.

Phase 4 database migrations and deployment notes are documented in
[`docs/database.md`](docs/database.md).

Phase 5 adds pharmacy inventory CRUD and atomic stock-adjustment endpoints.

Phase 6 adds participant-scoped booking APIs with conflict-safe scheduling.

Phase 7 adds ordered batch push and participant-aware cursor pull
synchronization.

Phase 8 connects Flutter repositories and its SQLite outbox to the API.
`API_ALLOWED_ORIGINS` controls browser origins permitted to call the backend.

Phase 9 adds shared rate limiting, audit events, structured request logging,
security headers, payload limits, and readiness checks.

Phase 10 adds release flags, CI, standalone container builds, staging gates,
and rollback documentation.

In development, every API exchange is logged to the terminal with request and
response JSON. Credentials, tokens, document paths, and sensitive health fields
are redacted. Production logs retain request metadata without payload bodies.

## Commands

```sh
npm run lint
npm run typecheck
npm test
npm run build
```

## Security

`SUPABASE_SERVICE_ROLE_KEY` is server-only. Never expose it through a
`NEXT_PUBLIC_` variable or copy it into the Flutter application.
