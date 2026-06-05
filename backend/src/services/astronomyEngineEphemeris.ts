import { Body, Ecliptic, GeoVector } from "astronomy-engine";
import { computeAspects } from "../lib/aspects.ts";
import { placidusHouses, tropicalAngles, wholeSignHouses } from "../lib/houses.ts";
import { lahiriAyanamsha, tropicalToSidereal } from "../lib/sidereal.ts";
import { noonLocalAsUTC } from "../lib/timezone.ts";
import { computeTransits } from "../lib/transits.ts";
import { computeSynastry } from "../lib/synastry.ts";
import { findCrossings } from "../lib/forecast.ts";
import type {
  AspectType,
  BirthData,
  ForecastEvent,
  ForecastResult,
  HouseCusps,
  HouseSystem,
  NatalChart,
  PlanetPosition,
  SynastryPerson,
  SynastryResult,
  TransitsResult,
} from "../types.ts";
import type { ChartOptions, EphemerisService, ForecastOptions, TransitOptions } from "./ephemeris.ts";

/** The five major aspects, by exact angle, used for forecasting exact hits. */
const FORECAST_ASPECTS: readonly { type: AspectType; exactAngle: number }[] = [
  { type: "conjunction", exactAngle: 0 },
  { type: "sextile", exactAngle: 60 },
  { type: "square", exactAngle: 90 },
  { type: "trine", exactAngle: 120 },
  { type: "opposition", exactAngle: 180 },
];

/** The fields `effectiveInstant` needs — a `BirthData` or a synastry person. */
interface InstantSource {
  readonly birthDate: string;
  readonly birthTime?: string | null;
  readonly timeZoneIdentifier?: string | null;
}

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
  async chart(birthData: BirthData, options: ChartOptions = {}): Promise<NatalChart> {
    const houseSystem: HouseSystem = options.houseSystem ?? "placidus";
    const instant = effectiveInstant(birthData);
    const tropicalPlanets = PLANETS.map((spec) => positionAt(spec, instant));
    const ayanamsha = houseSystem === "sidereal" ? lahiriAyanamsha(instant) : 0;
    const planets = ayanamsha === 0
      ? tropicalPlanets
      : tropicalPlanets.map((p) => ({ ...p, longitude: tropicalToSidereal(p.longitude, ayanamsha) }));
    const houses = housesFor(birthData, instant, houseSystem, ayanamsha);
    const aspects = computeAspects(planets);
    return {
      calculatedAt: new Date().toISOString(),
      houseSystem,
      planets,
      aspects,
      houses,
    };
  }

  async transits(birthData: BirthData, options: TransitOptions = {}): Promise<TransitsResult> {
    const at = options.at ?? new Date();
    // Natal positions are tropical (J2000), matching the default chart; the
    // sidereal/house-system choice doesn't affect transit longitudes.
    const natalInstant = effectiveInstant(birthData);
    const natalPlanets = PLANETS.map((spec) => positionAt(spec, natalInstant));
    const transitingPlanets = PLANETS.map((spec) => positionAt(spec, at));
    return {
      calculatedAt: new Date().toISOString(),
      transitAt: at.toISOString(),
      transitingPlanets,
      transits: computeTransits(transitingPlanets, natalPlanets),
    };
  }

  async synastry(personA: SynastryPerson, personB: SynastryPerson): Promise<SynastryResult> {
    // Synastry compares geocentric planet longitudes, which are independent
    // of birth place — so each person needs only a date (+ optional time).
    const planetsA = PLANETS.map((spec) => positionAt(spec, effectiveInstant(personA)));
    const planetsB = PLANETS.map((spec) => positionAt(spec, effectiveInstant(personB)));
    return {
      calculatedAt: new Date().toISOString(),
      aspects: computeSynastry(planetsA, planetsB),
    };
  }

  async forecast(birthData: BirthData, options: ForecastOptions = {}): Promise<ForecastResult> {
    const from = options.from ?? new Date();
    const days = options.days ?? 30;
    const natalInstant = effectiveInstant(birthData);
    const natalPlanets = PLANETS.map((spec) => positionAt(spec, natalInstant));
    const events: ForecastEvent[] = [];

    for (const spec of PLANETS) {
      // Memoise the transiting body's longitude so re-sampling the same
      // instants across many natal targets is effectively free.
      const cache = new Map<number, number>();
      const longitudeAt = (time: number): number => {
        const key = Math.round(time / 60_000);
        const cached = cache.get(key);
        if (cached !== undefined) return cached;
        const lon = geocentricEclipticLongitude(spec.body, new Date(time));
        cache.set(key, lon);
        return lon;
      };

      for (const natal of natalPlanets) {
        for (const aspect of FORECAST_ASPECTS) {
          const targets = aspect.exactAngle === 0
            ? [natal.longitude]
            : [
                normalizeLongitude(natal.longitude + aspect.exactAngle),
                normalizeLongitude(natal.longitude - aspect.exactAngle),
              ];
          for (const target of targets) {
            for (const at of findCrossings(longitudeAt, target, from.getTime(), days)) {
              events.push({
                transiting: spec.name,
                natal: natal.planet,
                type: aspect.type,
                exactAngle: aspect.exactAngle,
                exactAt: new Date(at).toISOString(),
              });
            }
          }
        }
      }
    }

    events.sort((a, b) => a.exactAt.localeCompare(b.exactAt));
    return {
      calculatedAt: new Date().toISOString(),
      from: from.toISOString(),
      days,
      events,
    };
  }
}

function effectiveInstant(source: InstantSource): Date {
  // A known birth time is already an absolute instant (the iOS client encodes
  // a `Date`). For an unknown time we use the astrological convention of noon
  // *local* time on the birth date — resolved through the birth time zone so
  // we neither shift the calendar day nor silently use noon UTC. A synastry
  // person may carry no zone at all, in which case noon UTC is the fallback.
  if (source.birthTime != null) return new Date(source.birthTime);
  return noonLocalAsUTC(new Date(source.birthDate), source.timeZoneIdentifier ?? "UTC");
}

function housesFor(
  birthData: BirthData,
  instant: Date,
  houseSystem: HouseSystem,
  ayanamsha: number,
): HouseCusps | null {
  // Without a real birth time, houses, Asc, and MC are meaningless.
  if (birthData.birthTime == null) return null;
  if (houseSystem === "placidus") {
    return placidusHouses(instant, birthData.latitude, birthData.longitude);
  }
  // For wholeSign and sidereal we anchor on the (tropical) ascendant and
  // step in 30° increments. For sidereal we additionally subtract the
  // Lahiri ayanamsha from both Asc and MC before deriving the cusps.
  const tropical = tropicalAngles(instant, birthData.latitude, birthData.longitude);
  const asc = ayanamsha === 0 ? tropical.ascendant : tropicalToSidereal(tropical.ascendant, ayanamsha);
  const mc = ayanamsha === 0 ? tropical.midheaven : tropicalToSidereal(tropical.midheaven, ayanamsha);
  const houses = wholeSignHouses(asc, mc);
  return { ...houses, system: houseSystem };
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
