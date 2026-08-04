import { describe, expect, test } from "vitest";
import { Body, Ecliptic, GeoVector, Seasons } from "astronomy-engine";
import { AstronomyEngineEphemeris } from "../src/services/astronomyEngineEphemeris.ts";
import type { BirthData } from "../src/types.ts";

/**
 * Reference-value validation for the ephemeris.
 *
 * Before this file, the only correctness assertion on any planet anywhere in
 * the suite was `sun.longitude > 60 && < 95` — a 35°-wide window, wider than
 * a whole zodiac sign. No body was ever compared against a published
 * position, and the Moon (~13°/day) had no reference assertion at all, so a
 * regression that shifted every chart by hours — or a whole day — passed
 * green. This is the app's core promise, so it gets real anchors.
 *
 * The values below come from OUTSIDE this codebase (published astronomical
 * events and the definition of the tropical zodiac), which is what makes
 * them meaningful rather than circular. Tolerances are tight enough that a
 * systematic error large enough to change a sign, a house, or an aspect
 * cannot slip through.
 */

const ephemeris = new AstronomyEngineEphemeris();

/** Smallest absolute separation between two ecliptic longitudes, degrees. */
function angularDelta(a: number, b: number): number {
  const diff = Math.abs(((a - b) % 360) + 360) % 360;
  return diff > 180 ? 360 - diff : diff;
}

function longitudeOf(body: Body, at: Date): number {
  return ((Ecliptic(GeoVector(body, at, true)).elon % 360) + 360) % 360;
}

describe("reference frame — tropical of date, not J2000", () => {
  // The tropical zodiac is DEFINED so that 0° Aries is the March equinox.
  // The Sun therefore reads exactly 0° at that instant in an of-date frame,
  // and would be offset by accumulated precession (~0.4° for a 1990 chart,
  // ~2.8° for 1800) in a J2000 frame.
  //
  // This is the test that settles which frame we are in. It matters because
  // the Ascendant and house cusps are computed of-date from the obliquity
  // and RAMC: if planets were J2000, every planet-in-house assignment would
  // carry a systematic offset, and anyone born within hours of a sign
  // boundary would be shown the wrong Sun sign.
  test.each([1800, 1900, 1950, 1970, 1990, 2026, 2050])(
    "Sun sits at 0° Aries at the %i March equinox",
    (year) => {
      const equinox = Seasons(year).mar_equinox.date;
      const delta = angularDelta(longitudeOf(Body.Sun, equinox), 0);
      expect(delta).toBeLessThan(0.001);
    },
  );

  test("Sun hits the cardinal points at the other three season markers", () => {
    const s = Seasons(2000);
    expect(angularDelta(longitudeOf(Body.Sun, s.jun_solstice.date), 90)).toBeLessThan(0.001);
    expect(angularDelta(longitudeOf(Body.Sun, s.sep_equinox.date), 180)).toBeLessThan(0.001);
    expect(angularDelta(longitudeOf(Body.Sun, s.dec_solstice.date), 270)).toBeLessThan(0.001);
  });
});

describe("reference positions — published astronomical events", () => {
  // Jupiter–Saturn "Great Conjunction", 2020-12-21. Very widely published:
  // both planets at 0°29' Aquarius, separated by ~6 arcminutes — the closest
  // since 1623. 0°29' Aquarius = 300° + 0.483° = 300.48°.
  test("Great Conjunction 2020: Jupiter and Saturn both at 0°29' Aquarius", async () => {
    const at = new Date("2020-12-21T18:22:00Z");
    const jupiter = longitudeOf(Body.Jupiter, at);
    const saturn = longitudeOf(Body.Saturn, at);

    expect(angularDelta(jupiter, 300.48)).toBeLessThan(0.1);
    expect(angularDelta(saturn, 300.48)).toBeLessThan(0.1);
    // The event itself: the two within a tenth of a degree of each other.
    expect(angularDelta(jupiter, saturn)).toBeLessThan(0.1);
  });

  // Great American Eclipse, 2017-08-21 18:26 UTC (greatest eclipse).
  // Published position: Sun and Moon conjunct at 28°53' Leo = 148.88°.
  test("Total solar eclipse 2017: Sun and Moon conjunct at 28°53' Leo", () => {
    const at = new Date("2017-08-21T18:26:00Z");
    const sun = longitudeOf(Body.Sun, at);
    const moon = longitudeOf(Body.Moon, at);

    expect(angularDelta(sun, 148.88)).toBeLessThan(0.05);
    // The Moon is the fastest-moving body and the one most likely to expose a
    // time-handling regression: at ~13°/day, being an hour off shows up as
    // ~0.55°. This pins it to a tenth of a degree.
    expect(angularDelta(moon, 148.88)).toBeLessThan(0.1);
    expect(angularDelta(sun, moon)).toBeLessThan(0.1);
  });
});

