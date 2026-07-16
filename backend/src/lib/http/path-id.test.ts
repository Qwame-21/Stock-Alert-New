import { describe, expect, it } from "vitest";

import { getPathUuid } from "@/lib/http/path-id";

const uuid = "8c879b85-91f8-4fdb-b5fc-08aeed6635cb";

describe("getPathUuid", () => {
  it("reads the final UUID segment", () => {
    const request = new Request(`https://api.test/api/v1/inventory/${uuid}`);
    expect(getPathUuid(request)).toBe(uuid);
  });

  it("reads an earlier UUID segment", () => {
    const request = new Request(
      `https://api.test/api/v1/inventory/${uuid}/adjustments`,
    );
    expect(getPathUuid(request, 2)).toBe(uuid);
  });

  it("rejects invalid IDs", () => {
    const request = new Request("https://api.test/api/v1/inventory/not-valid");
    expect(() => getPathUuid(request)).toThrow("A valid UUID is required.");
  });
});
