# DEV.md — Lumina iOS Session Handoff

> **READ THIS FIRST** at the start of every session.
> Update `TASK.md` and `LEARNINGS.md` at the end of every session.
>
> **This file describes the repository as it actually is.** Everything below
> was checked against the source tree. Aspirational features live in
> `ROADMAP.md`; open pre-launch work lives in `LAUNCH-READINESS.md`. If you
> find a claim here that the code doesn't back, fix the claim — a handoff doc
> that lies costs more than one with gaps.

---

## ⚡ Quick Context

| Item | Value |
|---|---|
| **State** | Pre-launch remediation — working the `LAUNCH-READINESS.md` punch list |
| **Active branch** | `claude/pre-launch-audit-checklist-7dwc53` |
| **Last updated** | 2026-08-04 |
| **Dev environment** | **No local macOS** — CI on `macos-15` / latest-stable Xcode is the only iOS build/test loop |
| **Blockers** | Owner actions only — see the table at the end of `LAUNCH-READINESS.md` (backend deploy, RevenueCat products, ASC metadata, domain + AASA hosting) |
| **Spec docs** | `LAUNCH-READINESS.md` (what's left before launch) · `docs/NAVIGATION.md` (IA + UX clarity charter — read before any view PR) · `ROADMAP.md` (long-range plan) |

**No-Mac workflow.** There is no macOS machine and no local `xcodebuild`, so
every iOS verification happens through GitHub Actions:

1. Edit Swift / `project.yml` / config locally on Linux.
2. Run `bash scripts/local_checks.sh` — it catches the lint and config failures
   that otherwise cost a full ~5-minute CI round trip (line length, approximate
   type-body length, YAML/plist parse, backend typecheck + tests).
3. `git push` to a `claude/**` branch — `.github/workflows/ci.yml` runs
   `gitleaks → xcodegen → swiftlint --strict → xcodebuild build → xcodebuild test`
   on `macos-15`, plus the backend typecheck/test job on Ubuntu.
4. Read CI logs (GitHub MCP or the Actions UI) to verify; iterate.
5. `ci.yml` uses a `cancel-in-progress` concurrency group — pushing again
   kills the run in flight. Let a run you actually need finish before pushing.
6. To run on a real phone: `ios-testflight.yml` (needs the Apple signing
   secrets — see `docs/TESTFLIGHT.md`).

**The build is stricter than it looks.** The `Lumina` target sets
`SWIFT_TREAT_WARNINGS_AS_ERRORS`, `GCC_TREAT_WARNINGS_AS_ERRORS`, and
`SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY`. A bare `Error?` (rather than
`(any Error)?`) is a hard build failure, not a warning. Same for any unused
variable or deprecation. SPM dependency builds are unaffected.

---

## 🌙 What This Project Is

**Lumina** is a premium iOS 26 astrology app. The thesis: every existing
competitor (Co-Star, CHANI, Nebula, The Pattern) either fakes palm reading,
hallucinates planetary positions, or uses dark billing patterns. Lumina does
none of those.

**Tagline:** *Finally, a real one.*

**Palm reading is not in this release.** `Lumina/Features/Palm/` and
`Lumina/Core/PalmCV/` contain scaffolding — feature types and a stub reader —
but there is **no capture session, no Core ML model, and no segmenter**. The
`Palm` tab is excluded from `LuminaTab.visible` and palm deep links clamp to
Today, so the module has no reachable entry point. Nothing in the app or the
store metadata may claim otherwise (Guideline 2.3.1).

**App Store target:** iOS 26, SwiftUI 5, Swift 6.0 strict concurrency.

---

## 🏗️ Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│                  SwiftUI 5 (iOS 26)                   │
│         @Observable + SwiftData + Liquid Glass         │
└─────────────────┬────────────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────────────┐
│                 Core Services Layer                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │Ephemeris │ │   Auth   │ │ LuminaAI │ │ IAPMgr  │ │
│  │ Service  │ │ (Apple + │ │  Client  │ │(RevCat) │ │
│  │ (actor)  │ │ Keychain)│ │          │ │         │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬────┘ │
└───────┼────────────┼────────────┼────────────┼───────┘
        │            │            │            │
┌───────▼────────────▼────────────▼────────────▼───────┐
│                External Services                       │
│  backend/ (Node 22 + Fastify)  │ Supabase │  RevCat   │
│  ├─ astronomy-engine ephemeris │  (auth   │   SDK     │
│  └─ /interpret → Anthropic API │ exchange)│           │
└──────────────────────────────────────────────────────┘
```

Both the chart math **and** the LLM interpretation go through the same
self-hosted `backend/` service. The app never holds an Anthropic key.

### Key Architectural Decisions

- **Strict Swift 6 concurrency** — all async work via `async/await`, actors for
  shared state, `@MainActor` on every `@Observable` view model.
- **`astronomy-engine` (MIT), not Swiss Ephemeris.** Swiss Eph Pro is a
  CHF 1,550 license that was never bought; `backend/src/lib/` implements
  houses, aspects, transits, progressions, synastry and composites on top of
  `astronomy-engine`. Several docs still called this "Swiss Eph" — that name
  is wrong wherever it appears.
- **Tropical ecliptic *of date*.** Verified empirically: the Sun reads exactly
  0.0000° at the March equinox for 1800 → 2050. Do not "fix" the frame to
  J2000 — it would shift every chart in the app.
- **Server-side LLM.** `POST /interpret` on the backend calls Anthropic with
  the computed chart facts wrapped in `<chart_facts>` / `<user_question>`
  tags. There is **no RAG, no embeddings, and no vector store** — grounding is
  "the prompt contains the real numbers", which is the honest claim.
- **RevenueCat** — all IAP through the RevenueCat SDK; **no web billing
  funnel** (Guideline 3.1.2(c)).
- **SwiftData** — local persistence for journal entries and friends, behind
  `LuminaSchema.swift`'s versioned schema + migration plan, with an in-memory
  fallback (`isEphemeralFallback`) so a corrupt store degrades instead of
  crashing at launch.
- **MetricKit for crash reporting** (`Core/Diagnostics/CrashReporter.swift`) —
  no vendor account, no extra privacy-manifest burden.

---

## 📁 Directory Structure

```
Lumina/
├── App/                    LuminaApp.swift · AppDelegate.swift · RootView · router
├── Core/
│   ├── AI/                 LuminaAIClient.swift — calls backend /interpret
│   ├── Auth/               AuthManager · AuthSession · KeychainStore · SupabaseAuthService
│   ├── Config/             BuildConfig.swift — reads Info.plist, rejects `$(…)` placeholders
│   ├── Diagnostics/        CrashReporter.swift — MetricKit subscriber
│   ├── Ephemeris/          EphemerisService (actor) · ChartCache · NatalChartStore · Models/
│   ├── Errors/             LuminaError + mapping (no raw Error ever reaches a View)
│   ├── Glossary/           GlossaryStore.swift (backed by Resources/Glossary.json)
│   ├── IAP/                IAPManager · Entitlements · PremiumStatus · PremiumGate
│   ├── Motion/             MotionManager.swift — gyroscope parallax
│   ├── Notifications/      permission · tap routing · transit + reflect schedulers
│   ├── PalmCV/             scaffolding only — no capture, no model, not reachable
│   ├── Progression/        ChartDiscovery · MomentsStore
│   ├── Security/           AppLock.swift — Face ID gate
│   ├── Storage/            AppPreferences · UserBirthDataStore · ModelContext+Save
│   └── Widget/             WidgetPublisher · WidgetSharedStore (App Group bridge)
├── Features/
│   ├── Auth/               SignInView
│   ├── Chart/              natal wheel, Human Design, quiz, deterministic Q&A
│   ├── Moments/            streak-free milestones
│   ├── Onboarding/         8 steps: brandPromise → motivation → name → birthDate
│   │                       → birthTime → birthPlace → chartReveal → whatNext
│   ├── Palm/               "coming soon" screen — unreachable in this release
│   ├── Paywall/            PaywallOfferView · PaywallTracker
│   ├── People/             compatibility, synastry, composite, QR sharing
│   ├── Reflect/            journal + calendar + reminders
│   ├── Settings/           account, privacy dashboard, notifications, legal
│   └── Today/              daily reading, moon, retrogrades, forecast, returns
├── Design/
│   ├── Tokens/             LuminaColors · LuminaTypography · LuminaSpacing
│   └── Components/         reusable SwiftUI views (buttons, cards, states, fields)
├── Models/                 JournalEntry · Friend · SharedBirthData · LuminaSchema
└── Resources/              Assets.xcassets · Fonts/ (empty) · Glossary.json
                            Localizable.xcstrings · PrivacyInfo.xcprivacy

LuminaWidget/               CosmicWidget · LuminaWidgetBundle · PrivacyInfo.xcprivacy
LuminaTests/                XCTest suite (runs in CI after the build)
backend/                    Node 22 + Fastify + TypeScript ephemeris/interpret service
```

---

## 🎨 Design System

### Color Palette
```swift
// LuminaColors.swift — always use these, never raw hex
static let inkBlack      = Color(hex: "#1A1A1F")   // primary text
static let parchment     = Color(hex: "#F5F0E6")   // primary background
static let celestialBlue = Color(hex: "#3D5A8C")   // accent / interactive
static let mutedGold     = Color(hex: "#C9A96E")   // premium accent
static let midnight      = Color(hex: "#0B1437")   // chart wheel background
static let blush         = Color(hex: "#E5C8C2")   // warmth accent
```

### Typography

`Resources/Fonts/` is **empty** — PP Editorial New, Söhne and GT America Mono
are all paid licences that were never bought. `LuminaTypography` therefore maps
every role onto a system font (`.serif` for display/heading, default for body,
`.monospaced` for data). This is deliberate: shipping unlicensed fonts is worse
than shipping system ones, and Dynamic Type works out of the box. When a
licence is bought, swap the token bodies to `Font.custom(_:size:relativeTo:)` —
every call site already goes through `LuminaTypography`, so nothing else
changes.

- **Minimum body size:** 16pt · **Minimum label:** 13pt · **Line height:** 1.5×

### Design Principles
1. **Wellness-editorial hybrid** — CHANI warmth × The Cut discipline, NOT
   purple-gradient mysticism.
2. **Anti-Duolingo** — no confetti, achievement bursts, or streak counters.
3. **Liquid Glass** — iOS 26 glassmorphism for modal sheets and overlays.
4. **Motion** — slow gyroscope star parallax, 90s wheel rotation, light haptics
   on planet tap, `.smooth` cross-fades. No spring bounces on content cards.
5. **Custom illustration only** — stock clipart ships as a bug.

---

## 🔑 Environment Variables

All secrets live in `.env.local` (gitignored). Never hardcode a key.

```bash
# .env.local — copy from .env.example. These are exactly the keys
# scripts/inject_env.sh writes into secrets/Config.xcconfig.
REVENUECAT_API_KEY_IOS=        # iOS public key — safe in the binary
ONESIGNAL_APP_ID=
SUPABASE_URL=
SUPABASE_ANON_KEY=             # anon key — safe in the binary
SWISS_EPH_SERVICE_URL=         # backend base URL, e.g. http://localhost:3001
SWISS_EPH_API_SECRET=          # shared secret for the backend's auth check
```

`ANTHROPIC_API_KEY` is **not** in that list and must never be. LLM calls are
server-side; a key in the app bundle is extractable from the IPA. Set it in
`backend/.env` locally, or `fly secrets set` in production — see
`backend/.env.example`.

**The `//` hazard.** xcconfig treats `//` as a line comment *anywhere* on the
line, so a raw URL silently truncates to `https:`. `inject_env.sh` escapes
every value with xcconfig's `$()` empty-substitution idiom and then verifies
the round trip, failing the build rather than shipping a binary that can't
reach its backend. Don't "simplify" that escape.

The committed `project.xcconfig` only does `#include? "secrets/Config.xcconfig"`,
so a missing secrets file degrades to empty values instead of failing to build.

---

## ⚡ Common Commands

```bash
# Pre-push checks that don't need a Mac (run this before every push)
bash scripts/local_checks.sh

# Backend — the ephemeris + interpretation service
cd backend
npm install
npm run dev              # tsx watch, :3001
npm test                 # vitest
npm run typecheck        # tsc --noEmit
npm start                # production entrypoint (node --experimental-strip-types)

# Regenerate the Xcode project after touching project.yml
bash scripts/inject_env.sh   # writes secrets/Config.xcconfig from .env.local
xcodegen generate            # Lumina.xcodeproj is NOT committed

# App icon
node scripts/generate_app_icon.mjs
```

`xcodebuild`, `swiftlint` and `swiftformat` are **not** available in this
environment — CI runs them. Don't add commands here that only work on a Mac
without saying so.

**Backend gotcha:** production runs under `node --experimental-strip-types`,
which erases types but does **not** transform syntax. TypeScript parameter
properties (`constructor(readonly x: string)`) and enums are rejected at
runtime even though `tsc` and `vitest` accept them. CI boots the production
entrypoint and probes `/health` for exactly this reason.

---

## 📦 Swift Package Dependencies

Declared in `project.yml` (XcodeGen resolves them; no `Package.resolved` in
the repo):

| Package | Version | Purpose |
|---|---|---|
| `RevenueCat/purchases-ios` | `from: 5.0.0` | IAP management |
| `supabase/supabase-swift` | `from: 2.0.0` | Auth token exchange |
| `OneSignal/OneSignal-XCFramework` | `from: 5.0.0` | Push notifications |

That's the whole list. No Lottie, no Alamofire, no RxSwift/Combine — native
`URLSession` with async/await actors, and `@Observable` for state. SwiftLint
and SwiftFormat are CI tools installed via Homebrew, not package dependencies.

---

## 🚨 Critical Rules — Never Break These

1. **No API keys in source code.** `Config.xcconfig` + `secrets/` pattern; CI
   uses GitHub Secrets. `gitleaks` gates every push, over the working tree
   *and* full history.
2. **No web billing funnel.** All IAP through RevenueCat + App Store.
3. **No weekly subscription tier.** Apple is actively enforcing against weekly
   fleeceware in this category. Monthly + annual only.
4. **Never hardcode a price.** Prices come from the live RevenueCat offering
   and are already localized for the user's storefront; a pinned `$9.99` is
   wrong in every other country and is a Guideline 3.1.2 problem.
5. **No hardcoded hex colors or font names** outside `Design/Tokens/`.
6. **All `@Observable` ViewModels on `@MainActor`.**
7. **Chart math comes from the backend.** Never ask a language model to compute
   a planetary position.
8. **Never claim a feature the binary doesn't have** — in the app, the README,
   or the store listing. That is the single fastest path to a 2.3.1 rejection,
   and this repo has already had to walk several such claims back.
9. **Paywall:** one soft rescue at most once per install (`PaywallTracker`),
   then hard stop, and no second paywall in the same session. The rescue
   reframes the offer — it does **not** invent a discount. An earlier version
   showed a fake "30% off / $41.99" and then charged the real annual price;
   never reintroduce a price the user wasn't actually offered.
10. **The free/paid split lives in exactly one place** — `PremiumFeature` in
    `Core/IAP/PremiumGate.swift`. Gates and the paywall's feature list both
    read it, so marketing and gating can't drift.

---

## 🗂️ Session Protocol

### At the start
1. Read this file's Quick Context table — confirm the active branch.
2. Read `LAUNCH-READINESS.md` for what's outstanding, `TASK.md` for status.
3. Read `LEARNINGS.md` for recent gotchas and decisions.
4. `git status && git log --oneline -5`.
5. Read the relevant `docs/` file for whatever you're touching.

### During
- Work on a `claude/**` branch — never commit to `main`.
- Conventional commits: `fix(ios): persist house system across relaunch`.
- Document decisions in code with a `// DECISION:` prefix.
- `bash scripts/local_checks.sh` before every push.
- Verify claims before writing them down. Three findings in the last audit
  were false positives that would have *introduced* bugs if "fixed" — the
  ephemeris frame one would have shifted every chart in the app.

### At the end
1. Update `TASK.md` — `[x]` done, `[~]` in progress, note blockers.
2. Append new gotchas to `LEARNINGS.md` with a date tag.
3. Let CI gate the merge.
4. `git push -u origin <branch>`.
5. Update **Last updated** in the Quick Context table above.

---

## 🔗 Key External Resources

- [Anthropic Messages API](https://docs.anthropic.com) — backend `/interpret`
- [astronomy-engine](https://github.com/cosinekitty/astronomy) — the ephemeris the backend actually uses
- [RevenueCat iOS SDK](https://www.revenuecat.com/docs/getting-started/installation/ios)
- [iOS 26 HIG](https://developer.apple.com/design/human-interface-guidelines/) — Liquid Glass guidance
- [OneSignal iOS](https://documentation.onesignal.com/docs/ios-sdk-setup)
- [Supabase Swift](https://supabase.com/docs/reference/swift/introduction)
- [MetricKit](https://developer.apple.com/documentation/metrickit) — crash/hang payloads
- Competitive research: `docs/COMPETITIVE-ANALYSIS.md`
