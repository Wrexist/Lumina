/**
 * Lahiri ayanamsha — the offset between the tropical and Lahiri sidereal
 * zodiacs. This is the official ayanamsha of the Indian government and
 * the most widely used sidereal reference for Vedic astrology.
 *
 * To convert a tropical ecliptic longitude to sidereal:
 *   λ_sidereal = (λ_tropical - ayanamsha) mod 360
 *
 * Reference: Spica is fixed at 0° Libra (180° sidereal). The ayanamsha
 * was 23°51'12" at J2000 and drifts ~50.27"/year via the precession of
 * the equinoxes.
 *
 * This is a linear approximation accurate to better than 30" for dates
 * within a few centuries of J2000 — well within astrological tolerance.
 * For sub-arc-minute precision in the year ±5000 range, swap for the
 * polynomial expansion used by Swiss Ephemeris.
 */

const LAHIRI_AT_J2000_DEG = 23 + 51 / 60 + 12 / 3600; // 23° 51' 12"
const PRECESSION_ARCSEC_PER_YEAR = 50.2719; // IAU 2000A
const J2000_JD = 2_451_545.0;
const DAYS_PER_YEAR = 365.25;
const FULL_CIRCLE = 360;

export function lahiriAyanamsha(utcInstant: Date): number {
  const jd = utcInstant.getTime() / 86_400_000 + 2_440_587.5;
  const yearsFromJ2000 = (jd - J2000_JD) / DAYS_PER_YEAR;
  return LAHIRI_AT_J2000_DEG + (yearsFromJ2000 * PRECESSION_ARCSEC_PER_YEAR) / 3600;
}

export function tropicalToSidereal(longitudeDeg: number, ayanamshaDeg: number): number {
  const wrapped = (longitudeDeg - ayanamshaDeg) % FULL_CIRCLE;
  return wrapped < 0 ? wrapped + FULL_CIRCLE : wrapped;
}
