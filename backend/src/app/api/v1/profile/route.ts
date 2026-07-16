import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { readJsonBody } from "@/lib/http/json-body";
import { recordAuditEvent } from "@/lib/observability/audit";
import { enforceRateLimit } from "@/lib/security/rate-limit";
import {
  profileUpdateSchema,
} from "@/modules/profiles/profile";
import {
  getProfileByUserId,
  updateProfile,
} from "@/modules/profiles/profile-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (_request, { requestId, user }) => {
  const profile = await getProfileByUserId(user.id);
  if (!profile) {
    throw new HttpError(404, "PROFILE_NOT_FOUND", "The profile was not found.");
  }

  return apiSuccess(profile, undefined, { requestId });
});

export const PATCH = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "profile-update",
    identity: user.id,
    limit: 30,
    windowSeconds: 60,
  });
  const input = profileUpdateSchema.parse(await readJsonBody(request));
  const profile = await updateProfile(user.id, input);
  await recordAuditEvent({
    actorId: user.id,
    action: "profile.updated",
    entityType: "profile",
    entityId: user.id,
    requestId,
    metadata: { fields: Object.keys(input) },
  });

  return apiSuccess(profile, undefined, { requestId });
});
