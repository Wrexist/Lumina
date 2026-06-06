import { z } from "zod";

// astronomy-engine is accurate roughly 1700-2200; bound inputs to a sane
// range so a typo'd year fails loudly instead of returning junk positions.
const MIN_BIRTH_MS = Date.UTC(1800, 0, 1);
const MAX_BIRTH_MS = Date.UTC(2200, 0, 1);

const plausibleInstant = z
  .string()
  .datetime({ offset: true })
  .refine(
    (s) => {
      const t = Date.parse(s);
      return Number.isFinite(t) && t >= MIN_BIRTH_MS && t <= MAX_BIRTH_MS;
    },
    { message: "must be a date between 1800 and 2200" },
  );

/**
 * Mirrors `Lumina/Core/Ephemeris/Models/BirthData.swift`.
 * The Swift `Date` fields are encoded as ISO-8601 strings on the wire.
 */
export const BirthDataSchema = z.object({
  birthDate: plausibleInstant,
  // The iOS encoder always emits this key (null when no birth time is
  // captured). Older clients and ad-hoc CLI callers may omit the key
  // entirely, so accept both via `.nullable().optional()`.
  birthTime: plausibleInstant.nullable().optional(),
  placeName: z.string().min(1).max(200),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  timeZoneIdentifier: z.string().min(1).max(64),
});

export type BirthData = z.infer<typeof BirthDataSchema>;

export const HouseSystemSchema = z.enum(["placidus", "wholeSign", "sidereal"]);
export type HouseSystem = z.infer<typeof HouseSystemSchema>;

/**
 * Wire format for `POST /chart`: birth data plus an optional house-system
 * choice. Defaults to `placidus`. The Swift iOS client encodes this as a
 * flat object — `BirthData` fields plus `houseSystem`.
 */
export const ChartRequestSchema = BirthDataSchema.extend({
  houseSystem: HouseSystemSchema.optional(),
});

export type ChartRequest = z.infer<typeof ChartRequestSchema>;

/** Mirrors `NatalChart.PlanetPosition` in Swift. */
export const PlanetPositionSchema = z.object({
  planet: z.string(),
  longitude: z.number(),
  latitude: z.number(),
  isRetrograde: z.boolean(),
});

export type PlanetPosition = z.infer<typeof PlanetPositionSchema>;

export const AspectTypeSchema = z.enum([
  "conjunction",
  "sextile",
  "square",
  "trine",
  "opposition",
]);

export type AspectType = z.infer<typeof AspectTypeSchema>;

/** Mirrors `NatalChart.Aspect` in Swift. */
export const AspectSchema = z.object({
  planet1: z.string(),
  planet2: z.string(),
  type: AspectTypeSchema,
  /** Exact aspect angle in degrees (0, 60, 90, 120, 180). */
  exactAngle: z.number(),
  /** Absolute deviation from the exact aspect angle, in degrees. */
  orb: z.number().nonnegative(),
});

export type Aspect = z.infer<typeof AspectSchema>;

/** Mirrors `NatalChart.HouseCusps` in Swift. */
export const HouseCuspsSchema = z.object({
  system: HouseSystemSchema,
  ascendant: z.number(),
  midheaven: z.number(),
  /** 12 cusps, index 0 == house 1 == ascendant. */
  cusps: z.array(z.number()).length(12),
});

export type HouseCusps = z.infer<typeof HouseCuspsSchema>;

export const NatalChartSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  houseSystem: HouseSystemSchema,
  planets: z.array(PlanetPositionSchema),
  /** Major aspects between natal planet pairs, sorted ascending by orb. */
  aspects: z.array(AspectSchema),
  /** Null when the birth time is unknown (chart is sun-noon). */
  houses: HouseCuspsSchema.nullable(),
});

export type NatalChart = z.infer<typeof NatalChartSchema>;

/**
 * A transiting (currently-moving) planet's aspect to a natal planet —
 * "transiting Mars trines your natal Venus". Mirrors `TransitReading` in
 * `Lumina/Core/Ephemeris/Models/NatalChart.swift`.
 */
export const TransitSchema = z.object({
  /** The currently-moving planet making the contact. */
  transiting: z.string(),
  /** The natal planet being contacted. */
  natal: z.string(),
  type: AspectTypeSchema,
  exactAngle: z.number(),
  orb: z.number().nonnegative(),
  /** True when the aspect is tightening toward exact, false when separating. */
  applying: z.boolean(),
});

