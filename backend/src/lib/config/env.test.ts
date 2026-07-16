import { describe, expect, it } from "vitest";

import { getBackendEnv } from "@/lib/config/env";

describe("backend environment", () => {
  it("accepts a complete configuration", () => {
    const env = getBackendEnv({
      SUPABASE_URL: "https://example.supabase.co",
      SUPABASE_PUBLISHABLE_KEY: "publishable",
      SUPABASE_SERVICE_ROLE_KEY: "service-role",
      TESTING_MODE: "true",
    });

    expect(env.SUPABASE_URL).toBe("https://example.supabase.co");
    expect(env.TESTING_MODE).toBe(true);
  });

  it("keeps testing mode disabled by default", () => {
    const env = getBackendEnv({
      SUPABASE_URL: "https://example.supabase.co",
      SUPABASE_PUBLISHABLE_KEY: "publishable",
      SUPABASE_SERVICE_ROLE_KEY: "service-role",
    });

    expect(env.TESTING_MODE).toBe(false);
  });

  it("rejects missing configuration", () => {
    expect(() => getBackendEnv({})).toThrow(
      "Invalid backend configuration",
    );
  });
});
