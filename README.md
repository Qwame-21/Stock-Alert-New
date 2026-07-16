# StockAlert

StockAlert is a Flutter application with an incrementally extracted Next.js
backend.

## Flutter app

```sh
flutter pub get
flutter run
```

The Flutter application currently uses `.env` for its public client
configuration.

Set `API_BASE_URL` to the reachable Next.js backend. Android emulators commonly
use `http://10.0.2.2:3000`; iOS simulators and Flutter web can usually use
`http://127.0.0.1:3000`.

Remote inventory, bookings, and background sync can be enabled independently
for gradual rollout. See the backend
[`deployment guide`](backend/docs/deployment.md).

Debug Flutter builds log each backend request, response, timeout, and network
failure using the same `X-Request-ID` as the server. Sensitive fields are
redacted, and release builds do not emit payload logs.

## Next.js backend

The backend foundation lives in [`backend/`](backend/README.md). During the
migration it will become the only component permitted to perform privileged
database operations.
