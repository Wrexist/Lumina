import { describe, expect, test } from "vitest";
import {
  calendarPartsInZone,
  isValidTimeZone,
  noonLocalAsUTC,
  wallTimeToUTC,
  zoneOffsetMs,
} from "../src/lib/timezone.ts";

describe("isValidTimeZone", () => {
  test("accepts real IANA ids and rejects junk", () => {
    expect(isValidTimeZone("Europe/Stockholm")).toBe(true);
    expect(isValidTimeZone("Pacific/Auckland")).toBe(true);
    expect(isValidTimeZone("UTC")).toBe(true);
    expect(isValidTimeZone("Not/AZone")).toBe(false);
    expect(isValidTimeZone("")).toBe(false);
  });
});

describe("zoneOffsetMs", () => {
  test("Stockholm is +2h in June (CEST)", () => {
    const offset = zoneOffsetMs(new Date("1990-06-15T10:00:00Z"), "Europe/Stockholm");
    expect(offset).toBe(2 * 60 * 60 * 1000);
  });

  test("Stockholm is +1h in January (CET)", () => {
    const offset = zoneOffsetMs(new Date("1990-01-15T10:00:00Z"), "Europe/Stockholm");
    expect(offset).toBe(1 * 60 * 60 * 1000);
  });
});

describe("wallTimeToUTC", () => {
  test("noon Stockholm in summer resolves to 10:00 UTC", () => {
    const utc = wallTimeToUTC(
      { year: 1990, month: 6, day: 15, hour: 12, minute: 0, second: 0 },
      "Europe/Stockholm",
    );
    expect(utc.toISOString()).toBe("1990-06-15T10:00:00.000Z");
  });

  test("New York 14:30 in summer resolves to 18:30 UTC regardless of host TZ", () => {
    const utc = wallTimeToUTC(
      { year: 1990, month: 6, day: 15, hour: 14, minute: 30, second: 0 },
      "America/New_York",
    );
    expect(utc.toISOString()).toBe("1990-06-15T18:30:00.000Z");
  });
});

describe("noonLocalAsUTC", () => {
  test("uses the birth-zone calendar day, not the UTC day", () => {
    // Stockholm local midnight on 1990-06-15 is 22:00Z on the 14th.
    const instant = new Date("1990-06-14T22:00:00Z");
    const noon = noonLocalAsUTC(instant, "Europe/Stockholm");
    // Noon local on the 15th == 10:00Z on the 15th — not noon on the 14th.
    expect(noon.toISOString()).toBe("1990-06-15T10:00:00.000Z");
  });

  test("does not shift the calendar day for a far-east offset", () => {
    // NZ (+12 in June) local midnight on the 15th is 12:00Z on the 14th.
    const instant = new Date("1990-06-14T12:00:00Z");
    const parts = calendarPartsInZone(instant, "Pacific/Auckland");
    expect(parts).toEqual({ year: 1990, month: 6, day: 15 });
    const noon = noonLocalAsUTC(instant, "Pacific/Auckland");
    // Noon local on the 15th in NZ == 00:00Z on the 15th — the old
    // setUTCHours(12) bug produced noon on the 14th.
    expect(noon.toISOString()).toBe("1990-06-15T00:00:00.000Z");
  });

  test("falls back to noon UTC for an unresolvable zone", () => {
    const noon = noonLocalAsUTC(new Date("1990-06-14T22:00:00Z"), "Not/AZone");
    expect(noon.toISOString()).toBe("1990-06-14T12:00:00.000Z");
  });
});
