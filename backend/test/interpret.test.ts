import { afterEach, describe, expect, test, vi } from "vitest";
import type { FastifyInstance } from "fastify";
import { buildServer } from "../src/server.ts";
import { loadConfig } from "../src/config.ts";
import { AnthropicError, buildUserMessage, interpret } from "../src/lib/interpret.ts";

const TEST_SECRET = "test-secret-at-least-sixteen-chars-long";

function makeConfig(overrides: Record<string, string> = {}): Parameters<typeof buildServer>[0] {
  return loadConfig({
    LUMINA_API_SECRET: TEST_SECRET,
    LOG_LEVEL: "silent",
    NODE_ENV: "test",
    ...overrides,
  } as NodeJS.ProcessEnv);
}

async function withServer(
  config: Parameters<typeof buildServer>[0],
  run: (app: FastifyInstance) => Promise<void>,
): Promise<void> {
  const app = await buildServer(config);
  await app.ready();
  try {
    await run(app);
  } finally {
    await app.close();
  }
}

function anthropicResponse(text: string): Response {
  return new Response(JSON.stringify({ content: [{ type: "text", text }] }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
}

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("buildUserMessage", () => {
  test("ask includes the facts and the question", () => {
    const msg = buildUserMessage({ kind: "ask", facts: "Sun in Gemini", question: "Am I stubborn?" });
    expect(msg).toContain("Sun in Gemini");
    expect(msg).toContain("Am I stubborn?");
  });

  test("ask falls back to a default question when none is given", () => {
    const msg = buildUserMessage({ kind: "ask", facts: "Sun in Gemini" });
    expect(msg).toContain("What stands out about my chart?");
  });

  test("daily frames the facts as today's transits", () => {
    const msg = buildUserMessage({ kind: "daily", facts: "Moon trine natal Venus" });
    expect(msg).toContain("today's real transits");
    expect(msg).toContain("Moon trine natal Venus");
  });
});

describe("interpret()", () => {
  const deps = { apiKey: "sk-test", model: "claude-sonnet-5", maxTokens: 256 };

  test("returns the completion text on success", async () => {
    const fetchImpl = vi.fn(
      async (..._args: Parameters<typeof fetch>) => anthropicResponse("  You lead with warmth.  "),
    );
    const text = await interpret({ kind: "ask", facts: "Sun in Leo" }, { ...deps, fetchImpl });
    expect(text).toBe("You lead with warmth.");
    // Auth + version headers must be present.
    const headers = fetchImpl.mock.calls[0]?.[1]?.headers as Record<string, string> | undefined;
    expect(headers?.["x-api-key"]).toBe("sk-test");
    expect(headers?.["anthropic-version"]).toBe("2023-06-01");
  });

  test("throws AnthropicError on a non-2xx response", async () => {
    const fetchImpl = vi.fn(async () => new Response("boom", { status: 500 }));
    await expect(interpret({ kind: "ask", facts: "x" }, { ...deps, fetchImpl })).rejects.toBeInstanceOf(
      AnthropicError,
    );
  });

  test("throws AnthropicError on an empty completion", async () => {
    const fetchImpl = vi.fn(async () => anthropicResponse("   "));
    await expect(interpret({ kind: "ask", facts: "x" }, { ...deps, fetchImpl })).rejects.toBeInstanceOf(
      AnthropicError,
    );
  });
});

describe("POST /interpret", () => {
  const validBody = { kind: "ask", facts: "Sun in Leo, Moon in Cancer", question: "What's my core?" };

  test("401 without the shared secret", async () => {
    await withServer(makeConfig({ ANTHROPIC_API_KEY: "sk-test" }), async (app) => {
      const res = await app.inject({ method: "POST", url: "/interpret", payload: validBody });
      expect(res.statusCode).toBe(401);
    });
  });

  test("400 on an invalid body", async () => {
    await withServer(makeConfig({ ANTHROPIC_API_KEY: "sk-test" }), async (app) => {
      const res = await app.inject({
        method: "POST",
        url: "/interpret",
        headers: { "x-lumina-secret": TEST_SECRET },
        payload: { facts: "" },
      });
      expect(res.statusCode).toBe(400);
    });
  });

  test("503 when the server has no Anthropic key", async () => {
    await withServer(makeConfig(), async (app) => {
      const res = await app.inject({
        method: "POST",
        url: "/interpret",
        headers: { "x-lumina-secret": TEST_SECRET },
        payload: validBody,
      });
      expect(res.statusCode).toBe(503);
      expect(res.json().error).toBe("ai_not_configured");
    });
  });

  test("200 with the completion text when configured", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => anthropicResponse("Your Leo Sun leads with warmth.")));
    await withServer(makeConfig({ ANTHROPIC_API_KEY: "sk-test" }), async (app) => {
      const res = await app.inject({
        method: "POST",
        url: "/interpret",
        headers: { "x-lumina-secret": TEST_SECRET },
        payload: validBody,
      });
      expect(res.statusCode).toBe(200);
      expect(res.json().text).toBe("Your Leo Sun leads with warmth.");
    });
  });

  test("502 when the upstream call fails", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => new Response("nope", { status: 500 })));
    await withServer(makeConfig({ ANTHROPIC_API_KEY: "sk-test" }), async (app) => {
      const res = await app.inject({
        method: "POST",
        url: "/interpret",
        headers: { "x-lumina-secret": TEST_SECRET },
        payload: validBody,
      });
      expect(res.statusCode).toBe(502);
      expect(res.json().error).toBe("ai_upstream_error");
    });
  });
});
