import Fastify, { type FastifyInstance } from "fastify";
import { loadConfig, type Config } from "./config.ts";
import { chartRoutes } from "./routes/chart.ts";
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

  app.get("/health", async () => ({ status: "ok" }));

  const ephemeris = new AstronomyEngineEphemeris();
  await app.register(chartRoutes, { ephemeris, config });

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
