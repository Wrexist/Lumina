# 🌙 Lumina — Astrology & Palm Reading for iOS 26

> *Finally, a real one.*

A best-in-class astrology + AI palm reading app for iOS 26. Real computer vision palm analysis, Swiss Ephemeris–grounded LLM personalization, honest App Store billing, and a premium wellness-editorial design language that no competitor has shipped.

---

## Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI 5 · iOS 26 Liquid Glass design system |
| Language | Swift 6.0 (strict concurrency) |
| State | `@Observable` + SwiftData |
| Palm CV | Apple Vision `VNDetectHumanHandPoseRequest` + Core ML (custom U-Net) |
| Ephemeris | Swiss Ephemeris Pro (self-hosted Node service) |
| AI Content | Claude claude-opus-4-6 via Anthropic API (RAG-grounded) |
| Audio | ElevenLabs TTS for daily reading narration |
| IAP | RevenueCat SDK |
| Push | OneSignal |
| Backend | Supabase (auth, user profiles, RAG vector store) |
| CI | GitHub Actions (`macos-15`, latest-stable Xcode) |

---

## Features (v1 — shipped)

- **🔮 Birth Chart** — Placidus / Whole-Sign toggle, interactive wheel, plain-English planet interpretations, "know your chart" daily quiz, and a placement-discovery collection
- **📅 Daily Reading** — Transit-grounded, deterministic reading with a once-a-day reveal; moon phase, retrogrades, progressed chapter, and upcoming returns
- **💫 Compatibility** — Synastry + composite + narrative dimensions; add people manually or by QR share
- **⚙️ Human Design** — Personality-side bodygraph from birth data (differentiator — no competitor ships this)
- **📓 Journal** — Daily transit-tied prompts, calendar review, optional evening reminder
- **✦ Moments** — quiet, streak-free milestones for real things you've done
- **👯 Friend Graph** — deep-link / QR share cards, chart comparison
- **💳 Subscription** — $9.99/month or $59.99/year · 7-day free trial · visible cancel button

### Roadmap (not yet shipped — deliberately not advertised in-app)

- **🤚 AI Palm Reading** — on-device Vision + Core ML line segmentation (the Palm tab is hidden until the capture pipeline and fairness testing land)
- **🔊 Audio narration** of the daily reading (ElevenLabs)
- **💬 Conversational "Ask your chart"** (RAG-grounded LLM) — the deterministic Q&A ships today; the free-text path unlocks when the key is provisioned
- **📇 Contacts import** for compatibility

---

## Project Structure

```
Lumina/
├── App/
│   ├── LuminaApp.swift              # @main entry point
│   └── AppDelegate.swift
├── Core/
│   ├── Ephemeris/                   # Swiss Eph API client
│   ├── PalmCV/                      # Vision + Core ML pipeline
│   ├── AI/                          # Claude API + RAG client
│   └── IAP/                         # RevenueCat manager + entitlements
├── Features/
│   ├── Onboarding/
│   ├── BirthChart/
│   ├── DailyReading/
│   ├── PalmReading/
│   ├── Compatibility/
│   ├── HumanDesign/
│   ├── Journal/
│   └── Friends/
├── Design/
│   ├── Tokens/                      # Color, type, spacing tokens
│   ├── Components/                  # Reusable SwiftUI views
│   └── Illustrations/               # Custom celestial SVGs
├── Models/                          # SwiftData models + DTOs
├── Services/                        # Network, notifications, analytics
└── Resources/                       # Assets, fonts, localization
```

---

## Getting Started

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/lumina-ios.git
cd lumina-ios

# 2. Copy environment config and fill in API keys
cp .env.example .env.local
# (see docs/API_KEYS.md once it lands)

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

- [`CLAUDE.md`](./CLAUDE.md) — AI session handoff context (read this first every Claude Code session)
- [`TASK.md`](./TASK.md) — Current sprint tasks & status
- [`LEARNINGS.md`](./LEARNINGS.md) — Accumulated knowledge, gotchas, decisions
- [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) — Full technical architecture
- [`docs/PRODUCT_SPEC.md`](./docs/PRODUCT_SPEC.md) — Product spec & design principles
- [`docs/API_KEYS.md`](./docs/API_KEYS.md) — API key setup guide (no actual keys)

---

## Monetization

| Tier | Price | Details |
|---|---|---|
| Free | $0 | Daily horoscope, basic chart, 1 palm scan/month |
| Premium | $9.99/mo · $59.99/yr | Full personalization, audio, unlimited palm, Human Design |
| Crush Report | $4.99 IAP | Deep compatibility analysis |
| Year Ahead | $11.99 IAP | 12-month transit forecast |
| Career Forecast | $7.99 IAP | Saturn/Jupiter career transits |
| Ask the Stars | $2.99 IAP | 10 Claude Q&A credits |

---

## Research Foundation

Built from a deep competitive analysis of Co-Star, CHANI, The Pattern, Nebula, Sanctuary, TimePassages, and the palm-reading fleeceware category. Key insight: **every existing app either fakes palm reading, hallucinates planetary positions, or traps users with dark billing patterns.** Lumina ships none of those.

See [`docs/PRODUCT_SPEC.md`](./docs/PRODUCT_SPEC.md) for the full strategic brief.

---

*Made with Claude claude-opus-4-6 + Claude Code*
