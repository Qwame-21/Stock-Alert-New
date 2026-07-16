import { HttpError } from "@/lib/http/errors";

export function getBearerToken(request: Request): string {
  const authorization = request.headers.get("authorization");
  if (!authorization) {
    throw new HttpError(
      401,
      "UNAUTHENTICATED",
      "An access token is required.",
    );
  }

  const [scheme, token, extra] = authorization.trim().split(/\s+/);
  if (scheme?.toLowerCase() !== "bearer" || !token || extra) {
    throw new HttpError(
      401,
      "UNAUTHENTICATED",
      "The authorization header must use the Bearer scheme.",
    );
  }

  return token;
}
