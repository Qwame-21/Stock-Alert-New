import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { getPathUuid } from "@/lib/http/path-id";
import { readJsonBody } from "@/lib/http/json-body";
import { updateOrderStatusSchema } from "@/modules/orders/order-schema";
import { updateOrderStatus } from "@/modules/orders/order-service";
export const dynamic = "force-dynamic";
export const PATCH = withAuth(async (request,{requestId,user}) => {
  const input=updateOrderStatusSchema.parse(await readJsonBody(request));
  return apiSuccess(await updateOrderStatus(user.id,getPathUuid(request),input.status,input.note),undefined,{requestId});
});
