# web-tests

Playwright checks for `docs/` — the pages GitHub Pages serves as the
**Marketing URL**, **Privacy Policy URL** and **Support URL** in App Store
Connect.

These are launch-blocking, not cosmetic: App Review loads the Privacy and
Support URLs, and a 404, a dead link, or a page that renders blank is a
rejection.

```bash
cd web-tests
npm install
npx playwright install chromium
npx playwright test
```

If the host already ships a Chromium (many CI images and sandboxes do), point
at it instead of downloading a second copy:

```bash
PLAYWRIGHT_CHROMIUM_PATH=/opt/pw-browsers/chromium-1194/chrome-linux/chrome npx playwright test
```

## What it checks

| Check | Why |
|---|---|
| HTTP 200, no console errors, no failed subresources | a broken asset is invisible until someone loads the page |
| A `<title>`, exactly one `<h1>`, no empty headings | structure reviewers and search engines read |
| Every internal link resolves | dead links on the Support URL are a rejection |
| No horizontal scroll at 390px | reviewers open these on a phone |
| Text ≥ 13px | the design charter's label floor |
| Privacy page names a contact route and a deletion path | Guideline 5.1.1(v) |
| Support page offers a way to reach a human | the Support URL's entire job |

## Found by this suite

- **The marketing page was invisible without JavaScript.** `.reveal { opacity: 0 }`
  was the unconditional default and only JS removed it, so every section below
  the hero stayed blank for anyone with scripts blocked. Now scoped to a `.js`
  class set by an inline script, so a browser that can't reveal content never
  hides it.
- **Palm reading was advertised in the page title, hero eyebrow and features
  grid** — the feature isn't in the binary (Guideline 2.3.1).
- Label text at 10.9–12px, under the charter's 13pt floor.
