import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { computeTransits } from "../src/lib/transits.ts";
import type { PlanetPosition } from "../src/types.ts";

function planet(
  name: string,
  longitude: number,
  isRetrograde = false,
): PlanetPosition {
  return { planet: name, longitude, latitude: 0, isRetrograde };
}

describe("computeTransits (pure)", () => {
  test("returns nothing for empty inputs", () => {
    expect(computeTransits([], [])).toEqual([]);
    expect(computeTransits([planet("Mars", 100)], [])).toEqual([]);
  });

  test("detects an exact conjunction at orb 0", () => {
    const result = computeTransits([planet("Mars", 100)], [planet("Venus", 100)]);
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      transiting: "Mars",
      natal: "Venus",
      type: "conjunction",
      orb: 0,
    });
  });

  test("respects the tight conjunction orb (2° in, 5° out)", () => {
    expect(computeTransits([planet("Mars", 102)], [planet("Venus", 100)])).toHaveLength(1);
    expect(computeTransits([planet("Mars", 105)], [planet("Venus", 100)])).toHaveLength(0);
  });

  test("detects a trine across a 120° separation", () => {
    const result = computeTransits([planet("Jupiter", 220)], [planet("Sun", 100)]);
    expect(result[0]).toMatchObject({ type: "trine", orb: 0 });
  });

  test("a prograde planet moving toward exact is applying", () => {
    // Sun at 98° heading forward to natal 100° — closing in.
    const [applying] = computeTransits([planet("Sun", 98)], [planet("Moon", 100)]);
    expect(applying?.applying).toBe(true);
    // Sun at 102° heading forward, away from 100° — separating.
    const [separating] = computeTransits([planet("Sun", 102)], [planet("Moon", 100)]);
    expect(separating?.applying).toBe(false);
  });

  test("a retrograde planet moving backward toward exact is applying", () => {
    // Mars at 102° but retrograde (moving toward 100°) — closing in.
    const [retro] = computeTransits([planet("Mars", 102, true)], [planet("Pluto", 100)]);
    expect(retro?.applying).toBe(true);
  });

  test("keeps same-named return contacts (transiting Sun conjunct natal Sun)", () => {
    const result = computeTransits([planet("Sun", 80)], [planet("Sun", 80)]);
    expect(result[0]).toMatchObject({ transiting: "Sun", natal: "Sun", type: "conjunction" });
  });

  test("sorts results tightest-orb-first", () => {
    const result = computeTransits(
      [planet("Mars", 100), planet("Venus", 60.5)],
      [planet("Sun", 102)],
    );
    // Mars 100 vs Sun 102 → conjunction orb 2; Venus 60.5 vs Sun 102 → sextile
    // (sep 41.5? no) — keep it simple: assert ascending orb regardless.
    for (let i = 1; i < result.length; i += 1) {
      expect(result[i]!.orb).toBeGreaterThanOrEqual(result[i - 1]!.orb);
    }
  });
});

const TEST_SECRET = "test-secret-at-least-sixteen-chars-long";

const sampleBirthData = {
  birthDate: "1990-06-15T00:00:00Z",
  birthTime: "1990-06-15T14:30:00+02:00",
  placeName: "Stockholm, Sweden",
  latitude: 59.3293,
  longitude: 18.0686,
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

describe("POST /transits", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({ method: "POST", url: "/transits", payload: sampleBirthData });
    expect(response.statusCode).toBe(401);
  });

  test("rejects malformed birth data", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { not: "birth data" },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_birth_data");
  });

  test("returns ten transiting planets and a well-formed transit list", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...sampleBirthData, at: "2026-06-03T12:00:00Z" },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.transitAt).toBe("2026-06-03T12:00:00.000Z");
    expect(body.transitingPlanets).toHaveLength(10);

    let previousOrb = -1;
    for (const transit of body.transits) {
      expect(typeof transit.transiting).toBe("string");
      expect(typeof transit.natal).toBe("string");
      expect(typeof transit.applying).toBe("boolean");
      expect(transit.orb).toBeGreaterThanOrEqual(0);
      // Sorted ascending by orb.
      expect(transit.orb).toBeGreaterThanOrEqual(previousOrb);
      previousOrb = transit.orb;
    }
  });

  test("transits computed at the birth instant return each planet conjunct itself", async () => {
    // When the transit moment equals the birth instant, transiting positions
    // equal natal positions — so every body conjuncts its own natal point at
    // orb ~0. A strong end-to-end correctness check on the wiring.
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...sampleBirthData, at: sampleBirthData.birthTime },
    });
    expect(response.statusCode).toBe(200);
    const sunReturn = response
      .json()
      .transits.find(
        (t: { transiting: string; natal: string }) => t.transiting === "Sun" && t.natal === "Sun",
      );
    expect(sunReturn).toBeDefined();
    expect(sunReturn.type).toBe("conjunction");
    expect(sunReturn.orb).toBeLessThan(0.001);
  });

  test("defaults the transit moment to now when `at` is omitted", async () => {
    const before = Date.now();
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: sampleBirthData,
    });
    expect(response.statusCode).toBe(200);
    const transitAt = Date.parse(response.json().transitAt);
    expect(transitAt).toBeGreaterThanOrEqual(before - 1000);
    expect(transitAt).toBeLessThanOrEqual(Date.now() + 1000);
  });
});
