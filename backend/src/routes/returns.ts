import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { ReturnsRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface ReturnsRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

const RETURNS_BODY_LIMIT = 8 * 1024;

export const returnsRoutes: FastifyPluginAsync<ReturnsRouteOptions> = async (
  app: FastifyInstance,
  opts: ReturnsRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  app.post("/returns", { bodyLimit: RETURNS_BODY_LIMIT }, async (request, reply) => {
    const parsed = ReturnsRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_returns_request",
        issues: parsed.error.issues,
      };
    }
    const { from, ...birthData } = parsed.data;
    return opts.ephemeris.returns(birthData, {
      from: from === undefined ? undefined : new Date(from),
    });
  });
};
