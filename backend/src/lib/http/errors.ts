import { ZodError } from "zod";

import { apiError } from "@/lib/http/api-response";

export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = "HttpError";
  }
}

export function handleRouteError(error: unknown, requestId?: string) {
  const meta = requestId ? { requestId } : {};

  if (error instanceof HttpError) {
    return apiError(
      error.status,
      {
        code: error.code,
        message: error.message,
        details: error.details,
      },
      meta,
    );
  }

  if (error instanceof ZodError) {
    return apiError(
      400,
      {
        code: "VALIDATION_ERROR",
        message: "The request was invalid.",
        details: error.flatten(),
      },
      meta,
    );
  }

  console.error("Unhandled route error", { requestId, error });
  return apiError(
    500,
    {
      code: "INTERNAL_ERROR",
      message: "An unexpected error occurred.",
    },
    meta,
  );
}
