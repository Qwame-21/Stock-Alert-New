import { describe, expect, it } from "vitest";

import {
  hasFieldsForAnotherRole,
  profileUpdateSchema,
} from "@/modules/profiles/profile";

describe("profileUpdateSchema", () => {
  it("accepts editable profile fields", () => {
    expect(
      profileUpdateSchema.parse({
        phoneNumber: "+233244000000",
        location: "Kumasi",
      }),
    ).toEqual({
      phoneNumber: "+233244000000",
      location: "Kumasi",
    });
  });

  it("prevents role updates", () => {
    expect(() =>
      profileUpdateSchema.parse({ role: "pharmacy" }),
    ).toThrow();
  });

  it("rejects empty updates", () => {
    expect(() => profileUpdateSchema.parse({})).toThrow();
  });

  it("prevents patient accounts from changing pharmacy fields", () => {
    expect(
      hasFieldsForAnotherRole("patient", {
        pharmacyName: "Another Pharmacy",
      }),
    ).toBe(true);
  });

  it("allows fields shared by both roles", () => {
    expect(
      hasFieldsForAnotherRole("pharmacy", {
        phoneNumber: "+233244000000",
      }),
    ).toBe(false);
  });
});
