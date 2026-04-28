Generate a test ephemeris chart JSON from the local Swiss Ephemeris backend.

Usage: /chart [--date "YYYY-MM-DD"] [--time "HH:MM"] [--place "City, Country"]

Default test case (if no args given): 1990-06-15, 14:30, Stockholm Sweden

```bash
cd backend && npm run chart -- --date "$ARGUMENTS_DATE" --time "$ARGUMENTS_TIME" --place "$ARGUMENTS_PLACE"
```

If the backend is not running, start it first:
```bash
cd backend && npm run dev
```

The backend must be running on :3001. Output is structured JSON with planets, houses, and aspects — pipe to Claude for interpretation testing.
