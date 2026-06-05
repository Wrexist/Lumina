import type {
  BirthData,
  CompositeResult,
  ForecastResult,
  HouseSystem,
  MoonPhaseResult,
  NatalChart,
  SynastryPerson,
  SynastryResult,
  TransitsResult,
} from "../types.ts";

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
  /** A↔B cross-aspects between two people's natal charts. */
  synastry(personA: SynastryPerson, personB: SynastryPerson): Promise<SynastryResult>;
  /** Upcoming exact transit moments to the natal chart over a window. */
  forecast(birthData: BirthData, options?: ForecastOptions): Promise<ForecastResult>;
  /** The composite (midpoint) chart of two people. */
  composite(personA: SynastryPerson, personB: SynastryPerson): Promise<CompositeResult>;
  /** Tonight's Moon — phase, illumination, next new/full (global sky data). */
  moonPhase(at?: Date): Promise<MoonPhaseResult>;
}

export interface ForecastOptions {
  /** Window start; defaults to now. */
  readonly from?: Date;
  /** Window length in days; defaults to 30. */
  readonly days?: number;
}

export interface ChartOptions {
  /** Defaults to `placidus` (tropical Placidus). */
  readonly houseSystem?: HouseSystem;
}

export interface TransitOptions {
  /** The moment to compute transiting positions for. Defaults to now. */
  readonly at?: Date;
}
