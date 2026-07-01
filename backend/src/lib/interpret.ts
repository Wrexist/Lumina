// LLM interpretation — the ONE place the Anthropic key is used.
//
// Grounding contract: the model interprets only the chart/transit facts the app
// sends (real positions computed by the ephemeris). It must never invent
// placements. This is the first grounding layer; pgvector RAG over a curated
// corpus (Liz Greene, Steven Forrest, Robert Hand) layers on later — see
// CLAUDE.md "RAG-grounded LLM". The prompt already forbids ungrounded claims,
// so shipping this before RAG is safe, not raw-LLM.

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
const REQUEST_TIMEOUT_MS = 30_000;

export type InterpretKind = "ask" | "daily" | "placement";

export interface InterpretInput {
  kind: InterpretKind;
  /** Pre-formatted, already-grounded facts from the app's real chart. */
  facts: string;
  /** The user's question — only meaningful for `kind: "ask"`. */
  question?: string;
}

export interface InterpretDeps {
  apiKey: string;
  model: string;
  maxTokens: number;
  /** Injected in tests; defaults to global fetch. */
  fetchImpl?: typeof fetch;
}

/** Thrown when Anthropic returns a non-2xx or an unusable body. */
export class AnthropicError extends Error {
  constructor(
    public readonly status: number,
    public readonly body: string,
  ) {
    super(`anthropic error ${status}`);
    this.name = "AnthropicError";
  }
}

export const SYSTEM_PROMPT = [
  "You are Lumina, a warm, precise astrology guide with an editorial voice —",
  "think of a thoughtful friend who genuinely knows charts, not a mystic and",
  "not a generic-horoscope app.",
  "",
  "Hard rules:",
  "- Interpret ONLY the chart facts provided by the app. They are real positions",
  "  computed from an ephemeris.",
  "- NEVER invent or assert planetary positions, signs, houses, degrees, or",
  "  aspects that are not in the provided facts. If a fact isn't given, don't",
  "  claim it.",
  "- If the facts can't answer the question, say so plainly and suggest what the",
  "  user could add (for example, their birth time to unlock houses and rising).",
  "- No deterministic predictions and no medical, legal, or financial advice.",
  "- Keep it to 2–4 short, grounded paragraphs. Specific over sweeping. Never",
  "  filler.",
].join("\n");

/** Builds the user-turn content for a given interpretation request. */
export function buildUserMessage(input: InterpretInput): string {
  switch (input.kind) {
    case "ask":
      return [
        "Here are my real chart facts:",
        "",
        input.facts,
        "",
        `My question: ${input.question?.trim() || "What stands out about my chart?"}`,
      ].join("\n");
    case "daily":
      return [
        "Here are today's real transits to my chart:",
        "",
        input.facts,
        "",
        "Write my daily reading — what today's sky is actually touching in my chart.",
      ].join("\n");
    case "placement":
      return [
        "Here is a placement from my real chart:",
        "",
        input.facts,
        "",
        "Interpret just this placement for me.",
      ].join("\n");
  }
}

/** Calls Anthropic and returns the completion text. Throws `AnthropicError`. */
export async function interpret(input: InterpretInput, deps: InterpretDeps): Promise<string> {
  const fetchImpl = deps.fetchImpl ?? fetch;
  const response = await fetchImpl(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": deps.apiKey,
      "anthropic-version": ANTHROPIC_VERSION,
    },
    body: JSON.stringify({
      model: deps.model,
      max_tokens: deps.maxTokens,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: buildUserMessage(input) }],
    }),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });

  if (!response.ok) {
    const body = await response.text().catch(() => "");
    throw new AnthropicError(response.status, body.slice(0, 500));
  }

  const data = (await response.json()) as { content?: Array<{ type?: string; text?: string }> };
  const text = data.content?.find((block) => block.type === "text")?.text ?? data.content?.[0]?.text;
  if (typeof text !== "string" || text.trim().length === 0) {
    throw new AnthropicError(502, "empty completion");
  }
  return text.trim();
}
