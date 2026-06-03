import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { TransitsRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface TransitsRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** Same shape/size as the chart payload — birth data plus an optional moment. */
const TRANSITS_BODY_LIMIT = 8 * 1024;

export const transitsRoutes: FastifyPluginAsync<TransitsRouteOptions> = async (
  app: FastifyInstance,
  opts: TransitsRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  app.post("/transits", { bodyLimit: TRANSITS_BODY_LIMIT }, async (request, reply) => {
    const parsed = TransitsRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_birth_data",
        issues: parsed.error.issues,
      };
    }
    const { at, ...birthData } = parsed.data;
    const result = await opts.ephemeris.transits(birthData, {
      at: at != null ? new Date(at) : undefined,
    });
    return result;
  });
};
