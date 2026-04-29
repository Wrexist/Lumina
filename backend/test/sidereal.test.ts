import { describe, expect, test } from "vitest";
import { lahiriAyanamsha, tropicalToSidereal } from "../src/lib/sidereal.ts";

describe("lahiriAyanamsha", () => {
  test("at J2000 returns 23°51'12\" (~23.85°)", () => {
    const value = lahiriAyanamsha(new Date("2000-01-01T12:00:00Z"));
    expect(value).toBeCloseTo(23 + 51 / 60 + 12 / 3600, 3);
  });

  test("drifts by ~50.27 arcseconds per year (precession)", () => {
    const a2000 = lahiriAyanamsha(new Date("2000-01-01T00:00:00Z"));
    const a2010 = lahiriAyanamsha(new Date("2010-01-01T00:00:00Z"));
    const drift = a2010 - a2000;
    // 10 years * 50.27"/yr = ~502.7" = ~0.1396°. Allow ~5%.
    expect(drift).toBeGreaterThan(0.13);
    expect(drift).toBeLessThan(0.15);
  });

  test("for a 1990 birth gives ~23.7°", () => {
    const value = lahiriAyanamsha(new Date("1990-06-15T12:30:00Z"));
    expect(value).toBeGreaterThan(23.65);
    expect(value).toBeLessThan(23.78);
  });

  test("for a 2026 chart gives ~24.2°", () => {
    const value = lahiriAyanamsha(new Date("2026-01-01T00:00:00Z"));
    expect(value).toBeGreaterThan(24.15);
    expect(value).toBeLessThan(24.25);
  });
});

describe("tropicalToSidereal", () => {
  test("subtracts the ayanamsha and wraps into [0, 360)", () => {
    expect(tropicalToSidereal(100, 24)).toBeCloseTo(76, 6);
    expect(tropicalToSidereal(10, 24)).toBeCloseTo(346, 6);
    expect(tropicalToSidereal(0, 24)).toBeCloseTo(336, 6);
  });

  test("preserves angular separation between planets", () => {
    // Two planets 90° apart in tropical stay 90° apart in sidereal.
    const aT = 100;
    const bT = 190;
    const ayanamsha = 23.85;
    const aS = tropicalToSidereal(aT, ayanamsha);
    const bS = tropicalToSidereal(bT, ayanamsha);
    const sepTropical = (bT - aT + 360) % 360;
    const sepSidereal = (bS - aS + 360) % 360;
    expect(sepSidereal).toBeCloseTo(sepTropical, 6);
  });
});
