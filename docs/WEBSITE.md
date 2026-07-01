# Website — Setup & Structure

The marketing site (`website/`) is a static, dependency-free site — no build
step, no framework, no npm install. Three pages: home, Support, Privacy. It's
required for App Store Connect's Support URL and Privacy Policy URL (see
`docs/APP-STORE-LISTING.md`).

---

## One-time setup (you must do this — can't be done via a workflow file)

1. Repo → **Settings → Pages**.
2. Under **Build and deployment → Source**, choose **GitHub Actions** (not
   "Deploy from a branch").
3. Push to `main` with changes under `website/` (or run the **pages** workflow
   manually from the Actions tab) — it builds and publishes automatically from
   then on.

Once enabled, the site is live at:

```
https://wrexist.github.io/Lumina/
```

(A project page, not a user/org page, since the repo isn't named
`wrexist.github.io`.) Update the placeholder `https://lumina.app/...` URLs in
`docs/APP-STORE-LISTING.md` and anywhere else they appear once you know the
final URL — either this GitHub Pages URL, or a custom domain if you set one up
(below).

---

## Optional: custom domain

If you own a domain (e.g. `lumina.app`):

1. Add a `website/CNAME` file containing just the domain, e.g. `lumina.app`.
2. At your DNS provider, add a `CNAME` record pointing the subdomain (or an
   `ALIAS`/`ANAME`/`A` record set per
   [GitHub's apex-domain instructions](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
   for a root domain) at `wrexist.github.io`.
3. Repo → Settings → Pages → set the custom domain, enable **Enforce HTTPS**
   once the certificate provisions (can take up to 24h).

---

## Structure

```
website/
├── index.html          # Marketing / landing — 3D hero, differentiators, features, get-the-app
├── support.html         # FAQ + contact — the App Store Connect Support URL
├── privacy.html          # Privacy policy — the App Store Connect Privacy Policy URL
└── assets/
    ├── css/
    │   ├── tokens.css     # Brand colors/type/spacing as CSS custom properties
    │   ├── fonts.css       # Self-hosted @font-face rules
    │   └── style.css        # Everything else
    ├── fonts/               # Self-hosted Fraunces/Inter/JetBrains Mono (latin subset, ~230KB total)
    ├── js/
    │   ├── hero3d.js        # The 3D hero — see below
    │   └── main.js            # Scroll reveals, nav contrast swap
    ├── vendor/three/         # Vendored Three.js (see below)
    └── img/
        ├── brand/mark-1024.png   # The app icon, reused as the site's wordmark glyph
        └── screenshots/            # Real app screenshots (from CI), reused across the site
```

## Design notes

- **Colors, type, spacing mirror the native app's `Design/Tokens/`** — same
  hex values, same 8pt grid. The paid fonts (PP Editorial New / Söhne / GT
  America Mono) aren't cleared for web embedding, so the site uses free,
  visually-similar equivalents instead: **Fraunces** (editorial serif italic,
  in place of PP Editorial New), **Inter** (clean grotesque, in place of
  Söhne), **JetBrains Mono** (in place of GT America Mono). Self-hosted via
  the `@fontsource` npm packages (latin subset only, ~230KB total) rather than
  a Google Fonts CDN request — one less third-party dependency, and it keeps
  working if that CDN ever has an outage.
- **The 3D hero** (`hero3d.js`) is hand-written Three.js: real app screenshots
  mapped onto floating rounded panels, drifting slowly among a starfield, with
  subtle mouse-parallax. It mirrors the native app's own motion language (slow
  gyroscope star parallax, no spring bounce). Three.js is **vendored locally**
  (`assets/vendor/three/`, MIT-licensed, see the adjacent `LICENSE` file) —
  not loaded from a CDN — so the hero doesn't depend on a third party being up
  either. It degrades gracefully in three cases, all handled explicitly: the
  visitor has `prefers-reduced-motion` set, their browser lacks WebGL, or the
  local module fails to load for any reason — each falls back to a single
  static screenshot, never a blank hero.
- **No tracking of any kind.** No analytics, no ad pixels, no cookies. Stated
  plainly on the Privacy page — the site should hold itself to the same
  standard the app's marketing claims about itself.
- **Palm reading is described honestly as in-progress**, not shipped — see the
  note in `docs/APP-STORE-LISTING.md`. The Palm feature card on the homepage
  and its screenshot deliberately show the app's own "coming soon" screen
  rather than overclaiming a live camera feature. Update that copy once palm
  capture actually ships.

## Local preview (no server needed beyond a static file server)

```bash
cd website && python3 -m http.server 8000
# open http://localhost:8000
```
