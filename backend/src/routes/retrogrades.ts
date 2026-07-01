import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { RetrogradesRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface RetrogradesRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** Tiny payload — just an optional `at`. */
const RETROGRADES_BODY_LIMIT = 1024;

export const retrogradesRoutes: FastifyPluginAsync<RetrogradesRouteOptions> = async (
  app: FastifyInstance,
  opts: RetrogradesRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

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
    return opts.ephemeris.retrogrades(at);
  });
};
