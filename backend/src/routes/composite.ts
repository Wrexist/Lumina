import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { SynastryRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface CompositeRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** Two small person payloads — well under 1 KB. */
const COMPOSITE_BODY_LIMIT = 8 * 1024;

export const compositeRoutes: FastifyPluginAsync<CompositeRouteOptions> = async (
  app: FastifyInstance,
  opts: CompositeRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  // Reuses the synastry payload (the two people) — the composite differs only
  // in how the two charts are combined, not in what input it needs.
  app.post("/composite", { bodyLimit: COMPOSITE_BODY_LIMIT }, async (request, reply) => {
    const parsed = SynastryRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_composite_request",
        issues: parsed.error.issues,
      };
    }
    return opts.ephemeris.composite(parsed.data.personA, parsed.data.personB);
  });
};
