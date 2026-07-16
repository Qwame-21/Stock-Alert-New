import { describe, expect, it } from "vitest";

import { clientIdentifier } from "@/lib/security/rate-limit";

describe("clientIdentifier", () => {
  it("hashes forwarded client addresses", () => {
    const request = new Request("https://api.example.test", {
      headers: { "x-forwarded-for": "203.0.113.10, 10.0.0.1" },
    });
    const identifier = clientIdentifier(request);

    expect(identifier).toMatch(/^[a-f0-9]{64}$/);
    expect(identifier).not.toContain("203.0.113.10");
  });

  it("prefers authenticated identity", () => {
    const request = new Request("https://api.example.test", {
      headers: { "x-forwarded-for": "203.0.113.10" },
    });

    expect(clientIdentifier(request, "user-123")).toBe(
      clientIdentifier(new Request("https://api.example.test"), "user-123"),
    );
  });
});
