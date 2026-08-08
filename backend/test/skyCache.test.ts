import { describe, expect, it } from "vitest";
import { bucketInstant, bucketedCache } from "../src/lib/skyCache.ts";

const MINUTE = 60_000;

describe("bucketInstant", () => {
  it("snaps down to the bucket boundary", () => {
    const bucket = 15 * MINUTE;
    const base = Date.UTC(2026, 7, 4, 13, 0, 0);
    expect(bucketInstant(base, bucket)).toBe(base);
    expect(bucketInstant(base + MINUTE, bucket)).toBe(base);
    expect(bucketInstant(base + 14 * MINUTE + 59_999, bucket)).toBe(base);
    expect(bucketInstant(base + 15 * MINUTE, bucket)).toBe(base + 15 * MINUTE);
  });

  it("snaps down, not toward zero, before the epoch", () => {
    const bucket = 15 * MINUTE;
    const before = Date.UTC(1969, 0, 1, 0, 7, 0);
    const snapped = bucketInstant(before, bucket);
    expect(snapped).toBeLessThanOrEqual(before);
    expect(before - snapped).toBeLessThan(bucket);
    // `Math.abs` because an exact negative multiple leaves `-0`, which
    // `toBe` distinguishes from `0`.
    expect(Math.abs(snapped % bucket)).toBe(0);
  });
});

describe("bucketedCache", () => {
  it("computes once per bucket and reuses the result", async () => {
    let calls = 0;
    const cached = bucketedCache(
      async (at: Date) => {
        calls += 1;
        return at.toISOString();
      },
      { bucketMs: 15 * MINUTE },
    );

    const base = new Date(Date.UTC(2026, 7, 4, 13, 0, 0));
    const first = await cached(base);
    const sameBucket = await cached(new Date(base.getTime() + 5 * MINUTE));
    expect(calls).toBe(1);
    expect(sameBucket).toBe(first);

    await cached(new Date(base.getTime() + 20 * MINUTE));
    expect(calls).toBe(2);
  });

  it("computes for the bucketed instant, so the answer matches the `at` it reports", async () => {
    // The point of bucketing rather than caching the response: what comes
    // back describes the instant it says it describes.
    const cached = bucketedCache(
      async (at: Date) => ({ at: at.toISOString() }),
      { bucketMs: 15 * MINUTE },
    );
    const base = Date.UTC(2026, 7, 4, 13, 0, 0);
    const result = await cached(new Date(base + 7 * MINUTE));
    expect(result.at).toBe(new Date(base).toISOString());
  });

  it("shares one in-flight computation between concurrent callers", async () => {
    let calls = 0;
    let release: (() => void) | undefined;
    const gate = new Promise<void>((resolve) => { release = resolve; });
    const cached = bucketedCache(
      async () => {
        calls += 1;
        await gate;
        return calls;
      },
      { bucketMs: 15 * MINUTE },
    );

    const at = new Date(Date.UTC(2026, 7, 4, 13, 0, 0));
    const both = Promise.all([cached(at), cached(at)]);
    release?.();
    const [a, b] = await both;
    expect(calls).toBe(1);
    expect(a).toBe(b);
  });

  it("does not cache a failure", async () => {
    let calls = 0;
    const cached = bucketedCache(
      async () => {
        calls += 1;
        if (calls === 1) throw new Error("transient");
        return "ok";
      },
      { bucketMs: 15 * MINUTE },
    );

    const at = new Date(Date.UTC(2026, 7, 4, 13, 0, 0));
    await expect(cached(at)).rejects.toThrow("transient");
    await expect(cached(at)).resolves.toBe("ok");
    expect(calls).toBe(2);
  });

  it("evicts the oldest buckets rather than growing without bound", async () => {
    let calls = 0;
    const cached = bucketedCache(
      async (at: Date) => {
        calls += 1;
        return at.toISOString();
      },
      { bucketMs: MINUTE, maxEntries: 2 },
    );

    const base = Date.UTC(2026, 7, 4, 13, 0, 0);
    await cached(new Date(base));
    await cached(new Date(base + MINUTE));
    await cached(new Date(base + 2 * MINUTE));
    expect(calls).toBe(3);

    // The first bucket was evicted, so it recomputes.
    await cached(new Date(base));
    expect(calls).toBe(4);
    // The most recent bucket is still resident.
    await cached(new Date(base + 2 * MINUTE));
    expect(calls).toBe(4);
  });
});
