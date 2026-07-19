import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { createOrderSchema, orderQuerySchema } from "@/modules/orders/order-schema";
import { createOrder, listOrders } from "@/modules/orders/order-service";
export const dynamic = "force-dynamic";
export const GET = withAuth(async (request,{requestId,user}) => {
  const input=orderQuerySchema.parse(Object.fromEntries(new URL(request.url).searchParams));
  return apiSuccess(await listOrders(user.id,input.pharmacyId,input.status),undefined,{requestId});
});
export const POST = withAuth(async (request,{requestId,user}) => {
  const input=createOrderSchema.parse(await readJsonBody(request));
  return apiSuccess(await createOrder(user.id,input),{status:201},{requestId});
});
