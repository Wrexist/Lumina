/**
 * Tiny dependency-free fixed-window rate limiter. Keyed on an arbitrary
 * string (the caller passes the client IP). Kept in-process — adequate for a
 * single-instance ephemeris service gated behind a shared secret; swap for a
 * Redis-backed limiter if the service is ever horizontally scaled.
 */

export interface RateLimitOptions {
  /** Max requests allowed per window. */
  readonly max: number;
  /** Window length in milliseconds. */
  readonly windowMs: number;
}

export interface RateLimitResult {
  readonly ok: boolean;
  /** Milliseconds until the window resets (0 when `ok`). */
  readonly retryAfterMs: number;
}

interface Bucket {
  count: number;
  resetAt: number;
}

const SWEEP_THRESHOLD = 10_000;

export function createRateLimiter(options: RateLimitOptions): (key: string, now?: number) => RateLimitResult {
  const buckets = new Map<string, Bucket>();

  return function check(key: string, now: number = Date.now()): RateLimitResult {
    if (buckets.size > SWEEP_THRESHOLD) {
      for (const [k, bucket] of buckets) {
        if (now >= bucket.resetAt) buckets.delete(k);
      }
    }

    const existing = buckets.get(key);
    if (existing === undefined || now >= existing.resetAt) {
      buckets.set(key, { count: 1, resetAt: now + options.windowMs });
      return { ok: true, retryAfterMs: 0 };
    }
    if (existing.count >= options.max) {
      return { ok: false, retryAfterMs: existing.resetAt - now };
    }
    existing.count += 1;
    return { ok: true, retryAfterMs: 0 };
  };
}
