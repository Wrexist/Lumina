import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { MOON_PHASE_NAMES, phaseName } from "../src/lib/moon.ts";

describe("phaseName (pure)", () => {
  test("maps the four cardinal angles to their phases", () => {
    expect(phaseName(0)).toBe("New Moon");
    expect(phaseName(90)).toBe("First Quarter");
    expect(phaseName(180)).toBe("Full Moon");
    expect(phaseName(270)).toBe("Last Quarter");
  });

  test("New Moon spans the 337.5–22.5° seam", () => {
    expect(phaseName(350)).toBe("New Moon");
    expect(phaseName(10)).toBe("New Moon");
    expect(phaseName(360)).toBe("New Moon");
  });

  test("maps the four intermediate bins", () => {
    expect(phaseName(45)).toBe("Waxing Crescent");
    expect(phaseName(135)).toBe("Waxing Gibbous");
    expect(phaseName(225)).toBe("Waning Gibbous");
    expect(phaseName(315)).toBe("Waning Crescent");
  });

  test("normalizes out-of-range and negative angles", () => {
    expect(phaseName(720)).toBe("New Moon");
    expect(phaseName(-90)).toBe("Last Quarter");
  });

  test("only ever returns a known phase name", () => {
    for (let angle = 0; angle < 360; angle += 7) {
      expect(MOON_PHASE_NAMES).toContain(phaseName(angle));
    }
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

describe("POST /moon", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({ method: "POST", url: "/moon", payload: {} });
    expect(response.statusCode).toBe(401);
  });

  test("returns a well-formed moon phase for an empty body (now)", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/moon",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: {},
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.angle).toBeGreaterThanOrEqual(0);
    expect(body.angle).toBeLessThan(360);
    expect(MOON_PHASE_NAMES).toContain(body.phase);
    expect(body.illumination).toBeGreaterThanOrEqual(0);
    expect(body.illumination).toBeLessThanOrEqual(1);
    expect(Date.parse(body.nextNewMoon)).toBeGreaterThan(Date.parse(body.at));
    expect(Date.parse(body.nextFullMoon)).toBeGreaterThan(Date.parse(body.at));
  });

  test("computes the phase for a specific instant — a known full moon", async () => {
    // 2025-01-13 ~22:27 UTC was a full moon (the Wolf Moon).
    const response = await app.inject({
      method: "POST",
      url: "/moon",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { at: "2025-01-13T22:27:00Z" },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.phase).toBe("Full Moon");
    expect(body.illumination).toBeGreaterThan(0.98);
  });

  test("rejects a malformed instant", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/moon",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { at: "not-a-date" },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_moon_request");
  });
});
