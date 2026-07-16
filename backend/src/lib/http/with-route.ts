import { handleRouteError } from "@/lib/http/errors";
import { getRequestId } from "@/lib/http/request-id";
import {
  logDevelopmentExchange,
  logger,
} from "@/lib/observability/logger";

export interface RouteContext {
  requestId: string;
}

type RouteHandler = (
  request: Request,
  context: RouteContext,
) => Promise<Response>;

export function withRoute(handler: RouteHandler) {
  return async function route(request: Request) {
    const requestId = getRequestId(request);
    const startedAt = performance.now();
    const requestForLogging =
      process.env.NODE_ENV === "development" ? request.clone() : request;

    try {
      const response = await handler(request, { requestId });
      logger.info("http_request", {
        requestId,
        method: request.method,
        path: new URL(request.url).pathname,
        status: response.status,
        durationMs: Math.round(performance.now() - startedAt),
      });
      await logDevelopmentExchange({
        request: requestForLogging,
        response,
        requestId,
        durationMs: Math.round(performance.now() - startedAt),
      });
      return response;
    } catch (error) {
      const response = handleRouteError(error, requestId);
      logger.warn("http_request", {
        requestId,
        method: request.method,
        path: new URL(request.url).pathname,
        status: response.status,
        durationMs: Math.round(performance.now() - startedAt),
      });
      await logDevelopmentExchange({
        request: requestForLogging,
        response,
        requestId,
        durationMs: Math.round(performance.now() - startedAt),
      });
      return response;
    }
  };
}
