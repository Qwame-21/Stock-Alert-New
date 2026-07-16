import type { AuthenticatedUser } from "@/lib/auth/authenticated-user";
import { authenticateRequest } from "@/lib/auth/authenticate";
import { withRoute } from "@/lib/http/with-route";

export interface AuthenticatedContext {
  requestId: string;
  user: AuthenticatedUser;
}

type AuthenticatedHandler = (
  request: Request,
  context: AuthenticatedContext,
) => Promise<Response>;

export function withAuth(handler: AuthenticatedHandler) {
  return withRoute(async (request, { requestId }) => {
    const user = await authenticateRequest(request);
    return handler(request, { requestId, user });
  });
}
