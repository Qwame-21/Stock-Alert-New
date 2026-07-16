import { createHash } from "node:crypto";

import { getBackendEnv } from "@/lib/config/env";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";

interface RateLimitOptions {
  scope: string;
  limit: number;
  windowSeconds: number;
  identity?: string;
}

export function clientIdentifier(request: Request, identity?: string) {
  const forwarded = request.headers.get("x-forwarded-for")?.split(",")[0].trim();
  const source = identity ?? forwarded ?? "unknown";
  return createHash("sha256").update(source).digest("hex");
}

export async function enforceRateLimit(
  request: Request,
  options: RateLimitOptions,
) {
  if (process.env.NODE_ENV === "test" || getBackendEnv().TESTING_MODE) {
    return;
  }

  const identifier = clientIdentifier(request, options.identity);
  const { data, error } = await getSupabaseAdmin().rpc("consume_rate_limit", {
    rate_key: `${options.scope}:${identifier}`,
    maximum_requests: options.limit,
    window_seconds: options.windowSeconds,
  });

  if (error) {
    throw new HttpError(
      503,
      "RATE_LIMIT_UNAVAILABLE",
      "Request throttling is temporarily unavailable.",
    );
  }

  const result = Array.isArray(data) ? data[0] : data;
  if (!result?.allowed) {
    throw new HttpError(
      429,
      "RATE_LIMITED",
      "Too many requests. Please try again later.",
      { resetAt: result?.reset_at },
    );
  }
}
