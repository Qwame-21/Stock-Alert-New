import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { availabilityUpdateSchema } from "@/modules/providers/provider-schema";
import { getProviderAccount, updateAvailability } from "@/modules/providers/provider-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (_request, { requestId, user }) =>
  apiSuccess(await getProviderAccount(user.id), undefined, { requestId }),
);

export const PUT = withAuth(async (request, { requestId, user }) => {
  const input = availabilityUpdateSchema.parse(await readJsonBody(request));
  return apiSuccess(await updateAvailability(user.id, input), undefined, { requestId });
});
