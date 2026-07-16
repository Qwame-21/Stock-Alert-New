import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { enforceRateLimit } from "@/lib/security/rate-limit";
import {
  createInventorySchema,
  inventoryQuerySchema,
} from "@/modules/inventory/inventory-schema";
import {
  createInventoryItem,
  listInventory,
} from "@/modules/inventory/inventory-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (request, { requestId }) => {
  const query = inventoryQuerySchema.parse(
    Object.fromEntries(new URL(request.url).searchParams),
  );
  const result = await listInventory(query);

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
    scope: "inventory-write",
    identity: user.id,
    limit: 120,
    windowSeconds: 60,
  });
  const input = createInventorySchema.parse(await readJsonBody(request));
  const item = await createInventoryItem(user.id, input);

  return apiSuccess(item, { status: 201 }, { requestId });
});
