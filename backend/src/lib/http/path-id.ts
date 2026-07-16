import { z } from "zod";

import { HttpError } from "@/lib/http/errors";

export function getPathUuid(request: Request, segmentFromEnd = 1): string {
  const segments = new URL(request.url).pathname.split("/").filter(Boolean);
  const value = segments.at(-segmentFromEnd);
  const result = z.uuid().safeParse(value);

  if (!result.success) {
    throw new HttpError(400, "INVALID_ID", "A valid UUID is required.");
  }

  return result.data;
}
