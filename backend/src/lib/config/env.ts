import { z } from "zod";

const backendEnvSchema = z.object({
  SUPABASE_URL: z.url(),
  SUPABASE_PUBLISHABLE_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  API_ALLOWED_ORIGINS: z.string().optional(),
  TESTING_MODE: z
    .enum(["true", "false"])
    .optional()
    .transform((value) => value === "true"),
  PAYSTACK_SECRET_KEY: z.string().startsWith("sk_").optional(),
  APP_PUBLIC_URL: z.url().optional(),
});

export type BackendEnv = z.infer<typeof backendEnvSchema>;

let cachedEnv: BackendEnv | undefined;

export function getBackendEnv(
  source: Record<string, string | undefined> = process.env,
): BackendEnv {
  if (source === process.env && cachedEnv) {
    return cachedEnv;
  }

  const result = backendEnvSchema.safeParse(source);
  if (!result.success) {
    const fields = result.error.issues
      .map((issue) => issue.path.join("."))
      .filter(Boolean)
      .join(", ");
    throw new Error(`Invalid backend configuration: ${fields}`);
  }

  if (source === process.env) {
    cachedEnv = result.data;
  }

  return result.data;
}
