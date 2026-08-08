# 🌙 Lumina — Astrology for iOS 26

> *Finally, a real one.*

A best-in-class astrology app for iOS 26. Real planetary math from a self-hosted ephemeris service, LLM interpretations grounded in your actual computed chart, and honest App Store billing.

> **Palm reading is not in this release.** The `Palm` tab is excluded from
> `LuminaTab.visible` and the module has no reachable entry point. Nothing in
> the app or the store metadata claims otherwise — see `LAUNCH-READINESS.md`.

---

## Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI 5 · iOS 26 Liquid Glass design system |
| Language | Swift 6.0 (strict concurrency) |
| State | `@Observable` + SwiftData |
| Ephemeris | `astronomy-engine` (MIT), self-hosted Node/Fastify service |
| AI Content | Claude via Anthropic API, grounded in computed chart facts (model set by `ANTHROPIC_MODEL`, default `claude-sonnet-5`) |
| IAP | RevenueCat SDK |
| Push | OneSignal |
| Auth | Sign in with Apple + Keychain; Supabase exchange when configured |
| CI | GitHub Actions (`macos-15`, latest-stable Xcode) |

---

## Features (v1 — shipped)

- **🔮 Birth Chart** — Placidus / Whole-Sign / Sidereal house systems, interactive wheel, plain-English planet interpretations, "know your chart" daily quiz, and a placement-discovery collection
- **📅 Daily Reading** — Transit-grounded, deterministic reading with a once-a-day reveal; moon phase, retrogrades, progressed chapter, and upcoming returns
- **💫 Compatibility** — Synastry + composite + narrative dimensions; add people manually or by QR share
- **⚙️ Human Design** — Personality-side bodygraph from birth data (differentiator — no competitor ships this)
- **📓 Journal** — Daily transit-tied prompts, calendar review, optional evening reminder
- **✦ Moments** — quiet, streak-free milestones for real things you've done
- **👯 Friend Graph** — deep-link / QR share cards, chart comparison
- **💳 Subscription** — monthly + annual auto-renewable, priced and localized by App Store Connect (the app never hardcodes a price), visible cancel button, and a trial line shown only when the product actually carries one

### Roadmap (not yet shipped — deliberately not advertised in-app)

- **🤚 AI Palm Reading** — on-device Vision + Core ML line segmentation (the Palm tab is hidden until the capture pipeline and fairness testing land)
- **🔊 Audio narration** of the daily reading
- **💬 Free-text "Ask your chart"** — today's Q&A sends your computed chart facts to Claude with the question; a retrieval-grounded corpus is a later step
- **📇 Contacts import** for compatibility

---

## Project Structure

```
Lumina/
├── App/
│   ├── LuminaApp.swift              # @main entry point
│   └── AppDelegate.swift
├── Core/
│   ├── Ephemeris/                   # client for the Node ephemeris service
│   ├── AI/                          # interpretation client (calls the same service)
│   ├── Auth/                        # Sign in with Apple + Keychain
│   ├── Diagnostics/                 # MetricKit crash/hang reporting
│   ├── Notifications/               # local + OneSignal push
│   ├── PalmCV/                      # scaffolding only — no capture pipeline yet
│   └── IAP/                         # RevenueCat manager, entitlements, premium gate
├── Features/
│   ├── Onboarding/
│   ├── Today/          # daily reading, moon, forecast
│   ├── Chart/          # natal wheel, Human Design, quiz, Q&A
│   ├── People/         # compatibility, synastry, composite, sharing
│   ├── Reflect/        # journal
│   ├── Paywall/
│   ├── Settings/
│   └── Palm/           # not reachable in this release
├── Design/
│   ├── Tokens/                      # Color, type, spacing tokens
│   └── Components/                  # Reusable SwiftUI views
├── Models/                          # SwiftData models + versioned schema
└── Resources/                       # Assets, privacy manifest, string catalog
```

---

## Getting Started

```bash
# 1. Clone
git clone https://github.com/Wrexist/Lumina.git
cd Lumina

# 2. Copy environment config and fill in API keys
cp .env.example .env.local
# (see .env.example and backend/.env.example for the full key list)

# 3. Generate the Xcode project (Lumina.xcodeproj is NOT committed —
#    it is regenerated from project.yml via XcodeGen)
brew install xcodegen
bash scripts/inject_env.sh   # writes secrets/Config.xcconfig from .env.local
xcodegen generate
open Lumina.xcodeproj        # Swift Packages resolve on first open

# 4. Install backend deps for local ephemeris service
cd backend && npm install && npm run dev

# 5. Run on simulator
# Select "Lumina" scheme → iPhone 16 Pro → ⌘R
```

---

## Documentation

- [`DEV.md`](./DEV.md) — session handoff context (read this first)
- [`TASK.md`](./TASK.md) — Current sprint tasks & status
- [`LEARNINGS.md`](./LEARNINGS.md) — Accumulated knowledge, gotchas, decisions
- [`LAUNCH-STEPS.md`](./LAUNCH-STEPS.md) — **what's left to launch**, step by step
- [`LAUNCH-READINESS.md`](./LAUNCH-READINESS.md) — the pre-launch audit this came from
- [`docs/NAVIGATION.md`](./docs/NAVIGATION.md) — IA + UX clarity charter
- [`docs/aso/`](./docs/aso/) — **App Store metadata pack**: every ASC field, keyword research, screenshot storyboard, privacy answers (`python3 scripts/aso_lint.py --print`)
- [`docs/ASSET-BRIEF.md`](./docs/ASSET-BRIEF.md) — 26 copy-paste image-generation prompts and the specs for wiring the results in

---

## Monetization

| Tier | Price | Details |
|---|---|---|
| Free | Free | Daily transit reading, full birth chart wheel, journal, moments |
| Lumina Plus | monthly · annual, set in App Store Connect | Human Design bodygraph, synastry + composite compatibility, transit forecast, home-screen widget |

Prices are read from the live RevenueCat offering at runtime and rendered in
the user's storefront currency — nothing in the app or this README pins a
number, because a hardcoded price is wrong in every other country.

The free/paid split is defined in exactly one place — `PremiumFeature` in
`Lumina/Core/IAP/PremiumGate.swift` — which both the gates and the paywall's
feature list read, so marketing and gating cannot drift apart. There are no
one-off IAPs; `Entitlement` defines a single `lumina_plus` case.

---

## Research Foundation

Built from a deep competitive analysis of Co-Star, CHANI, The Pattern, Nebula, Sanctuary, TimePassages, and the palm-reading fleeceware category. Key insight: **every existing app either fakes palm reading, hallucinates planetary positions, or traps users with dark billing patterns.** Lumina ships none of those.

See [`ROADMAP.md`](./ROADMAP.md) for the full plan.

---

*Made with Claude Code*
