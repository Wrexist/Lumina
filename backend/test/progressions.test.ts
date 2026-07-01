import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { progressedInstant } from "../src/lib/progressions.ts";

const YEAR_MS = 365.2422 * 86_400_000;
const DAY_MS = 86_400_000;

describe("progressedInstant (pure)", () => {
  test("day-for-a-year: 30 years of life ≈ 30 days past birth", () => {
    const birth = Date.UTC(1990, 0, 1);
    const progressed = progressedInstant(birth, birth + 30 * YEAR_MS);
    expect(Math.abs(progressed - birth - 30 * DAY_MS)).toBeLessThan(1000);
  });

  test("nothing has progressed at the birth instant", () => {
    expect(progressedInstant(5_000, 5_000)).toBe(5_000);
  });

  test("is linear in elapsed time", () => {
    const birth = Date.UTC(2000, 5, 1);
    const oneYear = progressedInstant(birth, birth + YEAR_MS) - birth;
    const twoYears = progressedInstant(birth, birth + 2 * YEAR_MS) - birth;
    expect(twoYears / oneYear).toBeCloseTo(2, 6);
  });
});

const TEST_SECRET = "test-secret-at-least-sixteen-chars-long";

const birthData = {
  birthDate: "1990-06-15T00:00:00Z",
  birthTime: "1990-06-15T14:30:00+02:00",
  placeName: "Stockholm, Sweden",
  latitude: 59.33,
  longitude: 18.07,
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

describe("POST /progressions", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({ method: "POST", url: "/progressions", payload: birthData });
    expect(response.statusCode).toBe(401);
  });

  test("rejects a malformed request", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/progressions",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { birthDate: "not-a-date" },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_progressions_request");
  });

  test("progresses the chart ~one month past birth for a 30-year-old", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/progressions",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...birthData, on: "2020-06-15T00:00:00Z" },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.planets).toHaveLength(10);
    // 30 years → ~30 days after the June 15 birth → mid-July 1990.
    expect(body.progressedAt.startsWith("1990-07")).toBe(true);
  });

  test("age zero leaves the chart at the birth instant", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/progressions",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...birthData, on: birthData.birthTime },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(Math.abs(Date.parse(body.progressedAt) - Date.parse(birthData.birthTime))).toBeLessThan(1000);
  });
});
