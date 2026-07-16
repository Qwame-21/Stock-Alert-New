import { describe, expect, it } from "vitest";

import { apiError, apiSuccess } from "@/lib/http/api-response";

describe("API responses", () => {
  it("creates a successful response envelope", async () => {
    const response = apiSuccess({ status: "ok" });

    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({
      data: { status: "ok" },
      error: null,
      meta: {},
    });
  });

  it("creates an error response envelope", async () => {
    const response = apiError(403, {
      code: "FORBIDDEN",
      message: "Access denied.",
    });

    expect(response.status).toBe(403);
    await expect(response.json()).resolves.toEqual({
      data: null,
      error: {
        code: "FORBIDDEN",
        message: "Access denied.",
      },
      meta: {},
    });
  });

  it("returns the request ID in metadata and response headers", async () => {
    const response = apiSuccess(
      { status: "ok" },
      undefined,
      { requestId: "request-123" },
    );

    expect(response.headers.get("x-request-id")).toBe("request-123");
    await expect(response.json()).resolves.toMatchObject({
      meta: { requestId: "request-123" },
    });
  });
});
