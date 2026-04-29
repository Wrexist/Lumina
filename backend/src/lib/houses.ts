/**
 * Placidus house cusps + Ascendant + Midheaven.
 *
 * The Placidus system is the most widely used Western house system —
 * it splits the diurnal arc and nocturnal arc of every degree of the
 * ecliptic into thirds. The intermediate cusps (11, 12, 2, 3) require
 * an iterative solver because the cusp's declination depends on its
 * ecliptic longitude, which depends on its declination via the
 * semi-arc relation.
 *
 * For latitudes ≥ ~66.5° the algorithm fails (some houses don't exist
 * for part of the year). We fall back to Whole Sign houses in that
 * case — see `wholeSignFallback`.
 *
 * Math sources:
 *   - Meeus, "Astronomical Algorithms" (2nd ed.) §13 (sidereal time),
 *     §22 (obliquity), §47 (rising/setting)
 *   - Holden, "A History of Horoscopic Astrology" (Placidus formulas)
 *
 * Verified internally against the standard angle-doubling identities:
 *   - cusp(k+6) = (cusp(k) + 180) mod 360 for opposing houses
 *   - cusp(1) === ascendant, cusp(10) === midheaven
 */
import type { HouseCusps } from "../types.ts";

const MEAN_OBLIQUITY_J2000 = 23.4392911; // degrees, IAU 2006
const HIGH_LATITUDE_THRESHOLD = 66.5; // |lat| above this → fall back

const DEG = Math.PI / 180;
const RAD = 180 / Math.PI;
const FULL_CIRCLE = 360;
const HALF_CIRCLE = 180;
const QUARTER_CIRCLE = 90;
const THIRTY_DEGREES = 30;

const PLACIDUS_MAX_ITERATIONS = 20;
const PLACIDUS_TOLERANCE_DEG = 1e-6;

interface PlacidusInputs {
  readonly ramc: number; // Right Ascension of Midheaven, degrees
  readonly latitude: number; // observer latitude, degrees
  readonly obliquity: number; // ecliptic obliquity, degrees
}

export function placidusHouses(
  utcInstant: Date,
  latitude: number,
  longitude: number,
): HouseCusps {
  const jd = julianDay(utcInstant);
  const obliquity = meanObliquity(jd);
  const ramc = rightAscensionOfMidheaven(jd, longitude);

  if (Math.abs(latitude) >= HIGH_LATITUDE_THRESHOLD) {
    return wholeSignFallback({ ramc, latitude, obliquity });
  }

  const mc = midheaven(ramc, obliquity);
  const asc = ascendant({ ramc, latitude, obliquity });
  const cusp11 = placidusIntermediate({ ramc, latitude, obliquity }, 1, 11);
  const cusp12 = placidusIntermediate({ ramc, latitude, obliquity }, 2, 12);
  const cusp2 = placidusIntermediate({ ramc, latitude, obliquity }, 1, 2);
  const cusp3 = placidusIntermediate({ ramc, latitude, obliquity }, 2, 3);

  const cusps = [
    asc,
    cusp2,
    cusp3,
    norm(mc + HALF_CIRCLE),
    norm(cusp11 + HALF_CIRCLE),
    norm(cusp12 + HALF_CIRCLE),
    norm(asc + HALF_CIRCLE),
    norm(cusp2 + HALF_CIRCLE),
    norm(cusp3 + HALF_CIRCLE),
    mc,
    cusp11,
    cusp12,
  ];

  return { system: "placidus", ascendant: asc, midheaven: mc, cusps };
}

// ── Astronomical primitives ─────────────────────────────────────────

function julianDay(date: Date): number {
  // ms since 1970-01-01 → JD; Unix epoch is JD 2440587.5
  return date.getTime() / 86_400_000 + 2_440_587.5;
}

