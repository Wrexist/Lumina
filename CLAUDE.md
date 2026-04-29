# CLAUDE.md — Lumina iOS Session Handoff

> **READ THIS FIRST** at the start of every Claude Code session.
> Update `TASK.md` and `LEARNINGS.md` at the end of every session.

---

## ⚡ Quick Context (read before anything else)

| Item | Value |
|---|---|
| **Phase** | Bootstrap — Xcode scaffolding committed; CI builds on every push |
| **Active branch** | `claude/initial-app-setup-hQvKZ` |
| **Last updated** | 2026-04-29 |
| **Dev environment** | **No local macOS** — CI on `macos-15`/Xcode-latest is the only build/test loop |
| **Blockers** | Font license · Swiss Eph license · ElevenLabs voice · Palm ML model · Supabase project · TestFlight signing |

**No-Mac workflow.** This developer has no macOS machine, so every iOS verification happens through GitHub Actions:

1. Edit Swift / `project.yml` / config locally on Linux.
2. `git push` to a `claude/**` branch — workflow `.github/workflows/ci.yml` runs `xcodegen generate → swiftlint → xcodebuild build → xcodebuild test` on `macos-15`.
3. Read CI logs (via the GitHub MCP or the Actions UI) to verify; iterate.
4. There is **no `xcodebuild` available locally** — the `/build`, `/test`, `/lint`, `/chart` slash commands and most macOS-only docs apply only when run on a Mac. Outside that, treat them as documentation of what CI does.
5. To actually run the app on a phone, ship via CI → TestFlight (planned milestone — needs Apple Developer signing artifacts).

---

## 🌙 What This Project Is

**Lumina** is a premium iOS 26 astrology + AI palm reading app targeting the $5–6B and growing spiritual-wellness app category. The core thesis: every existing competitor (Co-Star, CHANI, Nebula, The Pattern) either fakes palm reading, hallucinates planetary positions, uses dark billing patterns, or all three. Lumina does none of those.

**Tagline:** *Finally, a real one.*

**App Store target:** iOS 26, SwiftUI 5, Swift 6.0 strict concurrency, Xcode 17.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  SwiftUI 5 (iOS 26)                  │
│         @Observable + SwiftData + Liquid Glass        │
└─────────────────┬───────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────┐
│                 Core Services Layer                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │Ephemeris │ │ Palm CV  │ │Claude API│ │RevCat  │ │
│  │  Client  │ │(Vision + │ │  + RAG   │ │  IAP   │ │
│  │          │ │Core ML)  │ │          │ │        │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬────┘ │
└───────┼────────────┼────────────┼────────────┼──────┘
        │            │            │            │
┌───────▼────────────▼────────────▼────────────▼──────┐
│              External Services                        │
│  Swiss Eph  │  Apple Vision  │  Anthropic   │  RevCat│
│  Pro (Node) │  + Custom ML   │  claude-opus │  SDK   │
│             │  U-Net model   │  -4-6 + RAG  │        │
└─────────────────────────────────────────────────────┘
```

### Key Architectural Decisions
- **Strict Swift 6 concurrency** — all async work via `async/await`, actors for shared state, `@MainActor` on all `@Observable` view models
- **On-device palm CV** — `VNDetectHumanHandPoseRequest` + Core ML custom U-Net for line segmentation; only feature vector sent to server
- **Swiss Ephemeris Pro** — self-hosted Node.js microservice (not third-party API) to avoid per-call costs at scale; deterministic output piped to Claude as structured JSON
- **RAG-grounded LLM** — Claude claude-opus-4-6 with pgvector RAG over curated corpus (Liz Greene, Steven Forrest, Robert Hand); never raw LLM for interpretation
- **RevenueCat** — all IAP through RevenueCat SDK; **no web billing funnel** (Apple Guideline 3.1.2(c) compliance)
- **SwiftData** — local persistence for chart data, journal entries, cached readings; no Core Data
- **Supabase** — backend for auth, user profiles, push token management, RAG vector store

---

## 📁 Directory Structure

```
Lumina/
├── App/
│   ├── LuminaApp.swift                 # @main, app entry, scene setup
│   └── AppDelegate.swift               # push notification setup, RevenueCat init
│
├── Core/
│   ├── Ephemeris/
│   │   ├── EphemerisService.swift      # Actor — calls self-hosted Node API
│   │   ├── ChartCalculator.swift       # Aspect calculation, house cusp math
│   │   └── Models/                     # Planet, House, Aspect, Transit DTOs
│   │
│   ├── PalmCV/
│   │   ├── PalmCaptureSession.swift    # AVCaptureSession wrapper
│   │   ├── HandPoseDetector.swift      # VNDetectHumanHandPoseRequest
│   │   ├── LineSegmenter.swift         # Core ML U-Net inference
│   │   ├── PalmFeatureExtractor.swift  # Geometric features from segmentation
│   │   └── Models/lumina_palm_v1.mlpackage
│   │
│   ├── AI/
│   │   ├── LuminaAIClient.swift        # Actor — Anthropic API calls
│   │   ├── RAGRetriever.swift          # Supabase pgvector similarity search
│   │   ├── ContentGenerator.swift      # Daily reading, palm narration, compat
│   │   └── Prompts/                    # System prompt templates (version-controlled)
│   │
│   └── IAP/
│       ├── IAPManager.swift            # RevenueCat wrapper — actor
│       ├── Entitlements.swift          # Enum of all premium entitlements
│       └── Paywalls/                   # Paywall view models
│
├── Features/
│   ├── Onboarding/                     # 7-screen onboarding flow
│   ├── BirthChart/                     # Interactive wheel + interpretations
│   ├── DailyReading/                   # Transit-grounded LLM + ElevenLabs audio
│   ├── PalmReading/                    # CV capture + trace overlay + reading
│   ├── Compatibility/                  # Synastry + composite + narrative
│   ├── HumanDesign/                    # Bodygraph visualization
│   ├── Journal/                        # Transit-tied prompts + longitudinal review
│   └── Friends/                        # Contact-graph friend chart comparison
│
├── Design/
│   ├── Tokens/
│   │   ├── LuminaColors.swift          # Brand palette — DO NOT use hex literals elsewhere
│   │   ├── LuminaTypography.swift      # Font pairings — PP Editorial New + Söhne + GT Mono
│   │   └── LuminaSpacing.swift         # 8pt grid system
│   ├── Components/                     # Reusable SwiftUI views
│   └── Illustrations/                  # SVG celestial assets (custom, not stock)
│
├── Models/                             # SwiftData @Model classes + Codable DTOs
├── Services/                           # Network layer, OneSignal, analytics
└── Resources/
    ├── Assets.xcassets
    ├── Fonts/                          # PP Editorial New, Söhne, GT America Mono
    └── Localizable.xcstrings           # iOS 26 String Catalogs