export type Transit = z.infer<typeof TransitSchema>;

/**
 * Wire format for `POST /transits`: birth data plus an optional moment to
 * compute the sky for. The iOS client omits `at` to mean "right now".
 */
export const TransitsRequestSchema = BirthDataSchema.extend({
  at: plausibleInstant.optional(),
});

export type TransitsRequest = z.infer<typeof TransitsRequestSchema>;

export const TransitsResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  /** The moment the transiting positions were computed for. */
  transitAt: z.string().datetime({ offset: true }),
  /** Current geocentric positions of all ten bodies. */
  transitingPlanets: z.array(PlanetPositionSchema),
  /** Transit→natal aspects, sorted ascending by orb (tightest first). */
  transits: z.array(TransitSchema),
});

export type TransitsResult = z.infer<typeof TransitsResultSchema>;

/**
 * One cross-aspect between person A's planet and person B's planet —
 * the building block of a synastry (relationship) reading. Mirrors
 * `SynastryAspect` in `Lumina/Core/Ephemeris/Models/SynastryResult.swift`.
 */
export const SynastryAspectSchema = z.object({
  /** Person A's planet. */
  planetA: z.string(),
  /** Person B's planet. */
  planetB: z.string(),
  type: AspectTypeSchema,
  exactAngle: z.number(),
  orb: z.number().nonnegative(),
});

export type SynastryAspect = z.infer<typeof SynastryAspectSchema>;

/**
 * One person in a synastry request. Geocentric planet longitudes don't
 * depend on the birth *place*, so only the date (plus an optional time for
 * Moon precision and an optional zone for the unknown-time noon fallback)
 * is needed — which is all a contacts-imported friend may carry.
 */
export const SynastryPersonSchema = z.object({
  birthDate: plausibleInstant,
  birthTime: plausibleInstant.nullable().optional(),
  timeZoneIdentifier: z.string().min(1).max(64).optional(),
});

export type SynastryPerson = z.infer<typeof SynastryPersonSchema>;

/** Wire format for `POST /synastry`: the two people to compare. */
export const SynastryRequestSchema = z.object({
  personA: SynastryPersonSchema,
  personB: SynastryPersonSchema,
});

export type SynastryRequest = z.infer<typeof SynastryRequestSchema>;

export const SynastryResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  /** A↔B cross-aspects, sorted ascending by orb (tightest first). */
  aspects: z.array(SynastryAspectSchema),
});

export type SynastryResult = z.infer<typeof SynastryResultSchema>;

/**
 * A single upcoming moment when a transiting planet's aspect to a natal
 * planet becomes *exact* — the "timing" the rest of the category only gestures
 * at. Mirrors `ForecastEvent` in the iOS models.
 */
export const ForecastEventSchema = z.object({
  transiting: z.string(),
  natal: z.string(),
  type: AspectTypeSchema,
  exactAngle: z.number(),
  /** The instant the aspect perfects. */
  exactAt: z.string().datetime({ offset: true }),
});

export type ForecastEvent = z.infer<typeof ForecastEventSchema>;

/** Wire format for `POST /forecast`: birth data + window. */
export const ForecastRequestSchema = BirthDataSchema.extend({
  from: plausibleInstant.optional(),
  days: z.number().int().min(1).max(120).optional(),
});

export type ForecastRequest = z.infer<typeof ForecastRequestSchema>;

export const ForecastResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  from: z.string().datetime({ offset: true }),
  days: z.number(),
  /** Exact transit moments in the window, sorted earliest first. */
  events: z.array(ForecastEventSchema),
});

export type ForecastResult = z.infer<typeof ForecastResultSchema>;

/**
 * The composite (midpoint) chart of two people — a single merged relationship
 * chart. Reuses the synastry person payload for input.
 */
export const CompositeResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  /** Composite planets (midpoints of the two charts). */
  planets: z.array(PlanetPositionSchema),
  /** Major aspects within the composite chart, sorted ascending by orb. */
  aspects: z.array(AspectSchema),
});

export type CompositeResult = z.infer<typeof CompositeResultSchema>;

/** Wire format for `POST /moon`: an optional moment (defaults to now). */
export const MoonPhaseRequestSchema = z.object({
  at: plausibleInstant.optional(),
});

export type MoonPhaseRequest = z.infer<typeof MoonPhaseRequestSchema>;

