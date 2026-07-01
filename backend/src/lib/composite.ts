/**
 * Composite chart: the midpoint chart of two people — a single "relationship
 * chart" where each planet sits at the shorter-arc midpoint of the two
 * natal positions. A standard technique distinct from synastry (which compares
 * the two charts); here we *merge* them. Pure and unit-testable.
 */
import type { PlanetPosition } from "../types.ts";

const FULL_CIRCLE = 360;
const HALF_CIRCLE = 180;

/** Shorter-arc midpoint of two ecliptic longitudes (degrees, 0–360). */
export function midpointLongitude(a: number, b: number): number {
  // Shorter-arc signed difference b − a, in (−180, 180].
  const delta = ((b - a + 3 * HALF_CIRCLE) % FULL_CIRCLE) - HALF_CIRCLE;
  return ((a + delta / 2) % FULL_CIRCLE + FULL_CIRCLE) % FULL_CIRCLE;
}

/**
 * The composite planets: for each body present in both charts, the midpoint of
 * the two longitudes (latitudes averaged). Composite planets have no
 * meaningful retrograde state, so it's reported false.
 */
export function computeComposite(
  planetsA: readonly PlanetPosition[],
  planetsB: readonly PlanetPosition[],
): PlanetPosition[] {
  const byNameB = new Map(planetsB.map((planet) => [planet.planet, planet]));
  const composite: PlanetPosition[] = [];
  for (const planet of planetsA) {
    const counterpart = byNameB.get(planet.planet);
    if (counterpart === undefined) continue;
    composite.push({
      planet: planet.planet,
      longitude: midpointLongitude(planet.longitude, counterpart.longitude),
      latitude: (planet.latitude + counterpart.latitude) / 2,
      isRetrograde: false,
    });
  }
  return composite;
}
