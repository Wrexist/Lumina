import Fastify, { type FastifyInstance } from "fastify";
import { loadConfig, type Config } from "./config.ts";
import { createRateLimiter } from "./lib/rateLimit.ts";
import { chartRoutes } from "./routes/chart.ts";
import { transitsRoutes } from "./routes/transits.ts";
import { synastryRoutes } from "./routes/synastry.ts";
import { compositeRoutes } from "./routes/composite.ts";
import { forecastRoutes } from "./routes/forecast.ts";
import { moonRoutes } from "./routes/moon.ts";
import { progressionsRoutes } from "./routes/progressions.ts";
import { retrogradesRoutes } from "./routes/retrogrades.ts";
import { returnsRoutes } from "./routes/returns.ts";
import { AstronomyEngineEphemeris } from "./services/astronomyEngineEphemeris.ts";

export async function buildServer(config: Config): Promise<FastifyInstance> {
  const app = Fastify({
    logger: {
      level: config.LOG_LEVEL,
      transport:
        config.NODE_ENV === "development"
          ? { target: "pino-pretty", options: { translateTime: "HH:MM:ss.l", ignore: "pid,hostname" } }
          : undefined,
    },
  });

  // Baseline security headers (helmet-lite — no extra dependency).
  app.addHook("onSend", async (_request, reply, payload) => {
    reply.header("x-content-type-options", "nosniff");
    reply.header("x-frame-options", "DENY");
    reply.header("referrer-policy", "no-referrer");
    reply.header("cross-origin-resource-policy", "same-origin");
    return payload;
  });

  // Fixed-window per-IP rate limit. `/health` is exempt so probes never trip it.
  const rateLimit = createRateLimiter({ max: config.RATE_LIMIT_MAX, windowMs: config.RATE_LIMIT_WINDOW_MS });
  app.addHook("onRequest", async (request, reply) => {
    if (request.url === "/health") return;
    const result = rateLimit(request.ip);
    if (!result.ok) {
      reply.header("retry-after", Math.ceil(result.retryAfterMs / 1000));
      reply.code(429);
      throw new Error("rate limit exceeded");
    }
  });

  app.get("/health", async () => ({ status: "ok" }));

  const ephemeris = new AstronomyEngineEphemeris();
  await app.register(chartRoutes, { ephemeris, config });
  await app.register(transitsRoutes, { ephemeris, config });
  await app.register(synastryRoutes, { ephemeris, config });
  await app.register(compositeRoutes, { ephemeris, config });
  await app.register(forecastRoutes, { ephemeris, config });
  await app.register(moonRoutes, { ephemeris, config });
  await app.register(progressionsRoutes, { ephemeris, config });
  await app.register(retrogradesRoutes, { ephemeris, config });
  await app.register(returnsRoutes, { ephemeris, config });

  return app;
}

async function main(): Promise<void> {
  const config = loadConfig();
  const app = await buildServer(config);
  try {
    await app.listen({ port: config.PORT, host: config.HOST });
    app.log.info(`Lumina ephemeris listening on http://${config.HOST}:${config.PORT}`);
  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  void main();
}
