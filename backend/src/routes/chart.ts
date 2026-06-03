import { timingSafeEqual } from "node:crypto";
import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { ChartRequestSchema } from "../types.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface ChartRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

/** A birth payload is well under 1 KB; cap the body to shrink the DoS surface. */
const CHART_BODY_LIMIT = 8 * 1024;

/** Constant-time string comparison to avoid leaking the secret via timing. */
function secretsMatch(provided: string, expected: string): boolean {
  const a = Buffer.from(provided, "utf8");
  const b = Buffer.from(expected, "utf8");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

export const chartRoutes: FastifyPluginAsync<ChartRouteOptions> = async (
  app: FastifyInstance,
  opts: ChartRouteOptions,
) => {
  app.addHook("onRequest", async (request, reply) => {
    const provided = request.headers["x-lumina-secret"];
    if (typeof provided !== "string" || !secretsMatch(provided, opts.config.LUMINA_API_SECRET)) {
      reply.code(401);
      throw new Error("invalid or missing X-Lumina-Secret header");
    }
  });

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
