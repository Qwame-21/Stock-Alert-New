const requestIdPattern = /^[a-zA-Z0-9._:-]{1,128}$/;

export function getRequestId(request: Request): string {
  const supplied = request.headers.get("x-request-id");
  if (supplied && requestIdPattern.test(supplied)) {
    return supplied;
  }

  return crypto.randomUUID();
}
