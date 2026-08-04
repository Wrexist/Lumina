import Fastify, { type FastifyError, type FastifyInstance } from "fastify";
import { loadConfig, type Config } from "./config.ts";
import { createRateLimiter } from "./lib/rateLimit.ts";
import { secretsMatch } from "./routes/secret.ts";
import { chartRoutes } from "./routes/chart.ts";
import { transitsRoutes } from "./routes/transits.ts";
import { synastryRoutes } from "./routes/synastry.ts";
import { compositeRoutes } from "./routes/composite.ts";
import { forecastRoutes } from "./routes/forecast.ts";
import { moonRoutes } from "./routes/moon.ts";
import { progressionsRoutes } from "./routes/progressions.ts";
import { retrogradesRoutes } from "./routes/retrogrades.ts";
import { returnsRoutes } from "./routes/returns.ts";
import { interpretRoutes } from "./routes/interpret.ts";
import { AstronomyEngineEphemeris } from "./services/astronomyEngineEphemeris.ts";

export async function buildServer(config: Config): Promise<FastifyInstance> {
  const app = Fastify({
    // Fly terminates TLS and proxies to us, so without this every request
    // reports the proxy's address and the whole user base shares one
    // rate-limit bucket. `Fly-Client-IP` is set by Fly and strips any
    // client-supplied value, so it's the trustworthy source here.
    trustProxy: true,
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

  // Fixed-window per-client rate limit. `/health` is exempt so probes never
  // trip it.
  //
  // Auth is checked FIRST and unauthenticated requests are rejected without
  // consuming budget. Previously this hook ran before the plugin-scoped
  // `requireSharedSecret`, so anyone who knew the hostname could burn the
  // window with 401s and lock out every real user. The per-route hook stays
  // as defence in depth.
  const rateLimit = createRateLimiter({ max: config.RATE_LIMIT_MAX, windowMs: config.RATE_LIMIT_WINDOW_MS });
  app.addHook("onRequest", async (request, reply) => {
    if (request.url === "/health") return;

    const provided = request.headers["x-lumina-secret"];
    if (typeof provided !== "string" || !secretsMatch(provided, config.LUMINA_API_SECRET)) {
      reply.code(401);
      throw new Error("invalid or missing X-Lumina-Secret header");
    }

    const forwarded = request.headers["fly-client-ip"];
    const key = (typeof forwarded === "string" && forwarded) || request.ip;
    const result = rateLimit(key);
    if (!result.ok) {
      reply.header("retry-after", Math.ceil(result.retryAfterMs / 1000));
      reply.code(429);
      throw new Error("rate limit exceeded");
    }
  });

  // Normalises every unexpected throw to the same `{ error, message }` shape
  // the routes already use, so a stray JS error can't leak its stack or an
  // internal message to the client.
  app.setErrorHandler((error: FastifyError, request, reply) => {
    const status = reply.statusCode >= 400 ? reply.statusCode : (error.statusCode ?? 500);
    if (status >= 500) {
      request.log.error({ err: error }, "unhandled error");
    }
    reply.code(status).send({
      error: status >= 500 ? "internal_error" : "request_failed",
      message: status >= 500 ? "Something went wrong computing that." : error.message,
    });
  });

  const ephemeris = new AstronomyEngineEphemeris();

  // Liveness AND readiness: a machine that boots but can't compute is no use
  // in the pool. `moonPhase` needs no input and exercises the real ephemeris,
  // so a broken install fails the check instead of serving errors.
  app.get("/health", async (_request, reply) => {
    try {
      await ephemeris.moonPhase(new Date());
      return { status: "ok" };
    } catch (error) {
      reply.code(503);
      return { status: "degraded", error: (error as Error).message };
    }
  });

  await app.register(chartRoutes, { ephemeris, config });
  await app.register(transitsRoutes, { ephemeris, config });
  await app.register(synastryRoutes, { ephemeris, config });
  await app.register(compositeRoutes, { ephemeris, config });
  await app.register(forecastRoutes, { ephemeris, config });
  await app.register(moonRoutes, { ephemeris, config });
  await app.register(progressionsRoutes, { ephemeris, config });
  await app.register(retrogradesRoutes, { ephemeris, config });
  await app.register(returnsRoutes, { ephemeris, config });
  await app.register(interpretRoutes, { config });

  return app;
}

async function main(): Promise<void> {
  const config = loadConfig();
  const app = await buildServer(config);

  // Fly sends SIGTERM on every deploy and on autostop. Without this, Node's
  // default handler exits immediately and drops in-flight /forecast and
  // /interpret work mid-response.
  let shuttingDown = false;
  for (const signal of ["SIGTERM", "SIGINT"] as const) {
    process.on(signal, () => {
      if (shuttingDown) return;
      shuttingDown = true;
      app.log.info(`${signal} received — draining in-flight requests`);
      app
        .close()
        .then(() => process.exit(0))
        .catch((error) => {
          app.log.error({ err: error }, "error during shutdown");
          process.exit(1);
        });
    });
  }

  // A rejected promise with no handler would otherwise take the process down
  // silently. Log it and keep serving; the error handler covers request-scoped
  // failures.
  process.on("unhandledRejection", (reason) => {
    app.log.error({ err: reason }, "unhandled promise rejection");
  });
  process.on("uncaughtException", (error) => {
    app.log.fatal({ err: error }, "uncaught exception — exiting");
    process.exit(1);
  });

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
