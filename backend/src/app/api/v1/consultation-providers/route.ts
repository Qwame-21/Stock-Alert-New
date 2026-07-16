import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { providerQuerySchema } from "@/modules/providers/provider-schema";
import { listProviders } from "@/modules/providers/provider-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (request, { requestId }) => {
  const input = providerQuerySchema.parse(
    Object.fromEntries(new URL(request.url).searchParams),
  );
  return apiSuccess(
    await listProviders(input.date, input.specialty),
    undefined,
    { requestId },
  );
});
