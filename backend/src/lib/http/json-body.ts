import { HttpError } from "@/lib/http/errors";

export async function readJsonBody(
  request: Request,
  maxBytes = 1024 * 1024,
): Promise<unknown> {
  const contentLength = Number(request.headers.get("content-length") ?? 0);
  if (contentLength > maxBytes) {
    throw new HttpError(
      413,
      "PAYLOAD_TOO_LARGE",
      "The request body is too large.",
    );
  }

  try {
    const text = await request.text();
    if (new TextEncoder().encode(text).byteLength > maxBytes) {
      throw new HttpError(
        413,
        "PAYLOAD_TOO_LARGE",
        "The request body is too large.",
      );
    }
    return JSON.parse(text);
  } catch (error) {
    if (error instanceof HttpError) {
      throw error;
    }
    throw new HttpError(
      400,
      "INVALID_JSON",
      "The request body must contain valid JSON.",
    );
  }
}
