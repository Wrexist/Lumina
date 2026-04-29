/**
 * CLI for the `/chart` slash command.
 *
 * Usage:
 *   npm run chart -- --date 1990-06-15 --time 14:30 --tz Europe/Stockholm \
 *                   [--lat 59.3293] [--lon 18.0686] [--place "Stockholm"]
 *
 * Defaults match the placeholder in `.claude/commands/chart.md`. Output is
 * pretty-printed JSON on stdout.
 */
import { parseArgs } from "node:util";
import { AstronomyEngineEphemeris } from "../src/services/astronomyEngineEphemeris.ts";
import { BirthDataSchema } from "../src/types.ts";

const { values } = parseArgs({
  options: {
    date: { type: "string", default: "1990-06-15" },
    time: { type: "string", default: "14:30" },
    tz: { type: "string", default: "Europe/Stockholm" },
    lat: { type: "string", default: "59.3293" },
    lon: { type: "string", default: "18.0686" },
    place: { type: "string", default: "Stockholm, Sweden" },
  },
});

const localBirthInstant = new Date(`${values.date}T${values.time}:00`);
if (Number.isNaN(localBirthInstant.getTime())) {
  console.error(`Invalid --date / --time: ${values.date} ${values.time}`);
  process.exit(2);
}

const birthData = BirthDataSchema.parse({
  birthDate: new Date(`${values.date}T00:00:00Z`).toISOString(),
  birthTime: localBirthInstant.toISOString(),
  placeName: values.place,
  latitude: Number(values.lat),
  longitude: Number(values.lon),
  timeZoneIdentifier: values.tz,
});

const ephemeris = new AstronomyEngineEphemeris();
const chart = await ephemeris.chart(birthData);
process.stdout.write(`${JSON.stringify(chart, null, 2)}\n`);
