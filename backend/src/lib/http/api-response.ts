import { NextResponse } from "next/server";

export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

interface ApiEnvelope<T> {
  data: T | null;
  error: ApiError | null;
  meta: Record<string, unknown>;
}

function responseInit(init: ResponseInit | undefined, requestId?: string) {
  const headers = new Headers(init?.headers);
  if (requestId) {
    headers.set("x-request-id", requestId);
  }

  return {
    ...init,
    headers,
  };
}

export function apiSuccess<T>(
  data: T,
  init?: ResponseInit,
  meta: Record<string, unknown> = {},
) {
  const body: ApiEnvelope<T> = {
    data,
    error: null,
    meta,
  };

  const requestId =
    typeof meta.requestId === "string" ? meta.requestId : undefined;
  return NextResponse.json(body, responseInit(init, requestId));
}

export function apiError(
  status: number,
  error: ApiError,
  meta: Record<string, unknown> = {},
) {
  const body: ApiEnvelope<never> = {
    data: null,
    error,
    meta,
  };

  const requestId =
    typeof meta.requestId === "string" ? meta.requestId : undefined;
  return NextResponse.json(body, responseInit({ status }, requestId));
}
