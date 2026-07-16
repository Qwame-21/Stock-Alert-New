import { getBackendEnv } from "@/lib/config/env";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { withRoute } from "@/lib/http/with-route";

export const dynamic = "force-dynamic";

export const GET = withRoute(async (_request, { requestId }) => {
  getBackendEnv();
  const { error } = await getSupabaseAdmin()
    .from("profiles")
    .select("id", { head: true, count: "exact" })
    .limit(1);

  if (error) {
    throw new HttpError(
      503,
      "NOT_READY",
      "The database is not available.",
    );
  }

  return apiSuccess(
    { service: "stockalert-backend", status: "ready" },
    undefined,
    { requestId },
  );
});
