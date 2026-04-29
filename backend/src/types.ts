import { z } from "zod";

/**
 * Mirrors `Lumina/Core/Ephemeris/Models/BirthData.swift`.
 * The Swift `Date` fields are encoded as ISO-8601 strings on the wire.
 */
export const BirthDataSchema = z.object({
  birthDate: z.string().datetime({ offset: true }),
  birthTime: z.string().datetime({ offset: true }).nullable(),
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

export const NatalChartSchema = z.object({
  calculatedAt: z.string().datetime({ offset: true }),
  houseSystem: HouseSystemSchema,
  planets: z.array(PlanetPositionSchema),
});

export type NatalChart = z.infer<typeof NatalChartSchema>;
