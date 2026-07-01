/**
 * Secondary progressions — the "day-for-a-year" technique: the chart a number
 * of *days* after birth equal to the person's age in *years* describes how the
 * natal chart has evolved. Pure date math here (unit-testable); the actual
 * position computation lives in the service.
 */

const TROPICAL_YEAR_DAYS = 365.2422;
const MS_PER_DAY = 86_400_000;

/**
 * The progressed instant for `targetMs`: birth + (years elapsed) days. So at
 * age 30 the progressed chart is the sky 30 days after birth.
 */
export function progressedInstant(birthMs: number, targetMs: number): number {
  const yearsElapsed = (targetMs - birthMs) / (TROPICAL_YEAR_DAYS * MS_PER_DAY);
  return birthMs + yearsElapsed * MS_PER_DAY;
}
