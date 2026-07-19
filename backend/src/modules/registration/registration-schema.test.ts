import { describe, expect, it } from "vitest";

import { registrationSchema } from "@/modules/registration/registration-schema";

describe("registrationSchema", () => {
  it("accepts a patient registration", () => {
    const result = registrationSchema.parse({
      role: "patient",
      email: "PATIENT@EXAMPLE.COM",
      password: "secure-password",
      phoneNumber: "+233200000000",
      fullName: "Ama Mensah",
      dateOfBirth: "1995-04-12",
      gender: "female",
    });

    expect(result.email).toBe("patient@example.com");
  });

  it("accepts a pharmacy registration", () => {
    expect(() =>
      registrationSchema.parse({
        role: "pharmacy",
        email: "pharmacy@example.com",
        password: "secure-password",
        phoneNumber: "+233200000000",
        pharmacyName: "Community Pharmacy",
        licenseNumber: "PH-123",
        location: "Accra",
      }),
    ).not.toThrow();
  });

  it("accepts a consultation provider registration", () => {
    expect(() =>
      registrationSchema.parse({
        role: "provider",
        email: "provider@example.com",
        password: "secure-password",
        phoneNumber: "+233200000000",
        fullName: "Dr. Ama Mensah",
        specialty: "General Practice",
        professionalLicense: "MDC-12345",
        registrationAuthority: "Medical and Dental Council",
        yearsExperience: 8,
        consultationMode: "both",
        consultationDuration: 30,
        profileImageBase64: "aGVhbHRoY2FyZS1waG90bw==",
        profileImageExtension: "jpg",
        providerPolicyAccepted: true,
      }),
    ).not.toThrow();
  });

  it("rejects patient data for a pharmacy account", () => {
    expect(() =>
      registrationSchema.parse({
        role: "pharmacy",
        email: "pharmacy@example.com",
        password: "secure-password",
        phoneNumber: "+233200000000",
        fullName: "Wrong Shape",
        dateOfBirth: "1995-04-12",
        gender: "female",
      }),
    ).toThrow();
  });

  it("rejects weak passwords", () => {
    expect(() =>
      registrationSchema.parse({
        role: "patient",
        email: "patient@example.com",
        password: "short",
        phoneNumber: "+233200000000",
        fullName: "Ama Mensah",
        dateOfBirth: "1995-04-12",
        gender: "female",
      }),
    ).toThrow();
  });
});
