import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { ChartRequestSchema } from "../types.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import type { Config } from "../config.ts";

interface ChartRouteOptions {
  ephemeris: EphemerisService;
  config: Config;
}

export const chartRoutes: FastifyPluginAsync<ChartRouteOptions> = async (
  app: FastifyInstance,
  opts: ChartRouteOptions,
) => {
  app.addHook("onRequest", async (request, reply) => {
    if (request.url === "/health") return;
    const provided = request.headers["x-lumina-secret"];
    if (typeof provided !== "string" || provided !== opts.config.LUMINA_API_SECRET) {
      reply.code(401);
      throw new Error("invalid or missing X-Lumina-Secret header");
    }
  });

  app.post("/chart", async (request, reply) => {
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