/**
 * Tonight's Moon — phase, illumination, and the next new/full dates. Global
 * (not per-user) sky data. Mirrors `MoonPhaseResult` in the iOS models.
 */
export const MoonPhaseResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  /** The moment the phase was computed for. */
  at: z.string().datetime({ offset: true }),
  /** Phase angle 0–360° (0 = new, 90 = first quarter, 180 = full). */
  angle: z.number(),
  /** Human-readable phase name ("Waxing Gibbous", …). */
  phase: z.string(),
  /** Illuminated fraction of the lunar disk, 0–1. */
  illumination: z.number().min(0).max(1),
  /** The next new moon at or after `at`. */
  nextNewMoon: z.string().datetime({ offset: true }),
  /** The next full moon at or after `at`. */
  nextFullMoon: z.string().datetime({ offset: true }),
});

export type MoonPhaseResult = z.infer<typeof MoonPhaseResultSchema>;

/** Wire format for `POST /progressions`: birth data + an optional target date. */
export const ProgressionsRequestSchema = BirthDataSchema.extend({
  on: plausibleInstant.optional(),
});

export type ProgressionsRequest = z.infer<typeof ProgressionsRequestSchema>;

/**
 * Secondary-progressed chart — the natal chart "evolved" to a target date via
 * the day-for-a-year technique. Mirrors `ProgressionsResult` in the iOS models.
 */
export const ProgressionsResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  /** The target date the progression was computed for. */
  on: z.string().datetime({ offset: true }),
  /** The progressed instant (birth + age-in-years days) actually sampled. */
  progressedAt: z.string().datetime({ offset: true }),
  /** Progressed positions of all ten bodies. */
  planets: z.array(PlanetPositionSchema),
});

export type ProgressionsResult = z.infer<typeof ProgressionsResultSchema>;

/** Wire format for `POST /retrogrades`: an optional moment (defaults to now). */
export const RetrogradesRequestSchema = z.object({
  at: plausibleInstant.optional(),
});

export type RetrogradesRequest = z.infer<typeof RetrogradesRequestSchema>;

export const StationDirectionSchema = z.enum(["retrograde", "direct"]);
export type StationDirection = z.infer<typeof StationDirectionSchema>;

/** One body's apparent-motion state and its next station. */
export const RetrogradeStateSchema = z.object({
  planet: z.string(),
  isRetrograde: z.boolean(),
  /** The next station instant, or null if none within the search window. */
  nextStationAt: z.string().datetime({ offset: true }).nullable(),
  /** The direction the body takes *after* the next station. */
  nextStationDirection: StationDirectionSchema.nullable(),
});

export type RetrogradeState = z.infer<typeof RetrogradeStateSchema>;

/**
 * Which bodies are retrograde now and when each next turns — the culturally
 * dominant "is Mercury retrograde?" question, answered for real. Global (not
 * per-user) sky data. Mirrors `RetrogradesResult` in the iOS models.
 */
export const RetrogradesResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  /** The moment the states were computed for. */
  at: z.string().datetime({ offset: true }),
  /** Mercury through Pluto (the Sun and Moon never retrograde). */
  planets: z.array(RetrogradeStateSchema),
});

export type RetrogradesResult = z.infer<typeof RetrogradesResultSchema>;

/** Wire format for `POST /returns`: birth data + an optional window start. */
export const ReturnsRequestSchema = BirthDataSchema.extend({
  from: plausibleInstant.optional(),
});

export type ReturnsRequest = z.infer<typeof ReturnsRequestSchema>;

/**
 * One upcoming planetary return — when a slow planet next comes back to its
 * natal longitude (the Saturn return at ~29, the Jupiter return every ~12).
 * Mirrors `ReturnEvent` in the iOS models.
 */
export const ReturnEventSchema = z.object({
  /** "Jupiter" or "Saturn". */
  planet: z.string(),
  /** Which return this is — 1 = first, 2 = second, … */
  returnNumber: z.number().int().positive(),
  /** The instant the return perfects. */
  exactAt: z.string().datetime({ offset: true }),
  /** The natal longitude the planet returns to. */
  natalLongitude: z.number(),
});

export type ReturnEvent = z.infer<typeof ReturnEventSchema>;

export const ReturnsResultSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  from: z.string().datetime({ offset: true }),
  /** Next Jupiter and Saturn returns, sorted earliest first. */
  events: z.array(ReturnEventSchema),
});

export type ReturnsResult = z.infer<typeof ReturnsResultSchema>;
