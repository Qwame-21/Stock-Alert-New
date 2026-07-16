import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { withRoute } from "@/lib/http/with-route";
import { recordAuditEvent } from "@/lib/observability/audit";
import { enforceRateLimit } from "@/lib/security/rate-limit";
import { registrationSchema } from "@/modules/registration/registration-schema";
import { registerAccount } from "@/modules/registration/registration-service";

export const dynamic = "force-dynamic";

export const POST = withRoute(async (request, { requestId }) => {
  await enforceRateLimit(request, {
    scope: "registration",
    limit: 5,
    windowSeconds: 3600,
  });
  const input = registrationSchema.parse(await readJsonBody(request));
  const result = await registerAccount(input);
  await recordAuditEvent({
    actorId: result.user.id,
    action: "account.registered",
    entityType: "profile",
    entityId: result.user.id,
    requestId,
    metadata: { role: input.role },
  });

  return apiSuccess(result, { status: 201 }, { requestId });
});
