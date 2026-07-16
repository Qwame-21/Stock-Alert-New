import { describe, expect, it, vi } from "vitest";

import { authenticateRequest } from "@/lib/auth/authenticate";

const user = {
  id: "user-123",
  email: "patient@example.com",
  user_metadata: { role: "patient" },
};

describe("authenticateRequest", () => {
  it("returns a safe authenticated user", async () => {
    const verifier = vi.fn().mockResolvedValue({ user, error: null });
    const request = new Request("https://api.example.test", {
      headers: { authorization: "Bearer token" },
    });

    await expect(authenticateRequest(request, verifier)).resolves.toEqual({
      id: "user-123",
      email: "patient@example.com",
      metadata: { role: "patient" },
    });
    expect(verifier).toHaveBeenCalledWith("token");
  });

  it("rejects invalid or expired tokens", async () => {
    const verifier = vi
      .fn()
      .mockResolvedValue({ user: null, error: new Error("invalid") });
    const request = new Request("https://api.example.test", {
      headers: { authorization: "Bearer expired" },
    });

    await expect(authenticateRequest(request, verifier)).rejects.toMatchObject({
      status: 401,
      code: "UNAUTHENTICATED",
    });
  });
});
