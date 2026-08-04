/**
 * Transit forecasting: when do upcoming aspects become *exact*?
 *
 * Most apps only show which transits are in orb right now. The "timing"
 * promise — the day a transit perfects — needs root-finding over the
 * ephemeris. This module is the pure, ephemeris-agnostic core: given a
 * function that returns a body's ecliptic longitude at any instant, it finds
 * every time that longitude crosses a target degree within a window.
 *
 * Pure and unit-testable with a synthetic `longitudeAt`; the service supplies
 * the real `astronomy-engine`-backed sampler.
 */
const FULL_CIRCLE = 360;
const HALF_CIRCLE = 180;

/** Signed angular difference a − b, normalised to (−180, 180]. */
export function signedDelta(a: number, b: number): number {
  let delta = ((a - b) % FULL_CIRCLE + FULL_CIRCLE) % FULL_CIRCLE;
  if (delta > HALF_CIRCLE) delta -= FULL_CIRCLE;
  return delta;
}

/**
 * Epoch-ms timestamps in `[startMs, startMs + days·24h]` where `longitudeAt`
 * crosses `targetLon`. Steps every `stepHours`, detects sign changes of the
 * signed delta (ignoring the ±180° anti-target wrap), and bisects each
 * bracket to ~minute precision. Handles retrograde re-crossings naturally.
 */
export function findCrossings(
  longitudeAt: (t: number) => number,
  targetLon: number,
  startMs: number,
  days: number,
  stepHours = 12,
): number[] {
  const stepMs = stepHours * 3_600_000;
  const endMs = startMs + days * 86_400_000;
  const crossings: number[] = [];

  let prevDelta = signedDelta(longitudeAt(startMs), targetLon);
  for (let t = startMs + stepMs; t <= endMs; t += stepMs) {
    const delta = signedDelta(longitudeAt(t), targetLon);
    if (delta === 0) {
      // Sample landed exactly on the target — that instant is the crossing.
      crossings.push(t);
    } else if (prevDelta !== 0
      && Math.sign(delta) !== Math.sign(prevDelta)
      && Math.abs(delta - prevDelta) < HALF_CIRCLE) {
      crossings.push(bisect(longitudeAt, targetLon, t - stepMs, t));
    }
    prevDelta = delta;
  }
  return crossings;
}

/**
 * The first crossing only, stopping the scan as soon as it's found.
 *
 * `findCrossings` always walks the entire window. `/returns` searches a
 * Saturn period plus a margin — 11,159 days at a 48-hour step, so ~5,580
 * `astronomy-engine` evaluations — and then used `crossings[0]` and discarded
 * the rest. A return that falls early in the window now costs proportionally
 * little instead of always costing the full scan.
 */
export function findFirstCrossing(
  longitudeAt: (t: number) => number,
  targetLon: number,
  startMs: number,
  days: number,
  stepHours = 12,
): number | null {
  const stepMs = stepHours * 3_600_000;
  const endMs = startMs + days * 86_400_000;

  let prevDelta = signedDelta(longitudeAt(startMs), targetLon);
  for (let t = startMs + stepMs; t <= endMs; t += stepMs) {
    const delta = signedDelta(longitudeAt(t), targetLon);
    if (delta === 0) return t;
    if (prevDelta !== 0
      && Math.sign(delta) !== Math.sign(prevDelta)
      && Math.abs(delta - prevDelta) < HALF_CIRCLE) {
      return bisect(longitudeAt, targetLon, t - stepMs, t);
    }
    prevDelta = delta;
  }
  return null;
}

function bisect(
  longitudeAt: (t: number) => number,
  targetLon: number,
  low: number,
  high: number,
): number {
  let lo = low;
  let hi = high;
  for (let i = 0; i < 40 && hi - lo > 60_000; i += 1) {
    const mid = (lo + hi) / 2;
    if (Math.sign(signedDelta(longitudeAt(mid), targetLon)) === Math.sign(signedDelta(longitudeAt(lo), targetLon))) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return Math.round((lo + hi) / 2);
}
