import type { BirthData, HouseSystem, NatalChart, TransitsResult } from "../types.ts";

/**
 * Pluggable ephemeris backend. The `astronomy-engine` implementation is
 * the dev/MVP choice (pure JS, no native deps, no license fees). Once the
 * Swiss Ephemeris Pro license clears, swap in a `swisseph`-based impl
 * without changing any callers.
 */
export interface EphemerisService {
  chart(birthData: BirthData, options?: ChartOptions): Promise<NatalChart>;
  /** Transit→natal aspects for a given moment (the current sky by default). */
  transits(birthData: BirthData, options?: TransitOptions): Promise<TransitsResult>;
}

export interface ChartOptions {
  /** Defaults to `placidus` (tropical Placidus). */
  readonly houseSystem?: HouseSystem;
}

export interface TransitOptions {
  /** The moment to compute transiting positions for. Defaults to now. */
  readonly at?: Date;
}
