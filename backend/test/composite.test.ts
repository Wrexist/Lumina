import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { computeComposite, midpointLongitude } from "../src/lib/composite.ts";
import type { PlanetPosition } from "../src/types.ts";

function planet(name: string, longitude: number, latitude = 0): PlanetPosition {
  return { planet: name, longitude, latitude, isRetrograde: false };
}

describe("midpointLongitude (pure)", () => {
  test("midpoint of identical longitudes is the longitude itself", () => {
    expect(midpointLongitude(0, 0)).toBeCloseTo(0, 10);
    expect(midpointLongitude(123.4, 123.4)).toBeCloseTo(123.4, 10);
  });

  test("midpoint of a small arc is the arithmetic mean", () => {
    expect(midpointLongitude(0, 60)).toBeCloseTo(30, 10);
    expect(midpointLongitude(100, 200)).toBeCloseTo(150, 10);
  });

  test("takes the SHORTER arc across the 0/360 seam — not the naive mean", () => {
    // 10° and 350° are 20° apart the short way; the midpoint is 0°, not 180°.
    expect(midpointLongitude(10, 350)).toBeCloseTo(0, 10);
    expect(midpointLongitude(350, 10)).toBeCloseTo(0, 10);
  });

  test("always returns a longitude in [0, 360)", () => {
    const pairs: [number, number][] = [
      [0, 0],
      [10, 350],
      [359, 1],
      [200, 5],
      [123.4, 321.9],
    ];
    for (const [a, b] of pairs) {
      const mid = midpointLongitude(a, b);
      expect(mid).toBeGreaterThanOrEqual(0);
      expect(mid).toBeLessThan(360);
    }
  });
});

describe("computeComposite (pure)", () => {
  test("pairs planets by name and midpoints each longitude", () => {
    const result = computeComposite(
      [planet("Sun", 10), planet("Moon", 100)],
      [planet("Sun", 350), planet("Moon", 140)],
    );
    expect(result).toHaveLength(2);
    expect(result[0]).toMatchObject({ planet: "Sun", isRetrograde: false });
    expect(result[0]!.longitude).toBeCloseTo(0, 10);
    expect(result[1]!.longitude).toBeCloseTo(120, 10);
  });

  test("only includes bodies present in both charts", () => {
    const result = computeComposite(
      [planet("Sun", 10), planet("Moon", 100)],
      [planet("Sun", 20), planet("Venus", 200)],
    );
    expect(result.map((p) => p.planet)).toEqual(["Sun"]);
  });

  test("averages latitude and never reports retrograde", () => {
    const result = computeComposite([planet("Mars", 0, 2)], [planet("Mars", 0, -4)]);
    expect(result[0]!.latitude).toBeCloseTo(-1, 10);
    expect(result[0]!.isRetrograde).toBe(false);
  });

  test("composite of a chart with itself sits on the natal longitudes", () => {
    const self = [planet("Sun", 42.5), planet("Moon", 311.2)];
    const result = computeComposite(self, self);
    expect(result[0]!.longitude).toBeCloseTo(42.5, 9);
    expect(result[1]!.longitude).toBeCloseTo(311.2, 9);
  });
});

const TEST_SECRET = "test-secret-at-least-sixteen-chars-long";

const personA = {
  birthDate: "1990-06-15T00:00:00Z",
  birthTime: "1990-06-15T14:30:00+02:00",
  timeZoneIdentifier: "Europe/Stockholm",
};

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

describe("POST /composite", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/composite",
      payload: { personA, personB: personA },
    });
    expect(response.statusCode).toBe(401);
  });

  test("rejects a malformed request", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/composite",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { personA },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_composite_request");
  });

  test("returns a merged chart: 10 planets plus aspects sorted by orb", async () => {
    const personB = {
      birthDate: "1992-07-12T00:00:00Z",
      birthTime: "1992-07-12T09:15:00+03:00",
      timeZoneIdentifier: "Europe/Athens",
    };
    const response = await app.inject({
      method: "POST",
      url: "/composite",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { personA, personB },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.planets).toHaveLength(10);
    for (const p of body.planets) {
      expect(typeof p.planet).toBe("string");
      expect(p.longitude).toBeGreaterThanOrEqual(0);
      expect(p.longitude).toBeLessThan(360);
      expect(p.isRetrograde).toBe(false);
    }
    let previousOrb = -1;
    for (const aspect of body.aspects) {
      expect(aspect.orb).toBeGreaterThanOrEqual(0);
      expect(aspect.orb).toBeGreaterThanOrEqual(previousOrb);
      previousOrb = aspect.orb;
    }
  });

  test("accepts a person with no birth time or zone (contacts-imported friend)", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/composite",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { personA, personB: { birthDate: "1988-03-21T00:00:00Z" } },
    });
    expect(response.statusCode).toBe(200);
    expect(response.json().planets).toHaveLength(10);
  });
});
