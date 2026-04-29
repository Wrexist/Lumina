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

describe("GET /health", () => {
  test("responds 200 ok without auth", async () => {
    const response = await app.inject({ method: "GET", url: "/health" });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ status: "ok" });
  });
});

describe("POST /chart", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/chart",
      payload: sampleBirthData,
    });
    expect(response.statusCode).toBe(401);
  });

  test("rejects malformed birth data", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/chart",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { not: "a chart" },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_birth_data");
  });

  test("returns ten planet positions in valid ranges", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/chart",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: sampleBirthData,
    });
    expect(response.statusCode).toBe(200);
    const chart = response.json();
    expect(chart.houseSystem).toBe("placidus");
    expect(chart.planets).toHaveLength(10);

    const names = chart.planets.map((p: { planet: string }) => p.planet);
    expect(names).toEqual([
      "Sun",
      "Moon",
      "Mercury",
      "Venus",
      "Mars",
      "Jupiter",
      "Saturn",
      "Uranus",
      "Neptune",
      "Pluto",
    ]);

    for (const planet of chart.planets) {
      expect(planet.longitude).toBeGreaterThanOrEqual(0);
      expect(planet.longitude).toBeLessThan(360);
      expect(planet.latitude).toBeGreaterThan(-90);
      expect(planet.latitude).toBeLessThan(90);
      expect(typeof planet.isRetrograde).toBe("boolean");
    }
  });

  test("Sun is in Gemini for a mid-June birth", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/chart",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: sampleBirthData,
    });
    const sun = response.json().planets.find((p: { planet: string }) => p.planet === "Sun");
    // Gemini is ecliptic 60° to 90° (Cancer starts at 90°). June 15 is
    // very late in Gemini → expect ~ 23-25° Gemini → 83°-85° absolute.
    expect(sun.longitude).toBeGreaterThan(60);
    expect(sun.longitude).toBeLessThan(95);
  });

  test("accepts a payload that omits birthTime (CLI / unknown-time path)", async () => {
    const { birthTime: _omit, ...payload } = sampleBirthData;
    const response = await app.inject({
      method: "POST",
      url: "/chart",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload,
    });
    expect(response.statusCode).toBe(200);
    const chart = response.json();
    expect(chart.planets).toHaveLength(10);
    // Without a birth time, houses are meaningless — backend returns null.
    expect(chart.houses).toBeNull();
  });

  test("accepts a payload with birthTime explicitly null (iOS path)", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/chart",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...sampleBirthData, birthTime: null },
    });
    expect(response.statusCode).toBe(200);
    const chart = response.json();
    expect(chart.planets).toHaveLength(10);
    expect(chart.houses).toBeNull();
  });

  test("returns Placidus houses when birthTime is provided", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/chart",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: sampleBirthData,
    });
    expect(response.statusCode).toBe(200);
    const chart = response.json();
    expect(chart.houses).not.toBeNull();
    expect(chart.houses.system).toBe("placidus");
    expect(chart.houses.cusps).toHaveLength(12);
    expect(chart.houses.cusps[0]).toBeCloseTo(chart.houses.ascendant, 6);
    expect(chart.houses.cusps[9]).toBeCloseTo(chart.houses.midheaven, 6);
  });
});
