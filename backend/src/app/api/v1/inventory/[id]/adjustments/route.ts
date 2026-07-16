import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { getPathUuid } from "@/lib/http/path-id";
import { readJsonBody } from "@/lib/http/json-body";
import { enforceRateLimit } from "@/lib/security/rate-limit";
import { inventoryAdjustmentSchema } from "@/modules/inventory/inventory-schema";
import { adjustInventoryStock } from "@/modules/inventory/inventory-service";

export const dynamic = "force-dynamic";

export const POST = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "inventory-write",
    identity: user.id,
    limit: 120,
    windowSeconds: 60,
  });
  const inventoryId = getPathUuid(request, 2);
  const input = inventoryAdjustmentSchema.parse(await readJsonBody(request));
  const item = await adjustInventoryStock(user.id, inventoryId, input);

  return apiSuccess(item, undefined, { requestId });
});
