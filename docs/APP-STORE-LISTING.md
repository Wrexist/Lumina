# App Store Listing — Copy-Paste Pack (ASO-optimized)

Everything you need to paste into App Store Connect, pre-fit to Apple's field
limits. Fields are ordered as they appear in ASC. Brand voice: premium,
editorial, honest — **no emojis** (on-brand and avoids looking spammy).

> ASO model: App Store search indexes **App Name + Subtitle + Keywords** (and
> the IAP display names). Apple then *recombines* individual keyword tokens into
> phrases. So we never repeat a word across those fields — every field adds new
> tokens, maximizing the phrase surface. Rationale notes are inline.

---

## App Name — 30 char limit

```
Lumina: Astrology & Palm
```
(24 chars.) Brand + the two head terms. If "Lumina" collides at submission
(names are globally unique), fallbacks, in order:
```
Lumina — Astrology & Palm
Lumina: Birth Chart & Palm
Lumina Astrology & Palmistry
```

## Subtitle — 30 char limit

```
Real birth charts & palmistry
```
(29 chars.) Adds `birth`, `charts`, `palmistry` to the index, and "Real"
carries the brand promise. Apple combines with the name → "astrology birth
chart", "palm reading", etc.

## Keywords — 100 char limit (comma-separated, NO spaces)

```
horoscope,zodiac,natal,tarot,moon,transit,compatibility,synastry,human,design,star,sign,cosmic
```
(94 chars.) Rules applied:
- **No spaces after commas** — every character is keyword budget.
- **No word repeated** from the name/subtitle (`astrology`, `palm`, `birth`,
  `chart`, `real` are already indexed).
- **Split multi-word phrases into tokens** — `human`,`design` and `star`,`sign`
  let Apple form "human design" and "star sign" itself. Same for `natal`(+chart
  from subtitle), `moon`(+phase), etc.
- Singular only — Apple stems plurals automatically (`chart`→`charts`).

## Promotional Text — 170 char limit (editable anytime, no review)

