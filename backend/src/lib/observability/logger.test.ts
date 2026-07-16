import { describe, expect, it } from "vitest";

import { redactForLog } from "@/lib/observability/logger";

describe("redactForLog", () => {
  it("redacts credentials and health fields recursively", () => {
    expect(
      redactForLog({
        email: "patient@example.com",
        password: "secret",
        profile: {
          knownAllergies: ["penicillin"],
          accessToken: "token",
        },
      }),
    ).toEqual({
      email: "patient@example.com",
      password: "[REDACTED]",
      profile: {
        knownAllergies: "[REDACTED]",
        accessToken: "[REDACTED]",
      },
    });
  });

  it("preserves ordinary API fields", () => {
    expect(
      redactForLog({
        mutationId: "mutation-1",
        quantity: 20,
        status: "synced",
      }),
    ).toEqual({
      mutationId: "mutation-1",
      quantity: 20,
      status: "synced",
    });
  });
});
