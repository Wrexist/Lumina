import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { ChartRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface ChartRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** A birth payload is well under 1 KB; cap the body to shrink the DoS surface. */
const CHART_BODY_LIMIT = 8 * 1024;

export const chartRoutes: FastifyPluginAsync<ChartRouteOptions> = async (
  app: FastifyInstance,
  opts: ChartRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  app.post("/chart", { bodyLimit: CHART_BODY_LIMIT }, async (request, reply) => {
    const parsed = ChartRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_birth_data",
        issues: parsed.error.issues,
      };
    }
    const { houseSystem, ...birthData } = parsed.data;
    const chart = await opts.ephemeris.chart(birthData, { houseSystem });
    return chart;
  });
};
