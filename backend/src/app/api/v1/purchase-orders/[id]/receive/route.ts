import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { getPathUuid } from "@/lib/http/path-id";
import { readJsonBody } from "@/lib/http/json-body";
import { receiveOrderSchema } from "@/modules/orders/order-schema";
import { receiveOrder } from "@/modules/orders/order-service";
export const dynamic = "force-dynamic";
export const POST = withAuth(async(request,{requestId,user})=>{
  const input=receiveOrderSchema.parse(await readJsonBody(request));
  return apiSuccess(await receiveOrder(user.id,getPathUuid(request,2),input.lines),undefined,{requestId});
});
