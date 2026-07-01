import type { FastifyInstance, FastifyPluginAsync } from "fastify";
import { z } from "zod";
import { requireSharedSecret } from "./secret.ts";
import { interpret } from "../lib/interpret.ts";
import type { Config } from "../config.ts";

interface InterpretRouteOptions {
  config: Config;
}

// Facts are pre-formatted by the app; cap them so a caller can't push a huge
// prompt (and cost) through. 6k chars comfortably fits a full chart summary.
const INTERPRET_BODY_LIMIT = 16_384;

const InterpretRequestSchema = z.object({
  kind: z.enum(["ask", "daily", "placement"]).default("ask"),
  facts: z.string().min(1).max(6000),
  question: z.string().min(1).max(500).optional(),
});

/**
 * `POST /interpret` — grounded LLM interpretation. Unlike the ephemeris routes
 * this holds no astronomy; it turns already-computed, real chart facts into
 * prose. Auth is the same shared secret. Returns 503 (not 500) when the server
 * has no Anthropic key, so the app can degrade gracefully to its deterministic
 * grounded answers.
 */
export const interpretRoutes: FastifyPluginAsync<InterpretRouteOptions> = async (
  app: FastifyInstance,
  opts: InterpretRouteOptions,
) => {
  requireSharedSecret(app, opts.config.LUMINA_API_SECRET);

  app.post("/interpret", { bodyLimit: INTERPRET_BODY_LIMIT }, async (request, reply) => {
    const parsed = InterpretRequestSchema.safeParse(request.body ?? {});
    if (!parsed.success) {
      reply.code(400);
      return { error: "invalid_interpret_request", issues: parsed.error.issues };
    }

    const apiKey = opts.config.ANTHROPIC_API_KEY;
    if (!apiKey) {
      reply.code(503);
      return {
        error: "ai_not_configured",
        message: "ANTHROPIC_API_KEY is not set on the server.",
      };
    }

    try {
      const text = await interpret(parsed.data, {
        apiKey,
        model: opts.config.ANTHROPIC_MODEL,
        maxTokens: opts.config.ANTHROPIC_MAX_TOKENS,
      });
      return { text };
    } catch (error) {
      request.log.error({ err: error }, "interpret failed");
      reply.code(502);
      return { error: "ai_upstream_error" };
    }
  });
};
