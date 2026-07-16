import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { pharmacyDiscoveryQuerySchema } from "@/modules/discovery/discovery-schema";
import { discoverPharmacies } from "@/modules/discovery/discovery-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (request, { requestId }) => {
  const input = pharmacyDiscoveryQuerySchema.parse(
    Object.fromEntries(new URL(request.url).searchParams),
  );
  const pharmacies = await discoverPharmacies(input);
  return apiSuccess(pharmacies, undefined, { requestId });
});
