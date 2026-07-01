import { describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { createRateLimiter } from "../src/lib/rateLimit.ts";

const TEST_SECRET = "test-secret-at-least-sixteen-chars-long";

const sampleBirthData = {
  birthDate: "1990-06-15T00:00:00Z",
  birthTime: "1990-06-15T14:30:00+02:00",
  placeName: "Stockholm, Sweden",
  latitude: 59.3293,
  longitude: 18.0686,
  timeZoneIdentifier: "Europe/Stockholm",
};

function makeConfig(overrides: Record<string, string> = {}): Parameters<typeof buildServer>[0] {
  return loadConfig({
    LUMINA_API_SECRET: TEST_SECRET,
    PORT: "3001",
    HOST: "127.0.0.1",
    LOG_LEVEL: "silent",
    NODE_ENV: "test",
    ...overrides,
  } as NodeJS.ProcessEnv);
}

async function withServer(
  config: Parameters<typeof buildServer>[0],
  run: (app: FastifyInstance) => Promise<void>,
): Promise<void> {
  const app = await buildServer(config);
  await app.ready();
  try {
    await run(app);
  } finally {
    await app.close();
  }
}

describe("createRateLimiter", () => {
  test("allows up to max then blocks within the window", () => {
    const limiter = createRateLimiter({ max: 2, windowMs: 1000 });
    expect(limiter("a", 0).ok).toBe(true);
    expect(limiter("a", 10).ok).toBe(true);
    const blocked = limiter("a", 20);
    expect(blocked.ok).toBe(false);
    expect(blocked.retryAfterMs).toBe(980);
    // A different key is independent.
    expect(limiter("b", 20).ok).toBe(true);
    // After the window resets, the key is allowed again.
    expect(limiter("a", 1001).ok).toBe(true);
  });
});

describe("server security", () => {
  test("sets baseline security headers", async () => {
    await withServer(makeConfig(), async (app) => {
      const res = await app.inject({ method: "GET", url: "/health" });
      expect(res.statusCode).toBe(200);
      expect(res.headers["x-content-type-options"]).toBe("nosniff");
      expect(res.headers["x-frame-options"]).toBe("DENY");
      expect(res.headers["referrer-policy"]).toBe("no-referrer");
    });
  });

  test("rate-limits repeated /chart calls and exempts /health", async () => {
    await withServer(makeConfig({ RATE_LIMIT_MAX: "2" }), async (app) => {
      const post = () =>
        app.inject({
          method: "POST",
          url: "/chart",
          headers: { "x-lumina-secret": TEST_SECRET },
          payload: sampleBirthData,
        });
      expect((await post()).statusCode).toBe(200);
      expect((await post()).statusCode).toBe(200);
      const limited = await post();
      expect(limited.statusCode).toBe(429);
      expect(limited.headers["retry-after"]).toBeDefined();
      // Health stays available even after the limit is hit.
      expect((await app.inject({ method: "GET", url: "/health" })).statusCode).toBe(200);
    });
  });

  test("rejects an oversized body with 413", async () => {
    await withServer(makeConfig(), async (app) => {
      const res = await app.inject({
        method: "POST",
        url: "/chart",
        headers: { "x-lumina-secret": TEST_SECRET },
        payload: { ...sampleBirthData, placeName: "x".repeat(9000) },
      });
      expect(res.statusCode).toBe(413);
    });
  });

  test("rejects a wildly out-of-range birth year", async () => {
    await withServer(makeConfig(), async (app) => {
      const res = await app.inject({
        method: "POST",
        url: "/chart",
        headers: { "x-lumina-secret": TEST_SECRET },
        payload: { ...sampleBirthData, birthDate: "0500-06-15T00:00:00Z", birthTime: null },
      });
      expect(res.statusCode).toBe(400);
      expect(res.json().error).toBe("invalid_birth_data");
    });
  });
});
