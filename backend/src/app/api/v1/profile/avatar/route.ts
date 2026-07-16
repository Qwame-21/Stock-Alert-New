import { z } from "zod";

import { withAuth } from "@/lib/auth/with-auth";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { readJsonBody } from "@/lib/http/json-body";

const avatarSchema = z.object({
  contentBase64: z.string().min(1).max(4_000_000),
  extension: z.enum(["jpg", "jpeg", "png", "webp"]),
});

export const POST = withAuth(async (request, { requestId, user }) => {
  const input = avatarSchema.parse(await readJsonBody(request, 4_500_000));
  const storage = getSupabaseAdmin().storage;
  const { data: buckets } = await storage.listBuckets();
  if (!buckets?.some((bucket) => bucket.id === "avatars")) {
    const { error } = await storage.createBucket("avatars", { public: true });
    if (error && !error.message.toLowerCase().includes("already exists")) {
      throw new HttpError(502, "AVATAR_UPLOAD_FAILED", "Avatar storage is unavailable.");
    }
  }
  const path = `${user.id}/profile.${input.extension}`;
  const { error } = await storage.from("avatars").upload(
    path,
    Buffer.from(input.contentBase64, "base64"),
    { upsert: true, contentType: `image/${input.extension === "jpg" ? "jpeg" : input.extension}` },
  );
  if (error) {
    throw new HttpError(502, "AVATAR_UPLOAD_FAILED", "The profile image could not be uploaded.");
  }
  const { data } = storage.from("avatars").getPublicUrl(path);
  return apiSuccess({ url: `${data.publicUrl}?v=${Date.now()}` }, undefined, { requestId });
});
