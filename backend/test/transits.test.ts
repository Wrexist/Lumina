import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";

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
  test("rejects without auth", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      payload: { birthData: sampleBirthData },
    });
    expect(response.statusCode).toBe(401);
  });

  test("returns 10 transiting planets and an aspect array sorted by orb", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { birthData: sampleBirthData, atInstant: "2026-04-29T12:00:00Z" },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.transitingPlanets).toHaveLength(10);
    expect(body.transitInstant).toBe("2026-04-29T12:00:00.000Z");
    for (let i = 1; i < body.aspects.length; i += 1) {
      expect(body.aspects[i].orb).toBeGreaterThanOrEqual(body.aspects[i - 1].orb);
    }
  });

  test("each aspect names a transiting and a natal planet", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { birthData: sampleBirthData, atInstant: "2026-04-29T12:00:00Z" },
    });
    const aspect = response.json().aspects[0];
    if (aspect) {
      expect(typeof aspect.transitingPlanet).toBe("string");
      expect(typeof aspect.natalPlanet).toBe("string");
      expect(["conjunction", "sextile", "square", "trine", "opposition"]).toContain(aspect.type);
      expect(aspect.orb).toBeLessThanOrEqual(4);
    }
  });

  test("Saturn-on-natal-Saturn return shows up at the ~29-30 year mark", async () => {
    // For a 1990-06-15 native, Saturn return falls roughly mid-2019 to mid-2020.
    // Saturn back in late Capricorn / Sagittarius near natal Saturn at ~24° Cap.
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { birthData: sampleBirthData, atInstant: "2020-01-15T12:00:00Z" },
    });
    expect(response.statusCode).toBe(200);
    const aspects = response.json().aspects as ReadonlyArray<{
      transitingPlanet: string;
      natalPlanet: string;
      type: string;
      orb: number;
    }>;
    const saturnReturn = aspects.find(
      (a) => a.transitingPlanet === "Saturn" && a.natalPlanet === "Saturn",
    );
    expect(saturnReturn).toBeDefined();
    expect(saturnReturn?.type).toBe("conjunction");
  });

  test("omitted atInstant defaults to roughly 'now'", async () => {
    const before = Date.now();
    const response = await app.inject({
      method: "POST",
      url: "/transits",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { birthData: sampleBirthData },
    });
    const after = Date.now();
    expect(response.statusCode).toBe(200);
    const computed = new Date(response.json().transitInstant).getTime();
    expect(computed).toBeGreaterThanOrEqual(before);
    expect(computed).toBeLessThanOrEqual(after);
  });
});
