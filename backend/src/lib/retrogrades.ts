/**
 * Retrograde motion and stations: is a planet apparently moving backward, and
 * when does it next turn? Pure and ephemeris-agnostic — given a longitude
 * sampler it derives apparent angular velocity and root-finds the stations
 * (where velocity crosses zero). The service supplies the real
 * `astronomy-engine`-backed sampler.
 */
import { signedDelta } from "./forecast.ts";

const HOUR_MS = 3_600_000;
const DAY_MS = 86_400_000;
const STATION_PROBE_MS = 6 * HOUR_MS;
const BISECT_FLOOR_MS = 60_000;
const BISECT_ITERATIONS = 40;

export type StationDirection = "retrograde" | "direct";

export interface Station {
  readonly atMs: number;
  /** The direction of motion *after* the station. */
  readonly direction: StationDirection;
}

/**
 * Signed apparent motion at `tMs`, in degrees across a ±probe window. Positive
 * is direct (prograde), negative is retrograde.
 */
export function angularVelocity(
  longitudeAt: (ms: number) => number,
  tMs: number,
  probeMs = STATION_PROBE_MS,
): number {
  return signedDelta(longitudeAt(tMs + probeMs), longitudeAt(tMs - probeMs));
}

/**
 * The next station — the instant apparent motion reverses — at or after
 * `startMs` within `days`. Scans `velocityAt` for a sign change, then bisects
 * to ~minute precision. Returns null if the body keeps one direction for the
 * whole window.
 */
export function findNextStation(
  velocityAt: (ms: number) => number,
  startMs: number,
  days: number,
  stepHours = 12,
): Station | null {
  const stepMs = stepHours * HOUR_MS;
  const endMs = startMs + days * DAY_MS;
  let prevVelocity = velocityAt(startMs);
  for (let t = startMs + stepMs; t <= endMs; t += stepMs) {
    const velocity = velocityAt(t);
    if (velocity === 0 && prevVelocity !== 0) {
      // Sample landed exactly on the station; direction is the reverse of the
      // motion leading in.
      return { atMs: t, direction: prevVelocity < 0 ? "direct" : "retrograde" };
    }
    if (velocity !== 0 && prevVelocity !== 0 && Math.sign(velocity) !== Math.sign(prevVelocity)) {
      return {
        atMs: bisectStation(velocityAt, t - stepMs, t),
        direction: velocity < 0 ? "retrograde" : "direct",
      };
    }
    prevVelocity = velocity;
  }
  return null;
}

function bisectStation(velocityAt: (ms: number) => number, lowMs: number, highMs: number): number {
  let lo = lowMs;
  let hi = highMs;
  const loSign = Math.sign(velocityAt(lo));
  for (let i = 0; i < BISECT_ITERATIONS && hi - lo > BISECT_FLOOR_MS; i += 1) {
    const mid = (lo + hi) / 2;
    if (Math.sign(velocityAt(mid)) === loSign) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return Math.round((lo + hi) / 2);
}
