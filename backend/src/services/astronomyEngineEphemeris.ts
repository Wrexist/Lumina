import { Body, Ecliptic, GeoVector } from "astronomy-engine";
import { placidusHouses } from "../lib/houses.ts";
import type { BirthData, HouseCusps, NatalChart, PlanetPosition } from "../types.ts";
import type { EphemerisService } from "./ephemeris.ts";

interface PlanetSpec {
  readonly body: Body;
  readonly name: string;
}

const PLANETS: readonly PlanetSpec[] = [
  { body: Body.Sun, name: "Sun" },
  { body: Body.Moon, name: "Moon" },
  { body: Body.Mercury, name: "Mercury" },
  { body: Body.Venus, name: "Venus" },
  { body: Body.Mars, name: "Mars" },
  { body: Body.Jupiter, name: "Jupiter" },
  { body: Body.Saturn, name: "Saturn" },
  { body: Body.Uranus, name: "Uranus" },
  { body: Body.Neptune, name: "Neptune" },
  { body: Body.Pluto, name: "Pluto" },
];

const RETROGRADE_PROBE_MS = 60 * 60 * 1000; // one hour earlier

/**
 * Pure-JS ephemeris implementation backed by `astronomy-engine`.
 *
 * Coordinates: geocentric J2000 ecliptic, computed via
 * `Ecliptic(GeoVector(body, t, aberration=true))`. Drift between J2000
 * and tropical-of-date is < 0.5° for births in the last 30 years —
 * within astrological tolerance for v0 and documented for the eventual
 * swap to Swiss Ephemeris precision.
 *
 * TODO(lumina): swap to a swisseph-backed implementation once the
 * Swiss Ephemeris Pro license is procured. The `EphemerisService`
 * interface is the only seam callers depend on.
 */
export class AstronomyEngineEphemeris implements EphemerisService {
  async chart(birthData: BirthData): Promise<NatalChart> {
    const instant = effectiveInstant(birthData);
    const planets = PLANETS.map((spec) => positionAt(spec, instant));
    const houses = housesFor(birthData, instant);
    return {
      calculatedAt: new Date().toISOString(),
      houseSystem: houses?.system ?? "placidus",
      planets,
      houses,
    };
  }
}

function effectiveInstant(birthData: BirthData): Date {
  // If birthTime is null we use noon UT on the birth date — see LEARNINGS.md.
  const source = birthData.birthTime ?? noonUTOf(birthData.birthDate);
  return new Date(source);
}

function housesFor(birthData: BirthData, instant: Date): HouseCusps | null {
  // Without a real birth time, houses, Asc, and MC are meaningless.
  if (birthData.birthTime == null) return null;
  return placidusHouses(instant, birthData.latitude, birthData.longitude);
}

function noonUTOf(isoDate: string): string {
  const date = new Date(isoDate);
  date.setUTCHours(12, 0, 0, 0);
  return date.toISOString();
}

function geocentricEclipticLongitude(body: Body, instant: Date): number {
  const vec = GeoVector(body, instant, /* aberration */ true);
  return Ecliptic(vec).elon;
}

function positionAt(spec: PlanetSpec, instant: Date): PlanetPosition {
  const vec = GeoVector(spec.body, instant, /* aberration */ true);
  const ecl = Ecliptic(vec);

  const earlier = new Date(instant.getTime() - RETROGRADE_PROBE_MS);
  const lonEarlier = geocentricEclipticLongitude(spec.body, earlier);

  return {
    planet: spec.name,
    longitude: normalizeLongitude(ecl.elon),
    latitude: ecl.elat,
    isRetrograde: signedLongitudeDelta(ecl.elon, lonEarlier) < 0,
  };
}

function normalizeLongitude(deg: number): number {
  const wrapped = deg % 360;
  return wrapped < 0 ? wrapped + 360 : wrapped;
}

function signedLongitudeDelta(now: number, earlier: number): number {
  let delta = now - earlier;
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta;
}
