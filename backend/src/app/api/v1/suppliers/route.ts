import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { supplierInputSchema, supplierQuerySchema } from "@/modules/orders/order-schema";
import { createSupplier, listSuppliers } from "@/modules/orders/order-service";
export const dynamic = "force-dynamic";
export const GET = withAuth(async (request,{requestId,user}) => {
  const input=supplierQuerySchema.parse(Object.fromEntries(new URL(request.url).searchParams));
  return apiSuccess(await listSuppliers(user.id,input.pharmacyId),undefined,{requestId});
});
export const POST = withAuth(async (request,{requestId,user}) => {
  const input=supplierInputSchema.parse(await readJsonBody(request));
  return apiSuccess(await createSupplier(user.id,input),{status:201},{requestId});
});
