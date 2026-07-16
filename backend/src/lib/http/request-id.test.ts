import { describe, expect, it } from "vitest";

import { getRequestId } from "@/lib/http/request-id";

describe("getRequestId", () => {
  it("preserves a valid caller request ID", () => {
    const request = new Request("https://api.example.test", {
      headers: { "x-request-id": "mobile-123" },
    });

    expect(getRequestId(request)).toBe("mobile-123");
  });

  it("replaces unsafe request IDs", () => {
    const request = new Request("https://api.example.test", {
      headers: { "x-request-id": "invalid request id" },
    });

    expect(getRequestId(request)).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    );
  });
});
