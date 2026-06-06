import type {
  BirthData,
  CompositeResult,
  ForecastResult,
  HouseSystem,
  MoonPhaseResult,
  NatalChart,
  ProgressionsResult,
  RetrogradesResult,
  ReturnsResult,
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
  /** Secondary-progressed chart for a target date (day-for-a-year). */
  progressions(birthData: BirthData, options?: ProgressionsOptions): Promise<ProgressionsResult>;
  /** Which bodies are retrograde now and when each next stations (global). */
  retrogrades(at?: Date): Promise<RetrogradesResult>;
  /** Upcoming Jupiter and Saturn returns to the natal chart. */
  returns(birthData: BirthData, options?: ReturnsOptions): Promise<ReturnsResult>;
}

export interface ReturnsOptions {
  /** Window start; defaults to now. */
  readonly from?: Date;
}

export interface ProgressionsOptions {
  /** The target date to progress to; defaults to now. */
  readonly on?: Date;
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
