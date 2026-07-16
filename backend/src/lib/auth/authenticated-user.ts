export interface AuthenticatedUser {
  id: string;
  email: string | null;
  metadata: Record<string, unknown>;
}
