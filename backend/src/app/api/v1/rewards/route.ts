import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { getPatientRewards } from "@/modules/rewards/reward-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (_request, { requestId, user }) => {
  const rewards = await getPatientRewards(user.id);
  return apiSuccess(rewards, undefined, { requestId });
});
