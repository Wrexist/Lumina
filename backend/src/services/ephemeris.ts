import type { BirthData, NatalChart } from "../types.ts";

/**
 * Pluggable ephemeris backend. The `astronomy-engine` implementation is
 * the dev/MVP choice (pure JS, no native deps, no license fees). Once the
 * Swiss Ephemeris Pro license clears, swap in a `swisseph`-based impl
 * without changing any callers.
 */
export interface EphemerisService {
  chart(birthData: BirthData): Promise<NatalChart>;
}
