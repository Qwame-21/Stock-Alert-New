import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { syncPullQuerySchema } from "@/modules/sync/sync-schema";
import { pullEvents } from "@/modules/sync/sync-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (request, { requestId, user }) => {
  const query = syncPullQuerySchema.parse(
    Object.fromEntries(new URL(request.url).searchParams),
  );
  const result = await pullEvents(user.id, query.cursor, query.limit);

  return apiSuccess(result.events, undefined, {
    requestId,
    nextCursor: result.nextCursor,
    hasMore: result.hasMore,
  });
});
