import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { SynastryRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface SynastryRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** Two small person payloads — well under 1 KB. */
const SYNASTRY_BODY_LIMIT = 8 * 1024;

export const synastryRoutes: FastifyPluginAsync<SynastryRouteOptions> = async (
  app: FastifyInstance,
  opts: SynastryRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  app.post("/synastry", { bodyLimit: SYNASTRY_BODY_LIMIT }, async (request, reply) => {
    const parsed = SynastryRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_synastry_request",
        issues: parsed.error.issues,
      };
    }
    return opts.ephemeris.synastry(parsed.data.personA, parsed.data.personB);
  });
};