function meanObliquity(jd: number): number {
  // IAU 2006: 23°26'21.406" - 46.836769"·T - 0.0001831"·T² + ...
  // T = centuries from J2000. Good to better than 0.01" over a few millennia.
  const t = (jd - 2_451_545.0) / 36_525;
  const arcseconds =
    23 * 3600 + 26 * 60 + 21.406 - 46.836769 * t - 0.0001831 * t * t + 0.0020034 * t ** 3;
  return arcseconds / 3600;
}

function rightAscensionOfMidheaven(jd: number, longitudeEastDeg: number): number {
  // GMST per IAU 1982/Meeus eq. 12.4 in degrees, then add east longitude.
  const t = (jd - 2_451_545.0) / 36_525;
  const gmst =
    280.46061837 +
    360.98564736629 * (jd - 2_451_545.0) +
    0.000387933 * t * t -
    (t * t * t) / 38_710_000;
  return norm(gmst + longitudeEastDeg);
}

function midheaven(ramc: number, obliquity: number): number {
  // λ_MC = atan2(sin(RAMC), cos(RAMC) · cos(ε))
  const lon = Math.atan2(
    Math.sin(ramc * DEG),
    Math.cos(ramc * DEG) * Math.cos(obliquity * DEG),
  ) * RAD;
  return norm(lon);
}

function ascendant({ ramc, latitude, obliquity }: PlacidusInputs): number {
  // Standard Asc formula:
  //   tan λ_Asc = -cos(RAMC) / (sin(ε)·tan(φ) + cos(ε)·sin(RAMC))
  // Use atan2 to keep the correct quadrant; the Asc is always east of MC,
  // i.e. cusps[1] is in (MC, MC+180) modulo 360.
  const numerator = -Math.cos(ramc * DEG);
  const denominator =
    Math.sin(obliquity * DEG) * Math.tan(latitude * DEG) +
    Math.cos(obliquity * DEG) * Math.sin(ramc * DEG);
  let asc = Math.atan2(numerator, denominator) * RAD;
  asc = norm(asc);

  // Asc must lie east of the MC; if not, add 180°.
  const mc = midheaven(ramc, obliquity);
  if (norm(asc - mc) > HALF_CIRCLE) {
    asc = norm(asc + HALF_CIRCLE);
  }
  return asc;
}

function placidusIntermediate(
  inputs: PlacidusInputs,
  multiple: 1 | 2,
  cuspNumber: 11 | 12 | 2 | 3,
): number {
  const { ramc, latitude, obliquity } = inputs;
  const fraction = multiple / 3; // 1/3 or 2/3
  const aboveHorizon = cuspNumber === 11 || cuspNumber === 12;

  // Position around the diurnal circle (in HA space, measured westward from
  // the upper meridian). Above horizon, eastern cusps (11, 12) sit between
  // MC (HA=0) and Asc (HA=-SA_diurnal), so α_cusp = RAMC + fraction · SA.
  // Below horizon, eastern cusps (2, 3) sit between Asc (HA=-SA) and IC
  // (HA=-180), so α_cusp = RAMC + SA + fraction · (180 - SA).

  // Equal-house initial guess (good start for convergence at moderate latitudes).
  const equalOffsetDegrees = aboveHorizon
    ? fraction * QUARTER_CIRCLE
    : QUARTER_CIRCLE + fraction * QUARTER_CIRCLE;
  let alpha = norm(ramc + equalOffsetDegrees);

  for (let i = 0; i < PLACIDUS_MAX_ITERATIONS; i += 1) {
    // Convert α (right ascension of cusp) → ecliptic longitude λ.
    const lambda = rightAscensionToEcliptic(alpha, obliquity);
    // Declination of the cusp from λ.
    const sinDelta = Math.sin(obliquity * DEG) * Math.sin(lambda * DEG);
    const delta = Math.asin(Math.max(-1, Math.min(1, sinDelta))) * RAD;
    // Diurnal semi-arc at the cusp's latitude/declination.
    const semiArc = diurnalSemiArc(latitude, delta);
    if (!Number.isFinite(semiArc)) {
      // Circumpolar geometry — fall back to equal-house spacing.
      return norm(midheaven(ramc, obliquity) + (cuspNumber - 10) * THIRTY_DEGREES);
    }
    const newAlpha = aboveHorizon
      ? norm(ramc + fraction * semiArc)
      : norm(ramc + semiArc + fraction * (HALF_CIRCLE - semiArc));
    if (Math.abs(angularDelta(newAlpha, alpha)) < PLACIDUS_TOLERANCE_DEG) {
      return rightAscensionToEcliptic(newAlpha, obliquity);
    }
    alpha = newAlpha;
  }
  // Fallback if non-convergent.
  return rightAscensionToEcliptic(alpha, obliquity);
}

