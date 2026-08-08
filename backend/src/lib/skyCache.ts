/**
 * A tiny time-bucketed memo for the two endpoints whose answer depends on
 * nothing but the instant.
 *
 * `/moon` and `/retrogrades` take no birth data — every user asking "what's
 * the sky doing right now" gets the identical response, and every client asks
 * on every cold launch. `/retrogrades` in particular root-finds the next
 * station for eight bodies across a 400-day window, so it was the most
 * expensive thing the service computed *and* the most repeated.
 *
 * Rather than caching the response and lying about when it was computed, the
 * instant itself is snapped to a bucket and the result is computed *for that
 * bucketed instant*. The `at` a client gets back is therefore the instant the
 * numbers actually describe — a truthful answer to a slightly rounded
 * question, not a stale answer to the exact one.
 *
 * Bucket sizes are chosen against how fast the underlying quantity moves:
 * the Moon's phase angle drifts ~0.5°/hour, and a planet's retrograde flag
 * flips a few dozen times a year.
 */

/** Snap `ms` down to a multiple of `bucketMs`. */
export function bucketInstant(ms: number, bucketMs: number): number {
  return Math.floor(ms / bucketMs) * bucketMs;
}

export interface SkyCacheOptions {
  /** Bucket width in ms. Requests within one bucket share a result. */
  readonly bucketMs: number;
  /** Max distinct buckets retained. Oldest are evicted first. */
  readonly maxEntries?: number;
}

/**
 * Wraps `compute` so calls for instants inside the same bucket resolve to one
 * shared promise. Concurrent callers await the same in-flight computation
 * rather than each starting their own, and a rejection is never cached.
 */
export function bucketedCache<T>(
  compute: (at: Date) => Promise<T>,
  { bucketMs, maxEntries = 8 }: SkyCacheOptions,
): (at?: Date) => Promise<T> {
  const entries = new Map<number, Promise<T>>();

  return (at?: Date): Promise<T> => {
    const key = bucketInstant((at ?? new Date()).getTime(), bucketMs);
    const hit = entries.get(key);
    if (hit !== undefined) return hit;

    const pending = compute(new Date(key));
    entries.set(key, pending);
    // A failure must not be served to everyone else for the rest of the
    // bucket — drop it so the next caller retries for real.
    pending.catch(() => {
      if (entries.get(key) === pending) entries.delete(key);
    });

    // Insertion-ordered, so the first key is the oldest bucket.
    while (entries.size > maxEntries) {
      const oldest = entries.keys().next();
      if (oldest.done === true) break;
      entries.delete(oldest.value);
    }
    return pending;
  };
}
