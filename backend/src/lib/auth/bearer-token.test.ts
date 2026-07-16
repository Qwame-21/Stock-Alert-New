import { describe, expect, it } from "vitest";

import { getBearerToken } from "@/lib/auth/bearer-token";
import { HttpError } from "@/lib/http/errors";

describe("getBearerToken", () => {
  it("returns a bearer token", () => {
    const request = new Request("https://api.example.test", {
      headers: { authorization: "Bearer valid-token" },
    });

    expect(getBearerToken(request)).toBe("valid-token");
  });

  it("rejects a missing token", () => {
    const request = new Request("https://api.example.test");

    expect(() => getBearerToken(request)).toThrowError(HttpError);
  });

  it("rejects malformed authorization", () => {
    const request = new Request("https://api.example.test", {
      headers: { authorization: "Basic credentials" },
    });

    expect(() => getBearerToken(request)).toThrow(
      "The authorization header must use the Bearer scheme.",
    );
  });
});
