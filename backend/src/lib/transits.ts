/**
 * Cross-set aspects: each transiting planet versus every natal planet.
 *
 * Transits use TIGHTER orbs than natal aspects because we care about the
 * exact moment a transiting planet "perfects" an aspect, not the wide
 * field of influence used in interpretive natal work. The defaults here
 * are widely used in modern Western practice (Tarnas, Hand):
 * - Conjunction / Opposition: 4°
 * - Square / Trine: 3°
 * - Sextile: 2°
 *
 * The Sun / Moon orb bonus from natal aspects is dropped here.
 */
import type { PlanetPosition, TransitAspect, AspectType } from "../types.ts";

const FULL_CIRCLE = 360;
const HALF_CIRCLE = 180;

interface AspectDefinition {
  readonly type: AspectType;
  readonly exactAngle: number;
  readonly orb: number;
}

const TRANSIT_ASPECTS: readonly AspectDefinition[] = [
  { type: "conjunction", exactAngle: 0, orb: 4 },
  { type: "sextile", exactAngle: 60, orb: 2 },
  { type: "square", exactAngle: 90, orb: 3 },
  { type: "trine", exactAngle: 120, orb: 3 },
  { type: "opposition", exactAngle: 180, orb: 4 },
];

export function computeTransitAspects(
  natal: readonly PlanetPosition[],
  transiting: readonly PlanetPosition[],
): TransitAspect[] {
  const aspects: TransitAspect[] = [];
  for (const tp of transiting) {
    for (const np of natal) {
      const aspect = closestTransitAspect(tp, np);
      if (aspect !== null) aspects.push(aspect);
    }
  }
  return aspects.sort((a, b) => a.orb - b.orb);
}

function closestTransitAspect(
  transiting: PlanetPosition,
  natal: PlanetPosition,
): TransitAspect | null {
  const separation = angularSeparation(transiting.longitude, natal.longitude);
  let best: TransitAspect | null = null;
  for (const definition of TRANSIT_ASPECTS) {
    const deviation = Math.abs(separation - definition.exactAngle);
    if (deviation <= definition.orb && (best === null || deviation < best.orb)) {
      best = {
        transitingPlanet: transiting.planet,
        natalPlanet: natal.planet,
        type: definition.type,
        exactAngle: definition.exactAngle,
        orb: deviation,
      };
    }
  }
  return best;
}

function angularSeparation(longitude1: number, longitude2: number): number {
  const wrapped = (longitude1 - longitude2) % FULL_CIRCLE;
  const positive = (wrapped + FULL_CIRCLE) % FULL_CIRCLE;
  return positive > HALF_CIRCLE ? FULL_CIRCLE - positive : positive;
}
