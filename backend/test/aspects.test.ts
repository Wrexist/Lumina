import { describe, expect, test } from "vitest";
import { computeAspects } from "../src/lib/aspects.ts";
import type { PlanetPosition } from "../src/types.ts";

function planet(name: string, longitude: number, isRetrograde = false): PlanetPosition {
  return { planet: name, longitude, latitude: 0, isRetrograde };
}

describe("computeAspects", () => {
  test("identical longitudes are an exact conjunction (orb 0)", () => {
    const aspects = computeAspects([planet("Sun", 100), planet("Mars", 100)]);
    expect(aspects).toHaveLength(1);
    expect(aspects[0]).toMatchObject({
      planet1: "Sun",
      planet2: "Mars",
      type: "conjunction",
      exactAngle: 0,
    });
    expect(aspects[0]?.orb).toBeCloseTo(0, 6);
  });

  test("180° apart is an exact opposition", () => {
    const aspects = computeAspects([planet("Mars", 0), planet("Venus", 180)]);
    expect(aspects[0]?.type).toBe("opposition");
    expect(aspects[0]?.orb).toBeCloseTo(0, 6);
  });

  test("60°, 90°, 120° give sextile/square/trine", () => {
    const sextile = computeAspects([planet("Mars", 0), planet("Mercury", 60)]);
    const square = computeAspects([planet("Mars", 0), planet("Saturn", 90)]);
    const trine = computeAspects([planet("Mars", 0), planet("Jupiter", 120)]);
    expect(sextile[0]?.type).toBe("sextile");
    expect(square[0]?.type).toBe("square");
    expect(trine[0]?.type).toBe("trine");
  });

  test("Sun gets a wider orb for a square (8° instead of 6°)", () => {
    // 7.5° orb on a square: in-orb for Sun (8° luminary), out-of-orb for Saturn-Mars (6°).
    const withSun = computeAspects([planet("Sun", 0), planet("Mars", 97.5)]);
    const withoutSun = computeAspects([planet("Saturn", 0), planet("Mars", 97.5)]);
    expect(withSun).toHaveLength(1);
    expect(withSun[0]?.type).toBe("square");
    expect(withoutSun).toHaveLength(0);
  });

  test("out-of-orb pairs return no aspect", () => {
    // 11° from a square — beyond even the luminary 8° orb.
    const aspects = computeAspects([planet("Sun", 0), planet("Mars", 101)]);
    expect(aspects).toHaveLength(0);
  });

  test("longitude wraparound is handled (5° vs 355° → 10° apart, not 350°)", () => {
    const aspects = computeAspects([planet("Sun", 5), planet("Mars", 355)]);
    expect(aspects).toHaveLength(1);
    expect(aspects[0]?.type).toBe("conjunction");
    expect(aspects[0]?.orb).toBeCloseTo(10, 6);
  });

  test("each pair contributes at most one aspect (the closest)", () => {
    // 89° apart is in-orb for both square (1°) and… actually nothing else
    // is within 8°. Just verify no double-counting.
    const aspects = computeAspects([planet("Sun", 0), planet("Mars", 89)]);
    expect(aspects).toHaveLength(1);
  });

  test("aspects come back sorted ascending by orb (tightest first)", () => {
    const aspects = computeAspects([
      planet("Sun", 0),
      planet("Moon", 122),         // trine 120° + 2°
      planet("Mars", 90.5),        // square 90° + 0.5°
      planet("Mercury", 60.3),     // sextile 60° + 0.3°
    ]);
    for (let i = 1; i < aspects.length; i += 1) {
      const prev = aspects[i - 1];
      const cur = aspects[i];
      if (prev && cur) {
        expect(cur.orb).toBeGreaterThanOrEqual(prev.orb);
      }
    }
  });
});
