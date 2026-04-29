# TASK.md — Lumina Sprint Tracker

> Updated at the end of every Claude Code session.
> Format: `[STATUS] Task description — notes`
> Statuses: `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked

---

## 🔥 Active Sprint — Project Bootstrap

### Infrastructure
- [~] Initialize Xcode 17 project (SwiftUI, Swift 6, iOS 26 deployment target) — `project.yml` written; user must run `xcodegen generate` on macOS to materialize `Lumina.xcodeproj`
- [x] Configure Swift Package Manager dependencies (RevenueCat, Supabase, Lottie, OneSignal) — declared in `project.yml`; resolved on first Xcode open
- [x] Set up `project.xcconfig` + `scripts/inject_env.sh` for secrets injection
- [x] Configure SwiftLint `.swiftlint.yml` — strict mode (added `excluded:` for design-token files)
- [x] Configure SwiftFormat `.swiftformat`
- [x] Set up GitHub Actions CI workflow (type-check + lint + test) — `.github/workflows/ci.yml` runs on `macos-14`
- [ ] Set up TestFlight distribution via GitHub Actions + fastlane (Xcode Cloud is impractical without a local Mac to drive its setup) — needs Apple Developer Program enrollment, App Store Connect API key, signing P12, provisioning profile
- [!] Create Supabase project — auth, user_profiles table, pgvector extension — needs human account credentials

### Design System
- [x] Create `LuminaColors.swift` with full brand palette
- [~] Create `LuminaTypography.swift` — PP Editorial New + Söhne + GT America Mono — token file written, falls back to system fonts until license clears (see Blockers)
- [x] Create `LuminaSpacing.swift` — 8pt grid constants (`xs/sm/md/lg/xl/xxl`)
- [!] Install and register custom fonts in `Info.plist` — gated on font license
- [ ] Create `LuminaButton` component (primary, secondary, ghost variants)
- [ ] Create `LuminaCard` component with glass effect
- [ ] Create `LuminaTextField` component

### Core Services
- [x] **[2026-04-29]** `EphemerisService.swift` — actor wrapping Swiss Eph Node API. Real `URLSession` POST to `{baseURL}/chart` with `X-Lumina-Secret` header, structured `ServiceError` cases, lenient ISO 8601 decoder for the backend's fractional-second `calculatedAt`. Round-trip tested via `URLProtocol` mock.
- [~] `LuminaAIClient.swift` — actor wrapping Anthropic API — actor + key plumbing in place; HTTP body `// TODO(lumina)`
- [~] `IAPManager.swift` — RevenueCat actor, entitlement check helper — actor + `Entitlement` enum in place; SDK calls `// TODO(lumina)`

### Backend (Node.js Swiss Ephemeris service)
- [x] **[2026-04-29]** Fastify 5 + TS 5 scaffold; `astronomy-engine` for planet positions; zod request validation; X-Lumina-Secret auth; vitest (7 tests including missing-/null-`birthTime` paths); `npm run chart` CLI; runs on `node --experimental-strip-types` (no bundler). Live `/health` and `/chart` smoke-tested locally.
- [x] **[2026-04-29]** Wire `EphemerisService.chart()` in iOS to actually POST to the backend
- [x] **[2026-04-29]** House calculations — Placidus iterative cusps + closed-form Asc/MC + whole-sign fallback for |lat| ≥ 66.5°. Six new vitest cases. iOS `NatalChart.HouseCusps` model + decode test.
- [x] **[2026-04-29]** Aspects (sextile/square/trine/opposition/conjunction with 8°/6°/4° orbs, +2° for Sun/Moon involvement). Eight new vitest cases. iOS `NatalChart.Aspect` model.
- [ ] Sidereal house variant (subtract Lahiri ayanamsha from tropical longitudes)
- [ ] Aspects (sextile/square/trine/opposition/conjunction with orbs)
- [ ] Transits & progressions
- [ ] Swap `astronomy-engine` → `swisseph` once Swiss Ephemeris Pro license clears
- [ ] Production deploy (Fly.io: Dockerfile, healthcheck, secrets)
- [ ] In-memory LRU cache for repeated birth-data queries
- [ ] Rate limiting (Fastify plugin, key on X-Lumina-Secret)
- [ ] `HandPoseDetector.swift` — VNDetectHumanHandPoseRequest wrapper
- [ ] Supabase client singleton + auth session observer

