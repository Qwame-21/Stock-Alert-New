import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { syncPushSchema } from "@/modules/sync/sync-schema";
import { pushMutations } from "@/modules/sync/sync-service";
import { enforceRateLimit } from "@/lib/security/rate-limit";

export const dynamic = "force-dynamic";

export const POST = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "sync-push",
    identity: user.id,
    limit: 30,
    windowSeconds: 60,
  });
  const input = syncPushSchema.parse(await readJsonBody(request));
  const results = await pushMutations(user.id, input.mutations);

  return apiSuccess(results, undefined, {
    requestId,
    summary: {
      synced: results.filter((result) => result.status === "synced").length,
      conflicts: results.filter((result) => result.status === "conflict")
        .length,
      failed: results.filter((result) => result.status === "failed").length,
    },
  });
});
