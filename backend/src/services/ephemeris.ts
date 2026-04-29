import type { BirthData, HouseSystem, NatalChart } from "../types.ts";

/**
 * Pluggable ephemeris backend. The `astronomy-engine` implementation is
 * the dev/MVP choice (pure JS, no native deps, no license fees). Once the
 * Swiss Ephemeris Pro license clears, swap in a `swisseph`-based impl
 * without changing any callers.
 */
export interface EphemerisService {
  chart(birthData: BirthData, options?: ChartOptions): Promise<NatalChart>;
}

export interface ChartOptions {
  /** Defaults to `placidus` (tropical Placidus). */
  readonly houseSystem?: HouseSystem;
}
