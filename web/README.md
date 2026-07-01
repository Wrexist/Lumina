# web/ — Associated Domains hosting artifact

This folder holds static content that needs to be published at the
`lumina.app` domain root once real hosting exists. It is **not** itself a
web server or a deployable site — it's the source-of-truth content for one
file (today) that a future static host (or the same one serving the Phase 15
`/privacy`, `/terms`, `/press` pages) needs to publish byte-for-byte.

## `apple-app-site-association`

Must be deployed so that it is reachable at exactly:

```
https://lumina.app/.well-known/apple-app-site-association
```

Notes on serving it correctly (Apple's fetcher is strict about all of these):

- **Path matters.** The file in this repo is named `apple-app-site-association`
  with no extension — that's intentional, it's exactly how Apple requires it
  to be served. The file itself lives in this repo's `web/` folder for
  version control; the *deployed* URL adds the `.well-known/` path prefix
  that isn't present here.
- **HTTPS only**, valid certificate.
- **`Content-Type: application/json`** is the safe recommendation. Apple's
  CDN fetches the file directly and is lenient about content-type, but there
  is no reason not to serve it correctly.
- **No redirects.** Apple's fetcher does not follow HTTP redirects (not even
  a 301/302 to the same content) — the file must be served directly from
  that exact URL with a `200`.

## Current status: blocked

This can't take effect until the `lumina.app` domain + hosting exists — a
known, pre-existing blocker (see `TASK.md` Blockers table and
`docs/CAPABILITIES-PLAN.md` §4). It's the same blocker sitting in front of
the Phase 15 privacy-policy/terms-of-service pages, so all of these are worth
shipping as one small static-site deliverable rather than separately.

Once it's live: Apple's CDN caches the AASA file aggressively, so changes
(e.g. adding a new path pattern) can take real time to propagate to devices.
Don't expect an edit to take effect immediately when testing.
