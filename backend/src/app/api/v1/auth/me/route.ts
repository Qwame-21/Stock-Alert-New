import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { getProfileByUserId } from "@/modules/profiles/profile-service";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (_request, { requestId, user }) => {
  const profile = await getProfileByUserId(user.id);

  return apiSuccess(
    {
      user: {
        id: user.id,
        email: user.email,
      },
      profile,
    },
    undefined,
    { requestId },
  );
});
