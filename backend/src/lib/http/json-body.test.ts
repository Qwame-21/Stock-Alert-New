import { describe, expect, it } from "vitest";

import { readJsonBody } from "@/lib/http/json-body";

describe("readJsonBody", () => {
  it("reads JSON request bodies", async () => {
    const request = new Request("https://api.example.test", {
      method: "POST",
      body: JSON.stringify({ value: 1 }),
    });

    await expect(readJsonBody(request)).resolves.toEqual({ value: 1 });
  });

  it("rejects invalid JSON", async () => {
    const request = new Request("https://api.example.test", {
      method: "POST",
      body: "{",
    });

    await expect(readJsonBody(request)).rejects.toMatchObject({
      status: 400,
      code: "INVALID_JSON",
    });
  });

  it("rejects bodies above the configured size", async () => {
    const request = new Request("https://api.example.test", {
      method: "POST",
      body: JSON.stringify({ value: "too large" }),
    });

    await expect(readJsonBody(request, 5)).rejects.toMatchObject({
      status: 413,
      code: "PAYLOAD_TOO_LARGE",
    });
  });
});