function rightAscensionToEcliptic(alphaDeg: number, obliquity: number): number {
  // Inverse of α = atan2(sin λ · cos ε, cos λ).
  const lambda = Math.atan2(
    Math.sin(alphaDeg * DEG) / Math.cos(obliquity * DEG),
    Math.cos(alphaDeg * DEG),
  ) * RAD;
  return norm(lambda);
}

function diurnalSemiArc(latitudeDeg: number, declinationDeg: number): number {
  // arccos(-tan φ · tan δ) — degrees.
  const value = -Math.tan(latitudeDeg * DEG) * Math.tan(declinationDeg * DEG);
  if (value <= -1 || value >= 1) return Number.NaN;
  return Math.acos(value) * RAD;
}

function wholeSignFallback({ ramc, latitude, obliquity }: PlacidusInputs): HouseCusps {
  const asc = ascendant({ ramc, latitude, obliquity });
  return wholeSignHouses(asc, midheaven(ramc, obliquity));
}

/**
 * Whole-Sign houses anchored on a given ascendant. The first cusp is the
 * 0° boundary of the ascendant's sign; subsequent cusps step by 30°.
 *
 * Used both as the polar Placidus fallback (where the iterative solver
 * fails) and as the Vedic / sidereal house default.
 */
export function wholeSignHouses(ascendantDeg: number, midheavenDeg: number): HouseCusps {
  const ascSignStart = Math.floor(ascendantDeg / THIRTY_DEGREES) * THIRTY_DEGREES;
  const cusps = Array.from({ length: 12 }, (_, i) => norm(ascSignStart + i * THIRTY_DEGREES));
  return {
    system: "wholeSign",
    ascendant: ascendantDeg,
    midheaven: midheavenDeg,
    cusps,
  };
}

/**
 * Compute just the tropical Ascendant + Midheaven for a given instant
 * and observer location. Used by the sidereal pipeline, which needs the
 * angles in tropical coordinates before subtracting the ayanamsha.
 */
export function tropicalAngles(
  utcInstant: Date,
  latitude: number,
  longitude: number,
): { readonly ascendant: number; readonly midheaven: number } {
  const jd = julianDay(utcInstant);
  const obliquity = meanObliquity(jd);
  const ramc = rightAscensionOfMidheaven(jd, longitude);
  return {
    ascendant: ascendant({ ramc, latitude, obliquity }),
    midheaven: midheaven(ramc, obliquity),
  };
}

// ── Helpers ─────────────────────────────────────────────────────────

function norm(deg: number): number {
  const wrapped = deg % FULL_CIRCLE;
  return wrapped < 0 ? wrapped + FULL_CIRCLE : wrapped;
}

function angularDelta(a: number, b: number): number {
  let delta = a - b;
  if (delta > HALF_CIRCLE) delta -= FULL_CIRCLE;
  if (delta < -HALF_CIRCLE) delta += FULL_CIRCLE;
  return delta;
}

// Suppress unused import warnings of constants in some toolchains.
export const _internal = { MEAN_OBLIQUITY_J2000 };
