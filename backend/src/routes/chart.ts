import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { ChartRequestSchema } from "../types.ts";
import type { EphemerisService } from "../services/ephemeris.ts";

interface ChartRouteOptions {
  ephemeris: EphemerisService;
}

export const chartRoutes: FastifyPluginAsync<ChartRouteOptions> = async (
  app: FastifyInstance,
  opts: ChartRouteOptions,
) => {
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