### Onboarding Flow (7 screens)
- [ ] Screen 1: Brand promise (single serif sentence on parchment)
- [ ] Screen 2: Name + birth date (DatePicker)
- [ ] Screen 3: Birth time (wheel picker with "I don't know → use noon" option)
- [ ] Screen 4: Birth place (city autocomplete — MapKit / GeoCoder)
- [ ] Screen 5: Motivation tap (4 options — personalizes paywall copy downstream)
- [ ] Screen 6: Chart reveal animation (slow SVG wheel draw + Lottie)
- [ ] Screen 7: Palm scan intro (optional, skip available)
- [ ] Hard paywall screen (post-onboarding, $9.99/$59.99 with 7-day trial)
- [ ] RevenueCat paywall integration
- [ ] Notification permission request (deferred until AFTER paywall decision)

### Birth Chart Feature
- [ ] `ChartCalculator.swift` — fetch from EphemerisService, parse response
- [ ] Interactive birth chart wheel (custom Canvas/SwiftUI drawing)
- [ ] Planet/house tap → side sheet with plain-English interpretation
- [ ] House system toggle (Placidus default, Whole Sign, Sidereal)
- [ ] Share card generation (chart wheel PNG export)

### Daily Reading Feature
- [ ] `ContentGenerator.swift` — transit JSON → Claude prompt → reading
- [ ] `RAGRetriever.swift` — Supabase pgvector similarity search
- [ ] Daily reading view (editorial card layout)
- [ ] ElevenLabs audio playback (optional narration)
- [ ] Reading caching (SwiftData — invalidate on new transits)

### Palm Reading Feature
- [ ] `PalmCaptureSession.swift` — AVCapture live preview
- [ ] `HandPoseDetector.swift` — wrist/palm landmark detection
- [ ] Capture guidance UI (hand outline overlay, "move hand into frame")
- [ ] `LineSegmenter.swift` — Core ML U-Net inference
- [ ] Trace overlay view (renders segmented lines on captured image)
- [ ] Manual correction UI (drag handles on line endpoints)
- [ ] Palm feature extraction + Claude narration
- [ ] "How this works" transparency modal

---

## 📋 Backlog

### Compatibility
- [ ] Contact import with privacy permission flow
- [ ] Synastry chart (bi-wheel) generation
- [ ] Composite chart calculation
- [ ] Compatibility narrative view (percentage + 5 dimensions)
- [ ] Crush Report IAP ($4.99) — deep dive consumable

### Human Design
- [ ] Bodygraph SVG render from birth data
- [ ] Type / Profile / Authority plain-English cards
- [ ] Defined/undefined center interpretations

### Journal
- [ ] Daily prompt generation (tied to active transit)
- [ ] Journal entry SwiftData model
- [ ] Calendar/history view
- [ ] Pattern detection (after 30+ entries)

### Friends
- [ ] Friend profile via contact import
- [ ] Chart comparison view
- [ ] Deep-link share card (birth chart PNG + compatibility score)

### IAP Ladder
- [ ] Year Ahead ($11.99 consumable) — 12-month transit forecast
- [ ] Career Forecast ($7.99 consumable)
- [ ] Ask the Stars ($2.99 — 10 Claude credits)
- [ ] Discount-rescue paywall (30% off, first decline only)

### Notifications
- [ ] OneSignal integration + token registration
- [ ] Daily morning push (7:30–9:00 AM local, 4–10 word blunt copy)
- [ ] Weekly "week ahead" Sunday push
- [ ] Event-triggered: eclipse, retrograde, ingress (cap at 5/week)

---

## ✅ Completed

- [x] Set up `.claude/settings.json` — bash permissions, Stop hook checklist, PreToolUse secrets guard
- [x] Create `.claude/commands/` — `/build`, `/lint`, `/test`, `/chart`, `/new-feature`, `/session-end`
- [x] Update `CLAUDE.md` — Quick Context table, active branch, optimized session protocol
- [x] Configure `.swiftlint.yml` — strict mode (pre-existing)
- [x] **[2026-04-29]** Phase 0 bootstrap — `project.yml`, design tokens, service-actor stubs, `RootView` splash, CI workflow, secrets injection. Branch `claude/initial-app-setup-hQvKZ`.

---

## 🚧 Blockers

| Blocker | Impact | Owner |
|---|---|---|
| PP Editorial New font license — confirm purchase | Design system blocked | — |
| Swiss Ephemeris Pro license (CHF 1,550) — purchase + server setup | Daily reading blocked | — |
| ElevenLabs voice ID — record brand voice | Audio reading blocked | — |
| Custom palm U-Net model — train on PolyU/CASIA data or find pre-trained | Palm CV blocked | — |
| Supabase RAG corpus — curate + embed (Liz Greene, Steven Forrest, Robert Hand) | AI readings blocked | — |
