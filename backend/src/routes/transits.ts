import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { computeTransitAspects } from "../lib/transits.ts";
import { planetsAt } from "../services/astronomyEngineEphemeris.ts";
import type { EphemerisService } from "../services/ephemeris.ts";
import { TransitRequestSchema } from "../types.ts";

interface TransitsRouteOptions {
  ephemeris: EphemerisService;
}

export const transitsRoutes: FastifyPluginAsync<TransitsRouteOptions> = async (
  app: FastifyInstance,
  opts: TransitsRouteOptions,
) => {
  app.post("/transits", async (request, reply) => {
    const parsed = TransitRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      reply.code(400);
      return { error: "invalid_transit_request", issues: parsed.error.issues };
    }
    const natal = await opts.ephemeris.chart(parsed.data.birthData);
    const transitInstant = parsed.data.atInstant ? new Date(parsed.data.atInstant) : new Date();
    const transitingPlanets = planetsAt(transitInstant);
    const aspects = computeTransitAspects(natal.planets, transitingPlanets);
    return {
      calculatedAt: new Date().toISOString(),
      transitInstant: transitInstant.toISOString(),
      transitingPlanets,
      aspects,
    };
  });
};
