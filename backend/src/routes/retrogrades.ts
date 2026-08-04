import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { RetrogradesRequestSchema } from "../types.ts";
import { bucketedCache } from "../lib/skyCache.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface RetrogradesRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** Tiny payload — just an optional `at`. */
const RETROGRADES_BODY_LIMIT = 1024;

// The most expensive endpoint in the service: eight bodies, each root-finding
// its next station across 400 days. A retrograde flag flips a few dozen times
// a year and a station time doesn't move within an hour of recompute, so an
// hourly bucket is free precision-wise and turns the common "what's
// retrograde right now" request into one computation per hour, globally.
const RETROGRADES_BUCKET_MS = 60 * 60 * 1000;

export const retrogradesRoutes: FastifyPluginAsync<RetrogradesRouteOptions> = async (
  app: FastifyInstance,
  opts: RetrogradesRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  const retrogrades = bucketedCache(
    (at: Date) => opts.ephemeris.retrogrades(at),
    { bucketMs: RETROGRADES_BUCKET_MS },
  );

  // Global sky data (not per-user). An empty body means "right now".
  app.post("/retrogrades", { bodyLimit: RETROGRADES_BODY_LIMIT }, async (request, reply) => {
    const parsed = RetrogradesRequestSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_retrogrades_request",
        issues: parsed.error.issues,
      };
    }
    const at = parsed.data.at === undefined ? undefined : new Date(parsed.data.at);
    return retrogrades(at);
  });
};
