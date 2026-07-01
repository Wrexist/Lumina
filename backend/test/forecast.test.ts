import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { findCrossings, signedDelta } from "../src/lib/forecast.ts";
import { AstronomyEngineEphemeris } from "../src/services/astronomyEngineEphemeris.ts";

const DAY = 86_400_000;

describe("findCrossings (pure)", () => {
  test("signedDelta normalises to (-180, 180]", () => {
    expect(signedDelta(10, 0)).toBe(10);
    expect(signedDelta(0, 10)).toBe(-10);
    expect(signedDelta(350, 10)).toBe(-20);
    expect(signedDelta(10, 350)).toBe(20);
  });

  test("finds a single forward crossing", () => {
    // 1°/day starting at 0°, crosses 10° at day 10.
    const lon = (t: number) => ((t / DAY) % 360 + 360) % 360;
    const crossings = findCrossings(lon, 10, 0, 30);
    expect(crossings).toHaveLength(1);
    expect(Math.abs(crossings[0]! - 10 * DAY)).toBeLessThan(DAY / 24);
  });

  test("detects a crossing over the 0°/360° wrap", () => {
    // 1°/day starting at 350°, wraps and crosses 5° around day 15.
    const lon = (t: number) => ((350 + t / DAY) % 360 + 360) % 360;
    const crossings = findCrossings(lon, 5, 0, 30);
    expect(crossings).toHaveLength(1);
    expect(Math.abs(crossings[0]! - 15 * DAY)).toBeLessThan(DAY / 24);
  });

  test("does not count passing the anti-target (180° away)", () => {
    // 1°/day from 170°, passes 180° (anti-target of 0°) but never reaches 0°.
    const lon = (t: number) => ((170 + t / DAY) % 360 + 360) % 360;
    expect(findCrossings(lon, 0, 0, 15)).toHaveLength(0);
  });

  test("returns nothing when the target is never reached", () => {
    const lon = (_t: number) => 42;
    expect(findCrossings(lon, 100, 0, 30)).toHaveLength(0);
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

describe("POST /forecast", () => {
  test("rejects without the shared secret", async () => {
    const response = await app.inject({ method: "POST", url: "/forecast", payload: sampleBirthData });
    expect(response.statusCode).toBe(401);
  });

  test("rejects malformed birth data", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/forecast",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { not: "valid" },
    });
    expect(response.statusCode).toBe(400);
  });

  test("returns upcoming exact transits, sorted and within the window", async () => {
    const from = "2026-06-03T00:00:00Z";
    const response = await app.inject({
      method: "POST",
      url: "/forecast",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...sampleBirthData, from, days: 30 },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.events.length).toBeGreaterThan(0); // the Moon alone aspects everything in 30 days

    const start = Date.parse(from);
    const end = start + 30 * DAY;
    let previous = start - 1;
    for (const event of body.events) {
      const at = Date.parse(event.exactAt);
      expect(at).toBeGreaterThanOrEqual(start);
      expect(at).toBeLessThanOrEqual(end);
      expect(at).toBeGreaterThanOrEqual(previous); // sorted
      previous = at;
      expect(["conjunction", "sextile", "square", "trine", "opposition"]).toContain(event.type);
    }
  });

  test("each forecast date is genuinely near-exact (orb ~0 there)", async () => {
    // Cross-check against the ephemeris directly: at the predicted instant the
    // transiting planet must sit on the aspect angle to the natal planet.
    const eph = new AstronomyEngineEphemeris();
    const { events } = await eph.forecast(sampleBirthData, {
      from: new Date("2026-06-03T00:00:00Z"),
      days: 20,
    });
    expect(events.length).toBeGreaterThan(0);
    const event = events[0]!;
    const transits = await eph.transits(sampleBirthData, { at: new Date(event.exactAt) });
    const match = transits.transits.find(
      (t) => t.transiting === event.transiting && t.natal === event.natal && t.type === event.type,
    );
    expect(match).toBeDefined();
    expect(match!.orb).toBeLessThan(0.2);
  });
});
