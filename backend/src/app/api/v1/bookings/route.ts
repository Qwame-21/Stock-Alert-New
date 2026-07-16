import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { enforceRateLimit } from "@/lib/security/rate-limit";
import {
  bookingQuerySchema,
  createBookingSchema,
} from "@/modules/bookings/booking-schema";
import {
  createBooking,
  listBookings,
} from "@/modules/bookings/booking-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (request, { requestId, user }) => {
  const query = bookingQuerySchema.parse(
    Object.fromEntries(new URL(request.url).searchParams),
  );
  const result = await listBookings(user.id, query);

  return apiSuccess(result.items, undefined, {
    requestId,
    pagination: {
      limit: query.limit,
      offset: query.offset,
      total: result.total,
    },
  });
});

export const POST = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "booking-create",
    identity: user.id,
    limit: 20,
    windowSeconds: 60,
  });
  const input = createBookingSchema.parse(await readJsonBody(request));
  const booking = await createBooking(user.id, input);

  return apiSuccess(booking, { status: 201 }, { requestId });
});
