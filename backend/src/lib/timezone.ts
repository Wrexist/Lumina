/**
 * Time-zone helpers built on the platform `Intl` database — no external
 * dependency. Used to resolve wall-clock local times (and the noon-local
 * convention for unknown birth times) to absolute UTC instants.
 *
 * The backend otherwise treats `birthTime` as an absolute instant (the iOS
 * client encodes a `Date`, which is already UT-correct). These helpers exist
 * for the two cases where a wall-clock time must be interpreted in a zone:
 *   1. the unknown-birth-time noon convention (`noonLocalAsUTC`), and
 *   2. the CLI, which accepts a human `--time` in a `--tz`.
 */

export interface CalendarParts {
  readonly year: number;
  readonly month: number; // 1-12
  readonly day: number;
}

export interface WallClock extends CalendarParts {
  readonly hour: number;
  readonly minute: number;
  readonly second: number;
}

function partValue(parts: Intl.DateTimeFormatPart[], type: Intl.DateTimeFormatPartTypes): number {
  return Number(parts.find((p) => p.type === type)?.value);
}

/** True when `timeZone` is a resolvable IANA identifier. */
export function isValidTimeZone(timeZone: string): boolean {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone });
    return true;
  } catch {
    return false;
  }
}

/** Calendar Y/M/D of `instant` as observed in `timeZone`. */
export function calendarPartsInZone(instant: Date, timeZone: string): CalendarParts {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(instant);
  return {
    year: partValue(parts, "year"),
    month: partValue(parts, "month"),
    day: partValue(parts, "day"),
  };
}

/** Milliseconds `timeZone` is ahead of UTC at `instant` (negative when behind). */
export function zoneOffsetMs(instant: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(instant);
  const asUTC = Date.UTC(
    partValue(parts, "year"),
    partValue(parts, "month") - 1,
    partValue(parts, "day"),
    partValue(parts, "hour") % 24,
    partValue(parts, "minute"),
    partValue(parts, "second"),
  );
  return asUTC - instant.getTime();
}

/**
 * Resolve a wall-clock local time in `timeZone` to a UTC `Date`. Two
 * correction passes converge across the rare DST boundary where the offset
 * at the naive guess differs from the offset at the resolved instant.
 */
export function wallTimeToUTC(wall: WallClock, timeZone: string): Date {
  const naive = Date.UTC(wall.year, wall.month - 1, wall.day, wall.hour, wall.minute, wall.second);
  let utc = naive;
  for (let pass = 0; pass < 2; pass += 1) {
    utc = naive - zoneOffsetMs(new Date(utc), timeZone);
  }
  return new Date(utc);
}

/**
 * Noon *local* time on the calendar date of `instant`, returned as a UTC
 * `Date`. This is the astrological convention for unknown birth times —
 * noon in the birth locality, not noon UTC. Falls back to noon UTC when the
 * zone id is unresolvable so a bad identifier never throws.
 */
export function noonLocalAsUTC(instant: Date, timeZone: string): Date {
  if (!isValidTimeZone(timeZone)) {
    const utcNoon = new Date(instant.getTime());
    utcNoon.setUTCHours(12, 0, 0, 0);
    return utcNoon;
  }
  const { year, month, day } = calendarPartsInZone(instant, timeZone);
  return wallTimeToUTC({ year, month, day, hour: 12, minute: 0, second: 0 }, timeZone);
}