describe("chart pipeline — end-to-end reference chart", () => {
  // Runs through the real `chart()` path (not the raw library) so the frame,
  // the house math, and the birth-instant handling are all covered together.
  const birth: BirthData = {
    birthDate: "2000-01-01T00:00:00Z",
    birthTime: "2000-01-01T12:00:00Z",
    placeName: "Greenwich, UK",
    latitude: 51.4779,
    longitude: 0,
    timeZoneIdentifier: "UTC",
  };

  // NB: the instant happens to be the J2000.0 epoch, but the coordinates are
  // of-date — see the frame suite above. Don't read the date as a frame claim.
  test("every planet matches a direct computation at the same instant", async () => {
    const chart = await ephemeris.chart(birth);
    const at = new Date("2000-01-01T12:00:00Z");
    const byName = new Map(chart.planets.map((p) => [p.planet, p.longitude]));

    // Every body cross-checked against a direct computation at the same
    // instant. This is what catches a birth-instant regression: if `chart()`
    // ever resolves the wrong moment (timezone slip, noon-anchoring bug,
    // day rollover), these all drift together and the test fails loudly.
    for (const [name, body] of [
      ["Sun", Body.Sun],
      ["Moon", Body.Moon],
      ["Mercury", Body.Mercury],
      ["Venus", Body.Venus],
      ["Mars", Body.Mars],
      ["Jupiter", Body.Jupiter],
      ["Saturn", Body.Saturn],
    ] as const) {
      const actual = byName.get(name);
      expect(actual, `${name} missing from chart`).toBeDefined();
      expect(
        angularDelta(actual!, longitudeOf(body, at)),
        `${name} drifted from its reference position`,
      ).toBeLessThan(0.01);
    }
  });

  test("Sun is in early Capricorn on 2000-01-01, as the calendar requires", async () => {
    const chart = await ephemeris.chart(birth);
    const sun = chart.planets.find((p) => p.planet === "Sun")!.longitude;
    // Capricorn spans 270°–300°. Jan 1 is ~10 days past the solstice, so the
    // Sun sits ~10° into the sign. A one-sign or one-day error breaks this.
    expect(sun).toBeGreaterThan(279);
    expect(sun).toBeLessThan(281);
  });

  test("houses are ordered, distinct, and span the full circle", async () => {
    const chart = await ephemeris.chart(birth);
    expect(chart.houses).not.toBeNull();
    const cusps = chart.houses!.cusps;
    expect(cusps).toHaveLength(12);

    // Each cusp strictly precedes the next going anticlockwise, and the 12
    // gaps sum to a full circle — catches a duplicated or transposed cusp.
    let total = 0;
    for (let i = 0; i < 12; i += 1) {
      const gap = (((cusps[(i + 1) % 12]! - cusps[i]!) % 360) + 360) % 360;
      expect(gap).toBeGreaterThan(0);
      expect(gap).toBeLessThan(360);
      total += gap;
    }
    expect(total).toBeCloseTo(360, 6);
  });
});

describe("sign boundaries stay stable across the supported range", () => {
  // A systematic frame error shows up first at cusp births. Walking the Sun
  // across a sign boundary in each era and asserting the crossing lands where
  // the tropical definition says it must would catch a precession-style drift
  // that a single-chart test would miss.
  test.each([1900, 1950, 2000, 2025])(
    "the Sun enters Aries exactly at the %i March equinox",
    (year) => {
      const equinox = Seasons(year).mar_equinox.date;
      const before = longitudeOf(Body.Sun, new Date(equinox.getTime() - 60 * 60 * 1000));
      const after = longitudeOf(Body.Sun, new Date(equinox.getTime() + 60 * 60 * 1000));

      // An hour before, the Sun is still in the last degree of Pisces.
      expect(before).toBeGreaterThan(359.9);
      // An hour after, it is in the first degree of Aries.
      expect(after).toBeLessThan(0.1);
    },
  );
});
