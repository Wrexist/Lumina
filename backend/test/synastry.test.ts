import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { computeSynastry } from "../src/lib/synastry.ts";
import type { PlanetPosition } from "../src/types.ts";

function planet(name: string, longitude: number): PlanetPosition {
  return { planet: name, longitude, latitude: 0, isRetrograde: false };
}

describe("computeSynastry (pure)", () => {
  test("returns nothing for empty inputs", () => {
    expect(computeSynastry([], [])).toEqual([]);
    expect(computeSynastry([planet("Sun", 10)], [])).toEqual([]);
  });

  test("detects an exact conjunction across the two charts at orb 0", () => {
    const result = computeSynastry([planet("Sun", 100)], [planet("Venus", 100)]);
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      planetA: "Sun",
      planetB: "Venus",
      type: "conjunction",
      orb: 0,
    });
  });

  test("widens the orb when a luminary is involved", () => {
    // Sun (luminary) 9° from Mars → within the 10° luminary conjunction orb.
    expect(computeSynastry([planet("Sun", 109)], [planet("Mars", 100)])).toHaveLength(1);
    // Two non-luminaries 9° apart → outside the 8° base conjunction orb.
    expect(computeSynastry([planet("Mars", 109)], [planet("Venus", 100)])).toHaveLength(0);
  });

  test("detects a trine across a 120° separation", () => {
    const result = computeSynastry([planet("Mars", 220)], [planet("Saturn", 100)]);
    expect(result[0]).toMatchObject({ type: "trine", orb: 0 });
  });

  test("is symmetric — swapping the charts swaps planetA/planetB only", () => {
    const forward = computeSynastry([planet("Sun", 100)], [planet("Moon", 105)]);
    const reverse = computeSynastry([planet("Moon", 105)], [planet("Sun", 100)]);
    expect(forward[0]).toMatchObject({ planetA: "Sun", planetB: "Moon", type: "conjunction" });
    expect(reverse[0]).toMatchObject({ planetA: "Moon", planetB: "Sun", type: "conjunction" });
    expect(forward[0]!.orb).toBeCloseTo(reverse[0]!.orb, 10);
  });

  test("sorts results tightest-orb-first", () => {
    const result = computeSynastry(
      [planet("Sun", 100), planet("Mars", 152)],
      [planet("Moon", 105), planet("Venus", 90)],
    );
    for (let i = 1; i < result.length; i += 1) {
      expect(result[i]!.orb).toBeGreaterThanOrEqual(result[i - 1]!.orb);
    }
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

describe("POST /synastry", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/synastry",
      payload: { personA, personB: personA },
    });
    expect(response.statusCode).toBe(401);
  });

  test("rejects a malformed request", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/synastry",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { personA },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_synastry_request");
  });

  test("returns well-formed cross-aspects sorted by orb", async () => {
    const personB = {
      birthDate: "1992-07-12T00:00:00Z",
      birthTime: "1992-07-12T09:15:00+03:00",
      timeZoneIdentifier: "Europe/Athens",
    };
    const response = await app.inject({
      method: "POST",
      url: "/synastry",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { personA, personB },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    let previousOrb = -1;
    for (const aspect of body.aspects) {
      expect(typeof aspect.planetA).toBe("string");
      expect(typeof aspect.planetB).toBe("string");
      expect(aspect.orb).toBeGreaterThanOrEqual(0);
      expect(aspect.orb).toBeGreaterThanOrEqual(previousOrb);
      previousOrb = aspect.orb;
    }
  });

  test("accepts a person with no birth time or zone (contacts-imported friend)", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/synastry",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { personA, personB: { birthDate: "1988-03-21T00:00:00Z" } },
    });
    expect(response.statusCode).toBe(200);
    expect(Array.isArray(response.json().aspects)).toBe(true);
  });

  test("synastry of a person with themselves conjuncts every planet at orb ~0", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/synastry",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { personA, personB: personA },
    });
    expect(response.statusCode).toBe(200);
    const sunSun = response
      .json()
      .aspects.find(
        (a: { planetA: string; planetB: string }) => a.planetA === "Sun" && a.planetB === "Sun",
      );
    expect(sunSun).toBeDefined();
    expect(sunSun.type).toBe("conjunction");
    expect(sunSun.orb).toBeLessThan(0.001);
  });
});
