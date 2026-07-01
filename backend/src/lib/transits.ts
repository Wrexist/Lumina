/**
 * Transit aspects: how the current sky touches a natal chart.
 *
 * For every transiting planet against every natal planet, the angular
 * separation is compared to the five major Ptolemaic aspects using the
 * tight orbs appropriate to transits — a transit is a moment, not a
 * lifelong placement, so its orbs are far smaller than natal orbs.
 *
 * `applying` (the aspect is tightening toward exact) is derived from the
 * transiting planet's direction of travel, already known via
 * `isRetrograde`: nudge the transit longitude one small step along its
 * motion and see whether the orb shrinks. No extra ephemeris sampling.
 *
 * Same-named pairs are kept on purpose — transiting Sun conjunct natal Sun
 * is your solar return (birthday), a real and wanted contact.
 *
 * Returned tightest-orb-first so consumers can show only the top few.
 *
 * Note: when a chart has no birth time the natal Moon is a noon
 * approximation, so transits to it carry the same caveat as the natal Moon
 * itself. Callers that know the time is unknown may wish to de-emphasise
 * Moon contacts.
 */
import type { AspectType, PlanetPosition, Transit } from "../types.ts";

const FULL_CIRCLE = 360;
const HALF_CIRCLE = 180;

// Longitude nudge (degrees) used to classify applying vs separating.
// Smaller than any orb, so it never steps past an exact hit.
const MOTION_PROBE_DEG = 0.05;

interface TransitAspectDefinition {
  readonly type: AspectType;
  readonly exactAngle: number;
  readonly orb: number;
}

// Tight transit orbs (modern consensus). Luminaries are not widened: a
// transit's relevance is its exactness, and the Sun/Moon already make
// frequent contacts on their own.
const TRANSIT_ASPECTS: readonly TransitAspectDefinition[] = [
  { type: "conjunction", exactAngle: 0, orb: 3 },
  { type: "sextile", exactAngle: 60, orb: 2 },
  { type: "square", exactAngle: 90, orb: 3 },
  { type: "trine", exactAngle: 120, orb: 3 },
  { type: "opposition", exactAngle: 180, orb: 3 },
];

export function computeTransits(
  transiting: readonly PlanetPosition[],
  natal: readonly PlanetPosition[],
): Transit[] {
  const transits: Transit[] = [];
  for (const transit of transiting) {
    const direction = transit.isRetrograde ? -1 : 1;
    const probedLongitude = normalize(transit.longitude + direction * MOTION_PROBE_DEG);
    for (const target of natal) {
      const aspect = closestTransitAspect(transit, target, probedLongitude);
      if (aspect !== null) transits.push(aspect);
    }
  }
  return transits.sort((a, b) => a.orb - b.orb);
}

function closestTransitAspect(
  transit: PlanetPosition,
  natal: PlanetPosition,
  probedLongitude: number,
): Transit | null {
  const separation = angularSeparation(transit.longitude, natal.longitude);
  const futureSeparation = angularSeparation(probedLongitude, natal.longitude);
  let best: Transit | null = null;
  for (const definition of TRANSIT_ASPECTS) {
    const orb = Math.abs(separation - definition.exactAngle);
    if (orb > definition.orb || (best !== null && orb >= best.orb)) continue;
    const futureOrb = Math.abs(futureSeparation - definition.exactAngle);
    best = {
      transiting: transit.planet,
      natal: natal.planet,
      type: definition.type,
      exactAngle: definition.exactAngle,
      orb,
      applying: futureOrb < orb,
    };
  }
  return best;
}

function angularSeparation(longitude1: number, longitude2: number): number {
  const wrapped = (longitude1 - longitude2) % FULL_CIRCLE;
  const positive = (wrapped + FULL_CIRCLE) % FULL_CIRCLE;
  return positive > HALF_CIRCLE ? FULL_CIRCLE - positive : positive;
}

function normalize(deg: number): number {
  const wrapped = deg % FULL_CIRCLE;
  return wrapped < 0 ? wrapped + FULL_CIRCLE : wrapped;
}
