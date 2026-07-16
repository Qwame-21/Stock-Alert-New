import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { getPathUuid } from "@/lib/http/path-id";
import { readJsonBody } from "@/lib/http/json-body";
import { enforceRateLimit } from "@/lib/security/rate-limit";
import {
  deleteInventorySchema,
  updateInventorySchema,
} from "@/modules/inventory/inventory-schema";
import {
  deleteInventoryItem,
  getInventoryItem,
  updateInventoryItem,
} from "@/modules/inventory/inventory-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (request, { requestId }) => {
  const item = await getInventoryItem(getPathUuid(request));
  return apiSuccess(item, undefined, { requestId });
});

export const PATCH = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "inventory-write",
    identity: user.id,
    limit: 120,
    windowSeconds: 60,
  });
  const inventoryId = getPathUuid(request);
  const input = updateInventorySchema.parse(await readJsonBody(request));
  const item = await updateInventoryItem(user.id, inventoryId, input);

  return apiSuccess(item, undefined, { requestId });
});

export const DELETE = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, {
    scope: "inventory-write",
    identity: user.id,
    limit: 120,
    windowSeconds: 60,
  });
  const inventoryId = getPathUuid(request);
  const input = deleteInventorySchema.parse(await readJsonBody(request));
  await deleteInventoryItem(user.id, inventoryId, input);

  return apiSuccess({ deleted: true }, undefined, { requestId });
});
