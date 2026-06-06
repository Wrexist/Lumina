import { afterAll, beforeAll, describe, expect, test } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";

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

describe("POST /returns", () => {
  test("rejects requests without the shared secret", async () => {
    const response = await app.inject({ method: "POST", url: "/returns", payload: birthData });
    expect(response.statusCode).toBe(401);
  });

  test("rejects a malformed request", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/returns",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { birthDate: "not-a-date" },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe("invalid_returns_request");
  });

  test("returns the next Jupiter and Saturn returns, upcoming and numbered", async () => {
    const from = "2026-06-15T00:00:00Z";
    const response = await app.inject({
      method: "POST",
      url: "/returns",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...birthData, from },
    });
    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.events).toHaveLength(2);
    const planets = body.events.map((event: { planet: string }) => event.planet).sort();
    expect(planets).toEqual(["Jupiter", "Saturn"]);
    for (const event of body.events) {
      expect(Date.parse(event.exactAt)).toBeGreaterThan(Date.parse(from));
      expect(event.returnNumber).toBeGreaterThanOrEqual(1);
      expect(event.natalLongitude).toBeGreaterThanOrEqual(0);
      expect(event.natalLongitude).toBeLessThan(360);
    }
  });

  test("the Saturn return for a 1990 birth (queried 2026) is the second", async () => {
    // First Saturn return ~2019–2020; the next is the second, ~2048–2049.
    const response = await app.inject({
      method: "POST",
      url: "/returns",
      headers: { "x-lumina-secret": TEST_SECRET },
      payload: { ...birthData, from: "2026-06-15T00:00:00Z" },
    });
    const saturn = response
      .json()
      .events.find((event: { planet: string }) => event.planet === "Saturn");
    expect(saturn.returnNumber).toBe(2);
    expect(saturn.exactAt.startsWith("204")).toBe(true);
  });
});
