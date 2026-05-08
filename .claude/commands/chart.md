Generate a test ephemeris chart JSON from the local backend.

Usage: /chart [--date "YYYY-MM-DD"] [--time "HH:MM"] [--tz "IANA/Zone"] [--place "City"] [--lat N] [--lon N]

Default test case (no args): 1990-06-15, 14:30, Europe/Stockholm, Stockholm Sweden.

```bash
cd backend && npm run chart -- \
  --date "${ARGUMENTS_DATE:-1990-06-15}" \
  --time "${ARGUMENTS_TIME:-14:30}" \
  --tz "${ARGUMENTS_TZ:-Europe/Stockholm}" \
  --place "${ARGUMENTS_PLACE:-Stockholm, Sweden}"
```

This calls the ephemeris service directly (no server boot needed). Output is `NatalChart` JSON: `calculatedAt`, `houseSystem`, and `planets[]` with longitude/latitude/isRetrograde for the ten major bodies. Houses, aspects, and transits are not yet implemented — see `backend/README.md` § "What's intentionally not here yet".

To exercise the HTTP path instead (auth, validation, route handler), boot the server:

```bash
cd backend && npm run dev   # http://127.0.0.1:3001
```