```

---

## 🎨 Design System

### Color Palette
```swift
// LuminaColors.swift — always use these, never raw hex
static let inkBlack     = Color(hex: "#1A1A1F")   // primary text
static let parchment    = Color(hex: "#F5F0E6")   // primary background
static let celestialBlue = Color(hex: "#3D5A8C")  // accent / interactive
static let mutedGold    = Color(hex: "#C9A96E")   // premium accent
static let midnight     = Color(hex: "#0B1437")   // chart wheel background
static let blush        = Color(hex: "#E5C8C2")   // warmth accent
```

### Typography
- **Display / Hero:** PP Editorial New Italic (paid license required — confirm before using)
- **Headings:** PP Editorial New Regular
- **Body:** Söhne Regular / Söhne Leicht
- **Monospace / Data:** GT America Mono (degrees, timestamps, zodiac glyphs)
- **Minimum body size:** 16pt · **Minimum label:** 13pt · **Line height:** 1.5×

### Design Principles
1. **Wellness-editorial hybrid** — CHANI warmth × The Cut discipline · NOT purple-gradient mysticism
2. **Anti-Duolingo** — no confetti, achievement bursts, or streak counters — breaks premium signal
3. **Liquid Glass** — iOS 26 glassmorphism for modal sheets and overlays — use native `.glassBackgroundEffect()` modifier
4. **Motion:** slow gyroscope star parallax, Lottie particles on loading, 90s wheel rotation, light haptics on planet tap, `.smooth` cross-fades — no spring bounces on content cards
5. **Custom illustration only** — if stock clipart is present, it ships as a bug

---

## 🔑 Environment Variables

All secrets live in `.env.local` (gitignored). Never hardcode API keys.

```bash
# .env.local (copy from .env.example)
ANTHROPIC_API_KEY=
ELEVENLABS_API_KEY=
ELEVENLABS_VOICE_ID=           # Lumina's brand voice
REVENUECAT_API_KEY_IOS=
ONESIGNAL_APP_ID=
SUPABASE_URL=
SUPABASE_ANON_KEY=
SWISS_EPH_SERVICE_URL=         # Self-hosted: https://eph.lumina.app
SWISS_EPH_API_SECRET=
```

Keys are injected via `secrets/Config.xcconfig` (gitignored, generated by `scripts/inject_env.sh` from `.env.local` or CI env vars). The committed `project.xcconfig` only does `#include? "secrets/Config.xcconfig"`. See `docs/API_KEYS.md` for full setup.

---

## ⚡ Common Commands

```bash
# Run ephemeris backend locally
cd backend && npm run dev          # starts on :3001

# Generate fresh chart JSON for a birth date (testing)
npm run chart -- --date "1990-06-15" --time "14:30" --place "Stockholm, Sweden"

# Run Core ML model conversion (Python venv required)
source .venv/bin/activate
python scripts/convert_palm_model.py   # outputs lumina_palm_v1.mlpackage

# Swift type-check (CI mirrors this)
xcodebuild -scheme Lumina -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -skipPackagePluginValidation build | xcpretty

# Run tests
xcodebuild test -scheme LuminaTests -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  | xcpretty

# Lint
swiftlint lint --strict

# Localization sync
xcrun extractLocStrings ... (see scripts/sync_strings.sh)
```

