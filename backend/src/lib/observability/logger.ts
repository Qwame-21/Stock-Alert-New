interface LogFields {
  requestId?: string;
  [key: string]: unknown;
}

function write(level: "info" | "warn" | "error", event: string, fields: LogFields) {
  const entry = JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    event,
    ...fields,
  });

  if (level === "error") {
    console.error(entry);
  } else if (level === "warn") {
    console.warn(entry);
  } else {
    console.info(entry);
  }
}

export const logger = {
  info: (event: string, fields: LogFields = {}) => write("info", event, fields),
  warn: (event: string, fields: LogFields = {}) => write("warn", event, fields),
  error: (event: string, fields: LogFields = {}) =>
    write("error", event, fields),
};

const sensitiveKeys = new Set([
  "authorization",
  "password",
  "accessToken",
  "refreshToken",
  "token",
  "documentPath",
  "document_path",
  "knownAllergies",
  "known_allergies",
  "chronicConditions",
  "chronic_conditions",
  "currentMedication",
  "current_medication",
  "emergencyContactName",
  "emergencyContactPhone",
  "emergencyContactEmail",
]);

export function redactForLog(value: unknown): unknown {
  if (Array.isArray(value)) {
    return value.map(redactForLog);
  }
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => [
        key,
        sensitiveKeys.has(key) ? "[REDACTED]" : redactForLog(nested),
      ]),
    );
  }
  return value;
}

async function jsonPayload(message: Request | Response) {
  const contentType = message.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) {
    return undefined;
  }

  try {
    const text = await message.clone().text();
    if (!text) return undefined;
    if (text.length > 100_000) {
      return "[TRUNCATED]";
    }
    return redactForLog(JSON.parse(text));
  } catch {
    return "[UNREADABLE]";
  }
}

export async function logDevelopmentExchange(input: {
  request: Request;
  response: Response;
  requestId: string;
  durationMs: number;
}) {
  if (process.env.NODE_ENV !== "development") {
    return;
  }

  const [requestBody, responseBody] = await Promise.all([
    jsonPayload(input.request),
    jsonPayload(input.response),
  ]);

  logger.info("api_exchange", {
    requestId: input.requestId,
    method: input.request.method,
    path: new URL(input.request.url).pathname,
    query: Object.fromEntries(new URL(input.request.url).searchParams),
    status: input.response.status,
    durationMs: input.durationMs,
    requestBody,
    responseBody,
  });
}
