import { describe, expect, test } from "vitest";
import { placidusHouses } from "../src/lib/houses.ts";

const STOCKHOLM = { lat: 59.3293, lon: 18.0686 };
const ATHENS = { lat: 37.9838, lon: 23.7275 };
const QUITO = { lat: -0.1807, lon: -78.4678 };
const LONGYEARBYEN = { lat: 78.2232, lon: 15.6267 };

const SAMPLE_INSTANT = new Date("1990-06-15T12:30:00Z");

function cusp(c: readonly number[], i: number): number {
  const value = c[((i % 12) + 12) % 12];
  if (value === undefined) throw new Error(`cusp ${i} missing`);
  return value;
}

function modSpan(from: number, to: number): number {
  return ((to - from) % 360 + 360) % 360;
}

describe("placidusHouses", () => {
  test("returns 12 cusps with house 1 == ascendant and house 10 == midheaven", () => {
    const houses = placidusHouses(SAMPLE_INSTANT, STOCKHOLM.lat, STOCKHOLM.lon);
    expect(houses.cusps).toHaveLength(12);
    expect(cusp(houses.cusps, 0)).toBeCloseTo(houses.ascendant, 6);
    expect(cusp(houses.cusps, 9)).toBeCloseTo(houses.midheaven, 6);
  });

  test("opposite-house cusps are exactly 180° apart", () => {
    const houses = placidusHouses(SAMPLE_INSTANT, STOCKHOLM.lat, STOCKHOLM.lon);
    for (let i = 0; i < 6; i += 1) {
      const diff = modSpan(cusp(houses.cusps, i), cusp(houses.cusps, i + 6));
      expect(diff).toBeCloseTo(180, 4);
    }
  });

  test("cusps are monotonically increasing modulo 360 starting at the ascendant", () => {
    const houses = placidusHouses(SAMPLE_INSTANT, ATHENS.lat, ATHENS.lon);
    let cumulative = 0;
    for (let i = 0; i < 12; i += 1) {
      const span = modSpan(cusp(houses.cusps, i), cusp(houses.cusps, i + 1));
      expect(span).toBeGreaterThan(0);
      expect(span).toBeLessThan(180);
      cumulative += span;
    }
    expect(cumulative).toBeCloseTo(360, 4);
  });

  test("equatorial latitude (Quito ~0°) gives near-equal house spans", () => {
    const houses = placidusHouses(SAMPLE_INSTANT, QUITO.lat, QUITO.lon);
    for (let i = 0; i < 12; i += 1) {
      const span = modSpan(cusp(houses.cusps, i), cusp(houses.cusps, i + 1));
      // At the equator Placidus collapses to ~30° per house with small
      // distortions from the obliquity of the ecliptic.
      expect(span).toBeGreaterThan(20);
      expect(span).toBeLessThan(45);
    }
  });

  test("polar latitude (Svalbard) falls back to whole-sign houses", () => {
    const houses = placidusHouses(SAMPLE_INSTANT, LONGYEARBYEN.lat, LONGYEARBYEN.lon);
    expect(houses.system).toBe("wholeSign");
    // Whole sign cusps land on multiples of 30° offset by the Asc sign start.
    const fractional = ((cusp(houses.cusps, 0) % 30) + 30) % 30;
    expect(fractional).toBeCloseTo(0, 6);
    for (let i = 1; i < 12; i += 1) {
      const span = modSpan(cusp(houses.cusps, i - 1), cusp(houses.cusps, i));
      expect(span).toBeCloseTo(30, 6);
    }
  });

  test("Stockholm 1990-06-15 14:30 CEST (= 12:30 UTC) — Asc in Libra, MC in Cancer", () => {
    const houses = placidusHouses(SAMPLE_INSTANT, STOCKHOLM.lat, STOCKHOLM.lon);
    // Reference values from astro.com / Swiss Ephemeris for the same
    // instant: Asc ≈ 12° Libra (192°), MC ≈ 17° Cancer (107°). Allow a
    // ~1° tolerance for the J2000-vs-of-date drift documented in
    // astronomyEngineEphemeris.ts.
    expect(houses.ascendant).toBeGreaterThan(190);
    expect(houses.ascendant).toBeLessThan(195);
    expect(houses.midheaven).toBeGreaterThan(104);
    expect(houses.midheaven).toBeLessThan(110);
  });
});