---

## 📦 Swift Package Dependencies

Managed via Swift Package Manager (Xcode):

| Package | Version | Purpose |
|---|---|---|
| `revenuecat/purchases-ios` | `^5.0` | IAP management |
| `supabase/supabase-swift` | `^2.0` | Backend client |
| `onesignal/OneSignal-XCFramework` | `^5.0` | Push notifications |
| `airbnb/lottie-ios` | `^4.0` | Loading animations |
| `nicklockwood/SwiftFormat` | `^0.54` | Dev tool |
| `realm/SwiftLint` | `^0.57` | Linting |

No Alamofire — use native `URLSession` with async/await actors. No RxSwift/Combine — use `@Observable`.

---

## 🚨 Critical Rules — Never Break These

1. **No API keys in source code.** Use `Config.xcconfig` + `secrets/` pattern. CI uses GitHub Secrets.
2. **No web billing funnel.** All IAP through RevenueCat + App Store. Learned from category-wide Apple enforcement in 2026.
3. **No weekly subscription tier.** Apple is actively scrutinizing $4.99–$9.99/week "fleeceware" in this category. Monthly + annual only.
4. **No hardcoded hex colors or font names** outside `Design/Tokens/`. Every color must come from `LuminaColors`, every font from `LuminaTypography`.
5. **All `@Observable` ViewModels on `@MainActor`.** Swift 6 strict concurrency — CI will fail on data race warnings.
6. **Palm CV stays on-device.** Only the extracted feature vector (not the photo) goes to the server. Privacy policy promise.
7. **Chart math must come from Swiss Ephemeris service.** Never ask Claude to calculate planetary positions.
8. **Paywall:** hard paywall after onboarding, ONE soft discount-rescue at 30% off on first decline only, then hard stop. No second paywall in same session (Apple Guideline 3.1.2(c) enforcement active April 2026).

---

## 🗂️ Session Protocol

### At the Start of a Session
1. Check the Quick Context table at the top of this file — confirm active branch and phase
2. Read `TASK.md` for current status and active work
3. Read `LEARNINGS.md` for recent gotchas and decisions
4. Run `git status` and `git log --oneline -5` to see what changed
5. Read any relevant `docs/` file for the feature you're touching
6. Ask for clarification on any ambiguity before writing code

### During a Session
- Work on branch `claude/initial-app-setup-hQvKZ` — never commit to `main`
- Commit frequently with conventional commit messages: `feat(palm-cv): add line segmentation overlay`
- Document decisions in code comments using `// DECISION:` prefix
- Flag any API key exposure immediately — check with `git status` before every commit
- Use `// TODO(lumina):` tags for deferred work, not inline fixups
- **No local macOS:** push to a `claude/**` branch and read CI logs to verify — `/build`, `/lint`, `/test` only work on a Mac. Where possible, validate Swift mentally against `.swiftlint.yml` rules, parse `project.yml` with `python3 -c 'import yaml'` after edits, and `bash -n` any shell scripts.

### At the End of a Session
1. Run `/session-end` for the full automated checklist, or manually:
2. Update `TASK.md` — mark completed `[x]`, in-progress `[~]`, add blockers
3. Update `LEARNINGS.md` — append new gotchas with `[2026-04]` date tag
4. CI runs `swiftlint lint --strict` on push — let it gate the merge
5. `git push -u origin claude/initial-app-setup-hQvKZ`
6. If RevenueCat entitlements changed, note in `LEARNINGS.md` under IAP section
7. Update the **Last updated** date in the Quick Context table above

---

## 🔗 Key External Resources

- [Anthropic API Docs](https://docs.anthropic.com) — Claude claude-opus-4-6 messages API
- [Swiss Ephemeris Docs](https://www.astro.com/swisseph/swisseph.htm) — Ephemeris service reference
- [RevenueCat iOS SDK](https://www.revenuecat.com/docs/getting-started/installation/ios) — IAP setup
- [Apple Vision Framework](https://developer.apple.com/documentation/vision) — `VNDetectHumanHandPoseRequest`
- [MediaPipe Hands](https://mediapipe.readthedocs.io/en/latest/solutions/hands.html) — alternate CV pipeline if needed
- [iOS 26 Liquid Glass HIG](https://developer.apple.com/design/human-interface-guidelines/) — Liquid Glass design guidance
- [OneSignal iOS](https://documentation.onesignal.com/docs/ios-sdk-setup) — Push notification setup
- [Supabase Swift](https://supabase.com/docs/reference/swift/introduction) — Backend client
- Competitive research: `docs/PRODUCT_SPEC.md`
