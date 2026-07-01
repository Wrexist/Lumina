import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { ForecastRequestSchema } from "../types.ts";
import { requireSharedSecret } from "./secret.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface ForecastRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

const FORECAST_BODY_LIMIT = 8 * 1024;

export const forecastRoutes: FastifyPluginAsync<ForecastRouteOptions> = async (
  app: FastifyInstance,
  opts: ForecastRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  app.post("/forecast", { bodyLimit: FORECAST_BODY_LIMIT }, async (request, reply) => {
    const parsed = ForecastRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return {
        error: "invalid_birth_data",
        issues: parsed.error.issues,
      };
    }
    const { from, days, ...birthData } = parsed.data;
    return opts.ephemeris.forecast(birthData, {
      from: from != null ? new Date(from) : undefined,
      days,
    });
  });
};
