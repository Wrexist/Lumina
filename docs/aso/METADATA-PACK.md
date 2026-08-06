# App Store metadata pack — everything, in submission order

Copy-paste ready. Fields appear in the order App Store Connect asks for them.

**The text fields are not stored here.** They live in
[`metadata/app-store.json`](../../metadata/app-store.json), which CI validates
on every change. To get the blocks with their character counts:

```sh
python3 scripts/aso_lint.py --print   # paste-ready
python3 scripts/aso_lint.py           # validate after any edit
```

Editing the JSON and re-running is always right. Editing a value pasted into
this file is always wrong — it will drift, and nothing checks it.

Reasoning behind the keyword choices: [`KEYWORD-RESEARCH.md`](./KEYWORD-RESEARCH.md).

---

## 1. App Information (set once, hard to change later)

| Field | Value | Note |
|---|---|---|
| Bundle ID | `app.lumina.ios` | Must match `project.yml` |
| SKU | `lumina-ios-1` | Internal only, never shown |
| Primary Language | English (U.S.) | |
| Primary Category | **Lifestyle** | Where every astrology app of this shape lives |
| Secondary Category | **Reference** | Deliberately not Entertainment: Reference is a thinner Top Charts surface, and the glossary/house-system depth genuinely fits it |
| Age Rating | **4+** | See §7 |
| Content Rights | Does not contain, show, or access third-party content | The chart maths is computed, the art is generated for this app |

**Name collision plan.** App names are globally unique. If "Lumina: Birth
Chart Astrology" is taken at submission, in order of preference:

1. `Lumina — Birth Chart Astrology` (em dash, 29)
2. `Lumina Birth Chart & Transits` (29)
3. `Lumina: Real Birth Chart` (24)

Every fallback keeps `birth` + `chart` in the name; that is the part doing the
work, not the punctuation.

---

## 2. The indexed fields

Run `python3 scripts/aso_lint.py --print` for the exact strings. Summary:

| Field | Chars | Value |
|---|---|---|
| App Name | 29/30 | `Lumina: Birth Chart Astrology` |
| Subtitle | 30/30 | `Daily transits, moon, synastry` |
| Keywords (en-US) | 97/100 | `horoscope,natal,zodiac,rising,human,design,forecast,retrograde,ephemeris,saturn,return,phase,sign` |
| Keywords (es-MX) | 94/100 | `aspects,houses,composite,placidus,sidereal,ascendant,venus,mars,mercury,ritual,journal,tracker` |
| Keywords (en-GB) | 97/100 | `star,lunar,eclipse,solar,planet,degree,orb,report,reading,guide,calendar,planner,insight,sky,cusp` |

**How to add the extra keyword fields.** In ASC → your app → the version →
the language dropdown at the top right → **Add Language** → Spanish (Mexico)
and English (U.K.). Fill in *only* the keyword field for each; leave the name,
subtitle and description inheriting from en-US. This is a five-minute change
that nearly triples indexed keyword space.

---

## 3. Promotional Text, Description, What's New

All three in the JSON; `--print` emits them.

- **Promotional Text** (126/170) sits above the description and — uniquely —
  can be changed *without submitting a build or waiting for review*. Use it
  for anything time-bound: "Mercury goes retrograde Friday — see exactly what
  it touches in your chart." Never put anything permanent here.
- **Description** (2,727/4,000) is not indexed by App Store search; it exists
  to convert someone already looking. The first three lines are what shows
  before "more", so the argument is front-loaded.
- **What's New** (531/4,000) — for 1.0, tell people what the app is; nobody
  has a previous version to diff against.

---

## 4. In-App Purchases

IAP display names and descriptions are shown at the point of purchase, and are
widely reported to be indexed for search — which is why they carry real terms
rather than "Monthly Plan".

| Reference name | Display name (30) | Description (45) |
|---|---|---|
| Lumina Plus Monthly | `Plus: Human Design & Synastry` | `Human Design, synastry, forecast, widget.` |
| Lumina Plus Annual | `Plus Yearly: Full Chart Access` | `One year of everything in Lumina Plus.` |

Both need a review screenshot of the paywall, and both must be submitted
*with* the first build — an app whose IAPs are still "Missing Metadata" gets
rejected for an unpurchasable subscription.

