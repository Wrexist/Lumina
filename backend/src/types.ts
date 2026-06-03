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
