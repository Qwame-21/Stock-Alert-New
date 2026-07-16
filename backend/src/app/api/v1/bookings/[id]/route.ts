import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { getPathUuid } from "@/lib/http/path-id";
import { readJsonBody } from "@/lib/http/json-body";
import { enforceRateLimit } from "@/lib/security/rate-limit";
import {
  cancelBookingSchema,
  updateBookingSchema,
} from "@/modules/bookings/booking-schema";
import {
  cancelBooking,
  getBooking,
  updateBooking,
} from "@/modules/bookings/booking-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (request, { requestId, user }) => {
  const booking = await getBooking(user.id, getPathUuid(request));
  return apiSuccess(booking, undefined, { requestId });
});

export const PATCH = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "booking-write",
    identity: user.id,
    limit: 60,
    windowSeconds: 60,
  });
  const bookingId = getPathUuid(request);
  const input = updateBookingSchema.parse(await readJsonBody(request));
  const booking = await updateBooking(user.id, bookingId, input);

  return apiSuccess(booking, undefined, { requestId });
});

export const DELETE = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "booking-write",
    identity: user.id,
    limit: 60,
    windowSeconds: 60,
  });
  const bookingId = getPathUuid(request);
  const input = cancelBookingSchema.parse(await readJsonBody(request));
  const booking = await cancelBooking(user.id, bookingId, input);

  return apiSuccess(booking, undefined, { requestId });
});
