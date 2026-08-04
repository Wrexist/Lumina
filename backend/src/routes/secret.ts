import { timingSafeEqual } from "node:crypto";
import type { FastifyInstance } from "fastify";

/** Constant-time comparison so the shared secret can't be guessed via timing. */
export function secretsMatch(provided: string, expected: string): boolean {
  const a = Buffer.from(provided, "utf8");
  const b = Buffer.from(expected, "utf8");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

/**
 * Registers an `onRequest` hook (scoped to the calling plugin) that rejects
 * any request without a valid `X-Lumina-Secret` header. Shared by every
 * authenticated route so the constant-time check lives in exactly one place.
 */
export function requireSharedSecret(app: FastifyInstance, expected: string): void {
  app.addHook("onRequest", async (request, reply) => {
    const provided = request.headers["x-lumina-secret"];
    if (typeof provided !== "string" || !secretsMatch(provided, expected)) {
      reply.code(401);
      throw new Error("invalid or missing X-Lumina-Secret header");
    }
  });
}
