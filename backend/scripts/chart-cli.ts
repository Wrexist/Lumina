/**
 * CLI for the `/chart` slash command.
 *
 * Usage:
 *   npm run chart -- --date 1990-06-15 --time 14:30 --tz Europe/Stockholm \
 *                   [--lat 59.3293] [--lon 18.0686] [--place "Stockholm"] \
 *                   [--system placidus|wholeSign|sidereal]
 *
 * Defaults match the placeholder in `.claude/commands/chart.md`. Output is
 * pretty-printed JSON on stdout.
 */
import { parseArgs } from "node:util";
import { AstronomyEngineEphemeris } from "../src/services/astronomyEngineEphemeris.ts";
import { isValidTimeZone, wallTimeToUTC } from "../src/lib/timezone.ts";
import { BirthDataSchema, HouseSystemSchema } from "../src/types.ts";

const { values } = parseArgs({
  options: {
    date: { type: "string", default: "1990-06-15" },
    time: { type: "string", default: "14:30" },
    tz: { type: "string", default: "Europe/Stockholm" },
    lat: { type: "string", default: "59.3293" },
    lon: { type: "string", default: "18.0686" },
    place: { type: "string", default: "Stockholm, Sweden" },
    system: { type: "string", default: "placidus" },
  },
});

const dateArg = values.date ?? "";
const timeArg = values.time ?? "";
const tzArg = values.tz ?? "";

const dateParts = dateArg.split("-").map(Number);
const timeParts = timeArg.split(":").map(Number);
const partsFinite = [...dateParts, ...timeParts].every(Number.isFinite);
if (dateParts.length !== 3 || timeParts.length < 2 || !partsFinite) {
  console.error(`Invalid --date / --time: ${dateArg} ${timeArg}`);
  process.exit(2);
}
if (!isValidTimeZone(tzArg)) {
  console.error(`Invalid --tz: ${tzArg}`);
  process.exit(2);
}

// Interpret the human wall-clock --date/--time *in --tz* (not the host's
// local zone) and resolve to absolute UTC instants.
const [year, month, day] = dateParts as [number, number, number];
const [hour, minute] = timeParts as [number, number];
const birthDateUTC = wallTimeToUTC({ year, month, day, hour: 0, minute: 0, second: 0 }, tzArg);
const birthTimeUTC = wallTimeToUTC({ year, month, day, hour, minute, second: 0 }, tzArg);

const birthData = BirthDataSchema.parse({
  birthDate: birthDateUTC.toISOString(),
  birthTime: birthTimeUTC.toISOString(),
  placeName: values.place,
  latitude: Number(values.lat),
  longitude: Number(values.lon),
  timeZoneIdentifier: tzArg,
});

const ephemeris = new AstronomyEngineEphemeris();
const houseSystem = HouseSystemSchema.parse(values.system);
const chart = await ephemeris.chart(birthData, { houseSystem });
process.stdout.write(`${JSON.stringify(chart, null, 2)}\n`);
