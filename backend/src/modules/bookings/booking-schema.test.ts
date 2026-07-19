import { describe, expect, it } from "vitest";

import {
  bookingQuerySchema,
  cancelBookingSchema,
  createBookingSchema,
  updateBookingSchema,
} from "@/modules/bookings/booking-schema";

const uuid = "8c879b85-91f8-4fdb-b5fc-08aeed6635cb";

describe("booking schemas", () => {
  it("accepts a booking", () => {
    expect(() =>
      createBookingSchema.parse({
        mutationId: uuid,
        providerId: uuid,
        providerName: "Dr. Emmanuel Boateng",
        scheduledAt: "2030-07-20T10:30:00+00:00",
        consultationMode: "video",
        clinicalReason: "Recurring headaches",
        patientCondition: "No known chronic condition",
        requestedSupport: "Assessment and treatment advice",
      }),
    ).not.toThrow();
  });

  it("rejects invalid appointment durations", () => {
    expect(() =>
      createBookingSchema.parse({
        mutationId: uuid,
        providerId: uuid,
        providerName: "Dr. Emmanuel Boateng",
        scheduledAt: "2030-07-20T10:30:00+00:00",
        consultationMode: "video",
        clinicalReason: "Recurring headaches",
        patientCondition: "No known chronic condition",
        requestedSupport: "Assessment and treatment advice",
        durationMinutes: 2,
      }),
    ).toThrow();
  });

  it("requires an editable field for updates", () => {
    expect(() =>
      updateBookingSchema.parse({
        mutationId: uuid,
        expectedVersion: 1,
      }),
    ).toThrow();
  });

  it("requires a cancellation reason", () => {
    expect(() =>
      cancelBookingSchema.parse({
        mutationId: uuid,
        expectedVersion: 1,
        reason: "",
        category: "other",
      }),
    ).toThrow();
  });

  it("coerces booking query pagination", () => {
    expect(
      bookingQuerySchema.parse({ limit: "25", offset: "5" }),
    ).toMatchObject({ limit: 25, offset: 5, upcoming: true });
  });
});
