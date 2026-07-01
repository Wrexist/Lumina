/**
 * Moon-phase naming — the pure part of the lunar feature. The astronomy-engine
 * orchestration (illumination, next new/full search) lives in the service; the
 * angle→name mapping is pure and unit-testable here.
 */

export const MOON_PHASE_NAMES = [
  "New Moon",
  "Waxing Crescent",
  "First Quarter",
  "Waxing Gibbous",
  "Full Moon",
  "Waning Gibbous",
  "Last Quarter",
  "Waning Crescent",
] as const;

export type MoonPhaseName = (typeof MOON_PHASE_NAMES)[number];

const FULL_CIRCLE = 360;
const PHASE_BIN = 45;
const HALF_BIN = 22.5;

/**
 * Maps a phase angle (0–360°, where 0 = new, 90 = first quarter, 180 = full,
 * 270 = last quarter) to its phase name. Eight 45° bins centered on the
 * cardinal phases — so "New Moon" spans 337.5°–22.5°, etc.
 */
export function phaseName(angle: number): MoonPhaseName {
  const normalized = ((angle % FULL_CIRCLE) + FULL_CIRCLE) % FULL_CIRCLE;
  const index = Math.floor(((normalized + HALF_BIN) % FULL_CIRCLE) / PHASE_BIN);
  return MOON_PHASE_NAMES[index] ?? "New Moon";
}
