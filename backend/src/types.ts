import { z } from "zod";

/**
 * Mirrors `Lumina/Core/Ephemeris/Models/BirthData.swift`.
 * The Swift `Date` fields are encoded as ISO-8601 strings on the wire.
 */
export const BirthDataSchema = z.object({
  birthDate: z.string().datetime({ offset: true }),
  // The iOS encoder always emits this key (null when no birth time is
  // captured). Older clients and ad-hoc CLI callers may omit the key
  // entirely, so accept both via `.nullable().optional()`.
  birthTime: z.string().datetime({ offset: true }).nullable().optional(),
  placeName: z.string().min(1).max(200),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  timeZoneIdentifier: z.string().min(1).max(64),
});

export type BirthData = z.infer<typeof BirthDataSchema>;

export const HouseSystemSchema = z.enum(["placidus", "wholeSign", "sidereal"]);
export type HouseSystem = z.infer<typeof HouseSystemSchema>;

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
