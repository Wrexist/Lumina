import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { MoonPhaseRequestSchema } from "../types.ts";
import { bucketedCache } from "../lib/skyCache.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface MoonRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** Tiny payload — just an optional `at`. */
const MOON_BODY_LIMIT = 1024;

// The phase angle moves ~0.5°/hour, so a 15-minute bucket costs at most
// ~0.12° of precision — well under what any UI renders — while collapsing
// every client's cold-launch request into one computation.
const MOON_BUCKET_MS = 15 * 60 * 1000;

export const moonRoutes: FastifyPluginAsync<MoonRouteOptions> = async (
  app: FastifyInstance,
  opts: MoonRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  const moonPhase = bucketedCache(
    (at: Date) => opts.ephemeris.moonPhase(at),
    { bucketMs: MOON_BUCKET_MS },
  );

  // Global sky data (not per-user). An empty body means "right now".
  app.post("/moon", { bodyLimit: MOON_BODY_LIMIT }, async (request, reply) => {
    const parsed = MoonPhaseRequestSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_moon_request",
        issues: parsed.error.issues,
      };
    }
    const at = parsed.data.at === undefined ? undefined : new Date(parsed.data.at);
    return moonPhase(at);
  });
};
