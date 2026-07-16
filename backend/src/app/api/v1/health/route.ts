import { apiSuccess } from "@/lib/http/api-response";
import { withRoute } from "@/lib/http/with-route";

export const dynamic = "force-dynamic";

export const GET = withRoute(async (_request, { requestId }) => {
  return apiSuccess({
    service: "stockalert-backend",
    status: "ok",
    timestamp: new Date().toISOString(),
  }, undefined, { requestId });
});
