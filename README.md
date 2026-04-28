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
| CI | GitHub Actions → Xcode Cloud |

---

## Features (v1)

- **🔮 Birth Chart** — Placidus / Whole-Sign / Sidereal toggle, interactive wheel, plain-English planet interpretations
- **🤚 AI Palm Reading** — On-device Vision + Core ML line segmentation with transparent trace overlay
- **📅 Daily Reading** — Transit-grounded LLM content narrated via ElevenLabs audio
- **💫 Compatibility** — Synastry + composite + narrative compatibility dimensions via contact import
- **⚙️ Human Design** — Bodygraph from birth data (differentiator — no competitor ships this)
- **📓 Journal** — Daily transit-tied prompts with longitudinal pattern review
- **👯 Friend Graph** — Deep-link share cards, chart comparison threads
- **💳 Subscription** — $9.99/month or $59.99/year · 7-day free trial · visible cancel button

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
│   └── RevenueCat/                  # IAP manager
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

# 2. Install dependencies (Swift Package Manager — auto on Xcode open)
open Lumina.xcodeproj

# 3. Copy environment config
cp .env.example .env.local
# Fill in API keys (see docs/API_KEYS.md)

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
