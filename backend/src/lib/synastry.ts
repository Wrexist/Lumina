/**
 * Synastry: the cross-aspects between two people's natal charts — the
 * factual layer of a relationship reading. For every planet of person A
 * against every planet of person B, the angular separation is matched to
 * the five major aspects using natal-scale orbs (wider than transit orbs;
 * widened again when a luminary is involved).
 *
 * This module is deliberately *facts only* — no compatibility score. Scoring
 * is a subjective interpretation and lives in the app
 * (`CompatibilityScorer`), kept separate from the deterministic ephemeris.
 *
 * Same-named pairs are kept (A's Sun vs B's Sun is a real contact). Returned
 * tightest-orb-first.
 */
import type { AspectType, PlanetPosition, SynastryAspect } from "../types.ts";

const FULL_CIRCLE = 360;
const HALF_CIRCLE = 180;

interface SynastryAspectDefinition {
  readonly type: AspectType;
  readonly exactAngle: number;
  readonly baseOrb: number;
  readonly luminaryOrb: number;
}

// Natal-scale orbs (matching lib/aspects.ts), widened for Sun/Moon contacts.
const SYNASTRY_ASPECTS: readonly SynastryAspectDefinition[] = [
  { type: "conjunction", exactAngle: 0, baseOrb: 8, luminaryOrb: 10 },
  { type: "sextile", exactAngle: 60, baseOrb: 4, luminaryOrb: 6 },
  { type: "square", exactAngle: 90, baseOrb: 6, luminaryOrb: 8 },
  { type: "trine", exactAngle: 120, baseOrb: 6, luminaryOrb: 8 },
  { type: "opposition", exactAngle: 180, baseOrb: 8, luminaryOrb: 10 },
];

const LUMINARIES = new Set(["Sun", "Moon"]);

export function computeSynastry(
  planetsA: readonly PlanetPosition[],
  planetsB: readonly PlanetPosition[],
): SynastryAspect[] {
  const aspects: SynastryAspect[] = [];
  for (const a of planetsA) {
    for (const b of planetsB) {
      const aspect = closestSynastryAspect(a, b);
      if (aspect !== null) aspects.push(aspect);
    }
  }
  return aspects.sort((x, y) => x.orb - y.orb);
}

function closestSynastryAspect(a: PlanetPosition, b: PlanetPosition): SynastryAspect | null {
  const separation = angularSeparation(a.longitude, b.longitude);
  const involvesLuminary = LUMINARIES.has(a.planet) || LUMINARIES.has(b.planet);
  let best: SynastryAspect | null = null;
  for (const definition of SYNASTRY_ASPECTS) {
    const orb = Math.abs(separation - definition.exactAngle);
    const maxOrb = involvesLuminary ? definition.luminaryOrb : definition.baseOrb;
    if (orb <= maxOrb && (best === null || orb < best.orb)) {
      best = {
        planetA: a.planet,
        planetB: b.planet,
        type: definition.type,
        exactAngle: definition.exactAngle,
        orb,
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