```
Real planetary math. Every word grounded in your actual chart — never generic, never hallucinated. Finally, a real one.
```
(121 chars.) Use this slot for campaigns/seasonal hooks — it updates instantly
without a new build. Swap in a palm-reading line once that feature actually
ships (see the note on the Description section below — don't claim it early).

---

## Description — 4000 char limit

```
Finally, an astrology app that doesn't fake it.

Every other app in this category either invents your planetary positions, fakes "palm reading" with a stock animation, or buries you in dark-pattern billing. Lumina does none of that.

WHAT MAKES LUMINA DIFFERENT

Real astronomy, not guesses. Your birth chart is computed from a genuine ephemeris — the same planetary math astronomers use — not approximated by an algorithm guessing at the sky. Degrees, houses, aspects: all exact.

Palm reading, built honestly. We're building on-device palm reading — real line detection that never uploads your photo — and won't ship it until it's actually accurate across every skin tone. No stock overlay standing in as a placeholder in the meantime.

Grounded interpretations, never hallucinated. Every reading is tied to your specific placements and today's real transits — the planet, the sign, the house, the exact angle. If a line of text can't be traced back to your chart, we don't write it.

WHAT YOU GET

• Today — a daily reading grounded in the transits actually happening to your chart, plus the live moon phase and its ritual, retrogrades, and what's coming next.
• Birth Chart — an interactive natal wheel. Tap any planet for a reading rooted in its real placement. See your Big Three, your dominant element, and what makes your chart genuinely rare.
• Cosmic Signature widget — your Sun, Moon, and Rising, right on your home screen.
• Compatibility — real synastry and composite charts for you and the people in your life, with shareable results.
• Human Design — your bodygraph and defined centers.
• Reflect — a journal with prompts tied to your current transits, so the questions actually fit the moment.
• Palm Reading (in progress) — see exactly where we are with it, in the app, right now.

HONEST BY DESIGN

• No fake data. No stock-clipart palmistry. No hallucinated horoscopes.
• Transparent, Apple-native billing. Monthly and annual only — no predatory weekly traps.
• Privacy first, including what's still in progress — your palm photo will never leave your device once palm reading ships.

Lumina is for people who love astrology and are tired of apps that treat it like a gimmick. Real charts. Real readings. Finally, a real one.

SUBSCRIPTION

Lumina Premium unlocks the full experience.
• Monthly and annual plans available.
• Payment is charged to your Apple ID at confirmation of purchase.
• Subscriptions renew automatically unless auto-renew is turned off at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.
• Any unused portion of a free trial is forfeited when you purchase a subscription.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://wrexist.github.io/Lumina/privacy.html
```

> Paste-time checks: the two URLs at the bottom are **required** by Apple when
> you have auto-renewable subscriptions (Guideline 3.1.2). The Privacy URL
> points at the real page in `docs/privacy.html` (see `docs/WEBSITE.md` for
> the one-time Pages setup) — swap in a custom domain there if you set one up.
> Terms of Use uses Apple's standard EULA since there's no custom Terms page
> built; write one and link it here instead if you need custom terms.
>
> **Palm reading claim check:** as of this writing, palm capture isn't live —
> the Palm tab shows an honest "coming soon" screen. The copy above is written
> to match that (a differentiator described as in-progress, not a shipped
> feature). Apple review tests that description claims match actual app
> behavior, so **before submitting, re-read this section and confirm it still
> matches reality** — either keep the "in progress" framing, or rewrite the
> palm paragraph/bullet to present tense once camera capture actually ships.

---

## What's New (release notes) — first release

```
The first Lumina. Real charts computed from a genuine ephemeris, and interpretations grounded in your actual placements — never generic, never faked.

• Your birth chart, exact to the degree
• A daily reading tied to today's real transits
• Compatibility, Human Design, a transit-aware journal
• Your Sun, Moon, and Rising on a home-screen widget
• On-device palm reading, in progress — see where it stands in the Palm tab

Finally, a real one.
```

---

## Categories

- **Primary: Lifestyle** — where the category leaders (Co-Star, CHANI) sit;
  best discovery for astrology.
- **Secondary: Entertainment** — widens reach. (Alternative: Health & Fitness
  if you lean the wellness/journal angle harder.)

## Age Rating

**12+** is the typical, safe rating for this category (astrology/"Infrequent
Mild Mature/Suggestive Themes" via fortune-telling references). Answer the ASC
questionnaire honestly; there's no objectionable content, so 12+ should be the
computed result. Not 4+ because of the fortune-telling/mysticism themes.

## Copyright

```
2026 Lumina
```

## URLs

| Field | Value | Required? |
|---|---|---|
| Support URL | `https://wrexist.github.io/Lumina/support.html` | Yes (must resolve) |
| Marketing URL | `https://wrexist.github.io/Lumina/` | Optional |
| Privacy Policy URL | `https://wrexist.github.io/Lumina/privacy.html` | Yes |

> These are the real pages in `docs/` — see `docs/WEBSITE.md` for the
> one-time GitHub Pages setup required before they resolve. Swap in a custom
> domain there later if you set one up; update these three rows to match.

---

## In-App Purchases (RevenueCat → App Store Connect)

Monthly + annual only (no weekly — Apple is actively enforcing against weekly
"fleeceware" in this category). Reference display names + review descriptions:

| Product | Reference Name | Display Name | Description (review-facing) |
|---|---|---|---|
| Monthly auto-renewable | `Lumina Premium Monthly` | `Lumina Premium (Monthly)` | Full access to every reading, chart, and premium feature, billed monthly. |
| Annual auto-renewable | `Lumina Premium Annual` | `Lumina Premium (Annual)` | Full access to every reading, chart, and premium feature, billed yearly at the best value. |

> Add "palm scan" back into these descriptions once palm reading actually
> ships and is part of what a subscriber's payment unlocks.

Subscription group: `Lumina Premium`. Optionally offer an introductory free
trial on the annual plan (one soft discount-rescue at 30% off is already the
in-app paywall strategy — keep the store IAPs clean: monthly + annual).

---

## Screenshots — order + captions (the real conversion driver)

Screenshots convert more than text. Lead with the differentiator. Required:
6.9" (iPhone 16 Pro Max) and 6.5"; others scale. Recommended order + overlay
caption (keep captions short, editorial, no emoji):

1. **Birth Chart wheel** — "Your chart, exact to the degree."
2. **Ask your chart** — "Real answers. Straight from your placements."
3. **Today / daily reading** — "Grounded in today's real transits."
4. **Cosmic Signature (Big Three)** — "Meet your cosmic signature."
5. **Compatibility result** — "See how you actually match."
6. **Brand close (no device — tagline card)** — "No fake data. Finally, a real one."

Rendered device-framed compositions for this exact order live in
`marketing/app-store-screenshots/`. Palm reading is deliberately **not** one
of the six — it isn't shipped yet (see the Description note above), and an
App Store screenshot showing a live camera/trace that doesn't exist is exactly
the kind of misleading-screenshot rejection Apple review looks for. Add a palm
screenshot once camera capture actually ships.

Tips to maximize installs:
- First 1–2 shots must sell in-thumbnail (most users never swipe). Put the
  strongest, most visually distinct differentiator up front — the chart wheel
  earns that slot until palm reading ships, then re-evaluate.
- Use a **custom product page** variant that leads with Compatibility for
  relationship-search keywords, and another leading with Chart for astrology
  keywords — test which converts.
- Add an **App Preview video** (15–30s) once there's a genuinely live moment
  worth showing in motion — the chart wheel rendering, or the future palm
  trace once it ships. Don't preview a feature that isn't real yet.

---

## App Review notes (Review Information field)

```
Lumina computes astrology charts from a self-hosted ephemeris service. LLM interpretations are grounded in those computed chart facts and generated server-side. No account is required to explore; premium features are gated by a RevenueCat subscription (sandbox-testable). The Palm tab intentionally shows an in-progress state, not a bug — on-device camera-based palm reading (Vision + Core ML; the photo will never leave the device) is still in accuracy testing and is described in the app as coming soon rather than shipped.
```

> Update this note once palm reading ships — remove the "intentionally
> in-progress" explanation and describe the real camera flow instead.

Provide a **demo walkthrough** and, if any feature needs auth, a sandbox/demo
account. Ensure the Support + Privacy URLs resolve, or review will reject.

---

## Launch ASO checklist (maximize downloads)

- [ ] Name + subtitle + keywords entered exactly as above (verify no field
      over its limit after paste — quotes/spaces can sneak in).
- [ ] Localize at least the **Name, Subtitle, Keywords** for your top markets
      (each localization is a *separate* 100-char keyword field = more index
      coverage). Start with English (U.S.), then English (U.K.), Spanish (MX),
      Portuguese (BR) if targeting those.
- [ ] App Preview video of a genuinely live moment (chart wheel rendering is
      a good candidate today; add the palm trace once it ships).
- [ ] Custom product pages: one Compatibility-led, one Chart-led.
- [ ] In-App Events (e.g. "New Moon in [sign] ritual") — these surface in
      search and on your product page and drive seasonal installs.
- [ ] Ratings prompt via SKStoreReviewController, fired after a *positive*
      moment (a completed reading), not on launch.
- [ ] Seasonal Promotional Text swaps (retrogrades, eclipses, new year) — no
      build needed.
- [ ] Keep the first screenshot and icon A/B-testable via Product Page
      Optimization once you have traffic.