Pricing, free trial and the introductory offer are configured in ASC, not
here; whatever you choose, the paywall's displayed price must match what
StoreKit charges (that mismatch was a P0 in the audit and is now driven from
the RevenueCat offering).

---

## 5. App Review Information

Full text in the JSON (`review.notes`); the short version of what it tells the
reviewer:

- The app needs network access — charts come from a backend, so a reviewer on
  a blocked network sees error states rather than content.
- Demo birth data that populates every screen: **14 March 1990, 09:25,
  Stockholm, Sweden**.
- Where to find the subscription (three entry points, plus Restore).
- Where in-app account deletion is (Guideline 5.1.1(v)).
- That the app does **not** read palms, that nothing in the binary claims it
  does, and that the FAQ says so — pre-empting the one question earlier
  marketing invites.

**Demo account.** Sign in with Apple can't be exercised by a reviewer with a
shared account, so provide an email/password test account in ASC and confirm
it works on a clean install before submitting.

---

## 6. Privacy

Answers and their justification: [`PRIVACY-LABELS.md`](./PRIVACY-LABELS.md).
They are derived from `PrivacyInfo.xcprivacy` and must not contradict it.

Privacy Policy URL is required and must resolve **before** you submit — a 404
there is an automatic rejection, and the domain step is the one most likely to
be half-finished (`LAUNCH-STEPS.md` Step 4).

---

## 7. Age Rating

Apple replaced the old 4+/9+/12+/17+ tiers with **4+, 9+, 13+, 16+, 18+** in
2025 and added questions about in-app controls. Lumina's answers are "None"
across violence, sexual content, profanity, gambling, drugs, horror and
user-generated content; there is no chat, no messaging, no web browser, no
ads. Result: **4+**.

Two questions people get wrong here:

- **"Does your app contain fortune telling?"** — Apple's rating flow has
  historically asked about "Horror/Fear Themes" and "Mature/Suggestive
  Themes", not fortune telling. Astrology framed as reflection and labelled
  for entertainment rates 4+; this is consistent with how the category's
  largest apps are rated. If the current questionnaire asks anything about
  fortune telling or the occult, answer it truthfully — a wrong rating is
  worse than a higher one.
- **"Unrestricted web access?"** — No. Links open in Safari, which is not the
  same thing.

---

## 8. URLs

| Field | Value | Required |
|---|---|---|
| Marketing URL | `https://wrexist.github.io/Lumina/` | Optional but always fill it |
| Support URL | `https://wrexist.github.io/Lumina/support.html` | **Required** |
| Privacy Policy URL | `https://wrexist.github.io/Lumina/privacy.html` | **Required** |
| Copyright | `2026 Lumina` | |

These point at GitHub Pages rather than `lumina.app`, deliberately: the custom
domain is Step 10 of the launch runbook and is not on the critical path. A
working Pages URL beats a pending DNS record. When the domain lands, update
these, `web/apple-app-site-association`, and the in-app links together.

Every URL in this table must return 200 before submission — `web-tests/`
checks exactly this; run it against the live site once Pages is on.

---

## 9. Screenshots

Storyboard, captions, sizes and the preview-video script:
[`SCREENSHOTS.md`](./SCREENSHOTS.md).

---

## 10. Submission checklist

Ordered so that nothing waits on something later in the list.

- [ ] Backend deployed and `/health` returns ok (`LAUNCH-STEPS.md` Step 2) — without it, every screen a reviewer opens is an error state
- [ ] GitHub Pages live; all three URLs above return 200
- [ ] `python3 scripts/aso_lint.py` passes
- [ ] Name, subtitle, both extra keyword localizations entered
- [ ] Description, promo text, What's New pasted
- [ ] Six 6.9" screenshots uploaded, captions matching `SCREENSHOTS.md`
- [ ] Both IAPs created, priced, screenshotted, and attached to the build
- [ ] Privacy labels entered to match `PrivacyInfo.xcprivacy`
- [ ] Age rating questionnaire completed → 4+
- [ ] Review notes and demo account filled in
- [ ] Build uploaded from the TestFlight lane and processed
- [ ] Export compliance answered (`ITSAppUsesNonExemptEncryption: false` is
      already in the Info.plist, so this should not even be asked)
- [ ] Phased release **on** — it costs nothing and buys a kill switch
