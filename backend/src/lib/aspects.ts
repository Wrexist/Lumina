/**
 * Major aspects between natal planet pairs.
 *
 * For each unordered pair of planets, the angular separation is compared
 * against the five major Ptolemaic aspects. If the deviation (orb) is
 * within the per-aspect tolerance, the pair is recorded.
 *
 * Orb policy follows the modern Western consensus (Tarnas, Hand, Greene):
 * - Conjunction / Opposition: 8°, widened to 10° when the Sun or Moon is
 *   one of the bodies.
 * - Square / Trine: 6°, widened to 8° for Sun/Moon involvement.
 * - Sextile: 4°, widened to 6° for Sun/Moon involvement.
 *
 * Returned in ascending-orb order (tightest aspects first) — consumers
 * often want to render only the closest few.
 */
import type { Aspect, AspectType, PlanetPosition } from "../types.ts";

const FULL_CIRCLE = 360;
const HALF_CIRCLE = 180;

interface AspectDefinition {
  readonly type: AspectType;
  readonly exactAngle: number;
  readonly baseOrb: number;
  readonly luminaryOrb: number;
}

const ASPECTS: readonly AspectDefinition[] = [
  { type: "conjunction", exactAngle: 0, baseOrb: 8, luminaryOrb: 10 },
  { type: "sextile", exactAngle: 60, baseOrb: 4, luminaryOrb: 6 },
  { type: "square", exactAngle: 90, baseOrb: 6, luminaryOrb: 8 },
  { type: "trine", exactAngle: 120, baseOrb: 6, luminaryOrb: 8 },
  { type: "opposition", exactAngle: 180, baseOrb: 8, luminaryOrb: 10 },
];

const LUMINARIES = new Set(["Sun", "Moon"]);

export function computeAspects(planets: readonly PlanetPosition[]): Aspect[] {
  const aspects: Aspect[] = [];
  for (let i = 0; i < planets.length; i += 1) {
    for (let j = i + 1; j < planets.length; j += 1) {
      const p1 = planets[i];
      const p2 = planets[j];
      if (!p1 || !p2) continue;
      const aspect = closestAspect(p1, p2);
      if (aspect !== null) aspects.push(aspect);
    }
  }
  return aspects.sort((a, b) => a.orb - b.orb);
}

function closestAspect(p1: PlanetPosition, p2: PlanetPosition): Aspect | null {
  const separation = angularSeparation(p1.longitude, p2.longitude);
  const involvesLuminary = LUMINARIES.has(p1.planet) || LUMINARIES.has(p2.planet);
  let best: Aspect | null = null;
  for (const definition of ASPECTS) {
    const deviation = Math.abs(separation - definition.exactAngle);
    const maxOrb = involvesLuminary ? definition.luminaryOrb : definition.baseOrb;
    if (deviation <= maxOrb && (best === null || deviation < best.orb)) {
      best = {
        planet1: p1.planet,
        planet2: p2.planet,
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
