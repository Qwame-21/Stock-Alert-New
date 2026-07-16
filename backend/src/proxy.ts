import { NextResponse, type NextRequest } from "next/server";

function allowedOrigins() {
  return new Set(
    (process.env.API_ALLOWED_ORIGINS ?? "")
      .split(",")
      .map((origin) => origin.trim())
      .filter(Boolean),
  );
}

function isAllowed(origin: string) {
  if (allowedOrigins().has(origin)) {
    return true;
  }

  if (process.env.NODE_ENV !== "production") {
    try {
      const url = new URL(origin);
      return url.hostname === "localhost" || url.hostname === "127.0.0.1";
    } catch {
      return false;
    }
  }

  return false;
}

export function proxy(request: NextRequest) {
  const origin = request.headers.get("origin");
  if (!origin || !isAllowed(origin)) {
    return NextResponse.next();
  }

  const headers = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Allow-Headers":
      "Authorization, Content-Type, X-Request-ID",
    "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
    Vary: "Origin",
  };

  if (request.method === "OPTIONS") {
    return new NextResponse(null, { status: 204, headers });
  }

  const response = NextResponse.next();
  for (const [name, value] of Object.entries(headers)) {
    response.headers.set(name, value);
  }
  return response;
}

export const config = {
  matcher: "/api/:path*",
};
