import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { ProgressionsRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface ProgressionsRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

const PROGRESSIONS_BODY_LIMIT = 8 * 1024;

export const progressionsRoutes: FastifyPluginAsync<ProgressionsRouteOptions> = async (
  app: FastifyInstance,
  opts: ProgressionsRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  app.post("/progressions", { bodyLimit: PROGRESSIONS_BODY_LIMIT }, async (request, reply) => {
    const parsed = ProgressionsRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_progressions_request",
        issues: parsed.error.issues,
      };
    }
    const { on, ...birthData } = parsed.data;
    return opts.ephemeris.progressions(birthData, {
      on: on === undefined ? undefined : new Date(on),
    });
  });
};
