import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { angularVelocity, findNextStation } from "../src/lib/retrogrades.ts";

const DAY_MS = 86_400_000;

describe("angularVelocity (pure)", () => {
  test("is positive for prograde (increasing) motion", () => {
    const longitudeAt = (ms: number) => (ms / DAY_MS) * 1; // 1°/day
    expect(angularVelocity(longitudeAt, 10 * DAY_MS)).toBeGreaterThan(0);
  });

  test("is negative for retrograde (decreasing) motion", () => {
    const longitudeAt = (ms: number) => 100 - (ms / DAY_MS) * 1;
    expect(angularVelocity(longitudeAt, 10 * DAY_MS)).toBeLessThan(0);
  });
});

describe("findNextStation (pure)", () => {
  test("finds a direct→retrograde station and reports 'retrograde' after it", () => {
    const turn = 5 * DAY_MS;
    const velocityAt = (t: number) => turn - t; // + before turn, − after
    const station = findNextStation(velocityAt, 0, 30);
    expect(station).not.toBeNull();
    expect(Math.abs(station!.atMs - turn)).toBeLessThan(60_000);
    expect(station!.direction).toBe("retrograde");
  });

  test("finds a retrograde→direct station and reports 'direct' after it", () => {
    const turn = 8 * DAY_MS;
    const velocityAt = (t: number) => t - turn; // − before turn, + after
    expect(findNextStation(velocityAt, 0, 30)?.direction).toBe("direct");
  });

  test("returns null when motion never reverses in the window", () => {
    expect(findNextStation(() => 1, 0, 30)).toBeNull();
  });
});

const TEST_SECRET = "test-secret-at-least-sixteen-chars-long";

let app: FastifyInstance;

beforeAll(async () => {
  const config = loadConfig({
    LUMINA_API_SECRET: TEST_SECRET,
    PORT: "3001",
    HOST: "127.0.0.1",
    LOG_LEVEL: "silent",
    NODE_ENV: "test",
  } as NodeJS.ProcessEnv);
  app = await buildServer(config);
  await app.ready();
});

afterAll(async () => {
  await app?.close();
});

describe("POST /retrogrades", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({ method: "POST", url: "/retrogrades", payload: {} });
    expect(response.statusCode).toBe(401);
  });

  test("returns the eight non-luminary bodies with valid states", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/retrogrades",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: {},
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.planets).toHaveLength(8);
    const names = body.planets.map((p: { planet: string }) => p.planet);
    expect(names).not.toContain("Sun");
    expect(names).not.toContain("Moon");
    expect(names).toContain("Mercury");
    for (const planet of body.planets) {
      expect(typeof planet.isRetrograde).toBe("boolean");
      if (planet.nextStationAt !== null) {
        expect(Date.parse(planet.nextStationAt)).toBeGreaterThan(Date.parse(body.at));
        expect(["retrograde", "direct"]).toContain(planet.nextStationDirection);
      }
    }
    // Mercury stations every ~4 months, so a next station always exists.
    const mercury = body.planets.find((p: { planet: string }) => p.planet === "Mercury");
    expect(mercury.nextStationAt).not.toBeNull();
  });

  test("a currently-retrograde body reports an upcoming 'direct' station", async () => {
    // 2025-03-15 fell inside a Mercury retrograde (2025-03-15 → 2025-04-07).
    const response = await app.inject({
      method: "POST",
      url: "/retrogrades",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { at: "2025-03-20T00:00:00Z" },
    });
    expect(response.statusCode).toBe(200);
    const mercury = response
      .json()
      .planets.find((p: { planet: string }) => p.planet === "Mercury");
    expect(mercury.isRetrograde).toBe(true);
    expect(mercury.nextStationDirection).toBe("direct");
  });

  test("rejects a malformed instant", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/retrogrades",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { at: "not-a-date" },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_retrogrades_request");
  });
});
