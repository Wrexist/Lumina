# TASK.md — Lumina Sprint Tracker

> Updated at the end of every Claude Code session.
> Format: `[STATUS] Task description — notes`
> Statuses: `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
> See `ROADMAP.md` for the full 16-phase plan and `docs/NAVIGATION.md` for IA & UX rules.

---

## 🔥 Active Sprint — Phase 1: Navigation Shell + Design System v2

> Branch: `claude/roadmap-navigation-improvements-yqxV2`
> Goal: ship the empty 5-tab shell, design-system v2 components, and routing primitives so every feature phase can plug in without reinventing navigation.

### Routing & app state
- [~] `AppRouter.swift` — `@Observable` root state machine — initial scaffold landed on this branch; persistence via `@AppStorage` still pending
- [~] `LuminaTab` enum + raw values matching deep-link slugs — initial scaffold landed
- [~] `MainTabsView.swift` — `TabView` selection bound to `AppRouter` — initial scaffold landed
- [~] `LuminaDeepLink` enum + `URL` parser — initial scaffold landed; full case coverage + tests pending
- [ ] Per-tab `NavigationStack` with typed `NavigationPath`
- [ ] Persist last-selected tab + nav path across launches via `@AppStorage`

### Design system v2 components
- [~] `LuminaButton` (primary / secondary / ghost / destructive variants) — initial scaffold landed
- [~] `LuminaCard` with `.glassBackgroundEffect()` — initial scaffold landed
- [~] `LuminaTextField` — initial scaffold landed; inline error treatment pending
- [~] `LuminaEmptyState(icon, title, body, primaryCTA)` — initial scaffold landed
- [~] `LuminaErrorState(error: LuminaError)` — initial scaffold landed
- [~] `LuminaSkeleton` shimmer — initial scaffold landed
- [~] `LuminaBadge` for "Premium" / "Beta" / "New" — initial scaffold landed
- [~] `GlossaryLink("term")` view modifier + `GlossaryStore` — initial scaffold landed; full corpus pending
- [x] **[2026-05-08]** `LuminaSegmentedControl` (house-system / chart-mode picker) — initial scaffold landed
- [x] **[2026-05-08]** `LuminaConfirmationDialog` wrapper for destructive actions
- [x] **[2026-05-08]** `LuminaShadows` token set (subtle / card / elevated)
- [x] **[2026-05-08]** `LuminaRadii` token set + `.luminaCornerRadius(_:)` view modifier
- [ ] SwiftLint rule blocking raw `.cornerRadius(...)` literals outside `Design/Tokens/`

### Errors & plumbing
- [x] **[2026-05-08]** `LuminaError.swift` sum type with `userTitle` / `userBody` / `recoveryActionTitle` / `analyticsKey`
- [x] **[2026-05-08]** Error-mapping extension on `EphemerisService.ServiceError` and `URLError` via `LuminaError.from(_:)`
- [x] **[2026-05-08]** Error-mapping extension on `LuminaAIClient.ClientError` via `LuminaError.from(_:)`
- [x] **[2026-05-08]** `AppLock.swift` — Face ID / device-passcode gate (`@MainActor @Observable`, session-scoped unlocks, `LAContext` evaluation, structured `LockError` for mapping)
- [x] **[2026-05-08]** `Haptics.swift` — light / medium / heavy / selection / success / warning / failure wrappers honoring Reduce Motion

### SwiftLint
- [ ] Custom rule `lumina_no_dead_end_list` — flag `LazyVStack` / `List` / `ForEach` over a model collection without an empty branch (deferred — needs AST, not regex)
- [~] `lumina_no_modal_on_modal` — left as a PR-review checklist item; regex-based detection is unreliable
- [x] **[2026-05-08]** Custom rule `no_raw_corner_radius` — flag `.cornerRadius(...)` outside `Design/Tokens/`
- [x] **[2026-05-08]** Custom rule `no_raw_shadow` — flag `.shadow(color:` outside `Design/Tokens/`

### Project hygiene
- [x] **[2026-05-08]** `.gitignore` already lists `Lumina.xcodeproj/` (verified)
- [ ] Coverage reporter target so PR diffs surface % delta

---

## 📋 Backlog — Phase 2: Onboarding v2

- [~] 8 onboarding screen views — placeholder screens shipped end-to-end (`OnboardingScreens.swift`); polish + real DatePicker / MapKit / chart-reveal animation pending
- [x] **[2026-05-08]** `OnboardingProgressBar` (8 dots, no labels)
- [x] **[2026-05-08]** `OnboardingState` `@Observable` model + resume-on-kill persistence via `OnboardingStorage` (UserDefaults / in-memory). SwiftData migration deferred until SwiftData enters the project broadly.
- [ ] Inline debounced validation on every field
- [ ] "Why we ask" link on every sensitive field
- [ ] MapKit city autocomplete + manual lat/lon fallback
- [ ] Soft post-onboarding paywall offer (not a hard wall) with explicit "Continue free"
- [ ] Discount rescue paywall (once per install)
- [ ] Sign in with Apple (deferred to after first chart reveal)
- [ ] Deferred notification permission (after first daily reading)
- [ ] 14 onboarding analytics events
- [ ] "Update birth info" Settings surface that reuses these forms

---

## 📋 Backlog — Phase 3: Today

- [ ] `TodayView` — hero card + transit summary + quick-actions row
- [ ] `DailyReadingViewModel`
- [ ] `ContentGenerator.swift` (transits → RAG → claude-opus-4-6)
- [ ] ElevenLabs TTS via Node `/generate-audio`
- [ ] Audio cache (FileManager, 7-day TTL, 50MB LRU)
- [ ] Daily reading SwiftData cache (invalidate at midnight)
- [ ] Quick-actions horizontal scroller
- [ ] Empty + offline + error states
- [ ] Server-side daily-reading throttle (Supabase edge function)
- [ ] OneSignal daily push 7:30–9:00 AM local
- [ ] "Why this reading?" transparency sheet showing transit JSON + 3 RAG snippets

---

## 📋 Backlog — Phase 4: Birth Chart

- [ ] `BirthChartView` layout (wheel 55% / interpretations below)
- [ ] Chart wheel `Canvas` renderer (single-pass, 60fps)
- [ ] Glyph hit-testing dictionary (44pt touch targets)
- [ ] `PlanetDetailView` `.sheet(item:)`
- [ ] House system `LuminaSegmentedControl`
- [ ] Unknown-birth-time graceful state
- [ ] Retrograde dashed-orbit ring
- [ ] Aspect legend expandable card
- [ ] Zodiac sign profile sheet
- [ ] Share card via `ImageRenderer`
- [ ] Deep-link `lumina://chart/planet/<name>` handler
- [ ] Big 3 (Sun / Moon / Rising) band at top of Chart tab
- [ ] "Read my chart aloud" Premium narration (90s audio)

---

## 📋 Backlog — Phase 5: Daily Reading + Audio

- [ ] Audio playback bar (sticky)
- [ ] Background audio + `MPNowPlayingInfoCenter` artwork
- [ ] AirPlay 2 / CarPlay support
- [ ] "Pin reading" Premium feature → Library
- [ ] Reading reactions (this was you / off / not today)

---

## 📋 Backlog — Phase 6: Palm Reading

- [ ] `PalmScanView` with hand outline guide + lighting indicator
- [ ] Real-time hand pose overlay
- [ ] Auto-capture trigger
- [ ] `LineSegmenter` Core ML actor
- [ ] Mask post-processing (morph close + Hilditch skeletonization)
- [ ] Trace-overlay Canvas
- [ ] Manual correction handles
- [ ] `PalmFeatureExtractor`
- [ ] Palm narration via claude-opus-4-6
- [ ] `PalmReadingView` (4 accordion cards + synthesis)
- [ ] "How this works" transparency modal
- [ ] SwiftData `PalmReading` storage
- [ ] History view
- [ ] Free-tier scan gating
- [ ] Pre-capture practice run animation
- [ ] Both-hands flow
- [ ] Skip-without-narration path

---

## 📋 Backlog — Phase 7: Compatibility (People tab)

- [ ] `CompatibilityView` entry (3 add paths)
- [ ] Contact import via `CNContactStore`
- [ ] Manual friend entry form
- [ ] `Friend @Model`
- [ ] Backend `/synastry` endpoint
- [ ] Backend `/composite` endpoint
- [ ] Backend `/davison` endpoint
- [ ] Synastry bi-wheel `Canvas` renderer
- [ ] Compatibility score (deterministic)
- [ ] LLM 5-dimension report
- [ ] Compatibility result view
- [ ] Share card
- [ ] Crush Report IAP $4.99
- [ ] Friend graph list
- [ ] "Don't know their time?" path
- [ ] Privacy disclosure card
- [ ] Encrypted Supabase friends backup (Premium)

---

## 📋 Backlog — Phase 8: Human Design (lives in Chart tab)

- [ ] HD Swift wrapper (gates / channels / centers / type / profile / authority)
- [ ] `BodygraphData` model
- [ ] Bodygraph SVG renderer
- [ ] Center fill states (defined / undefined / split)
- [ ] Type / Profile / Authority cards (zero jargon)
- [ ] Center detail sheets
- [ ] HD glossary integration with `GlossaryLink`
- [ ] Astrology-HD crossover callouts
- [ ] `HumanDesignViewModel`
- [ ] Premium gate (type + profile free)

---

## 📋 Backlog — Phase 9: Reflect (Journal)

- [ ] `JournalPromptGenerator`
- [ ] `JournalEntryView` with debounced auto-save
- [ ] `JournalEntry @Model` (encrypted at rest)
- [ ] Calendar history view
- [ ] Entry detail view
- [ ] Word counter (no streaks)
- [ ] `FetchDescriptor` search
- [ ] Pattern detection after 30th entry
- [ ] Monthly pattern view (Premium)
- [ ] Premium gate (3 free, then paywall)
- [ ] Face ID lock toggle
- [ ] Markdown export (Premium)
- [ ] Sensitive-prompt softer alternative path

---

## 📋 Backlog — Phase 10: People (Friends)

- [ ] `FriendsListView`
- [ ] QR code generator + scanner
- [ ] Chart comparison view
- [ ] `ShareCardGenerator.swift` (consolidates 4 share-card types)
- [ ] Friend discovery opt-in (hashed phone, default OFF)
- [ ] Friend-added push notification
- [ ] Privacy controls
- [ ] Group reading Premium feature
- [ ] Soft-delete with 5s undo

---

## 📋 Backlog — Phase 11: Notifications + Engagement

- [ ] OneSignal SDK integration + token registration + 4 segments
- [ ] Daily morning push
- [ ] Weekly "week ahead" Sunday push (Premium)
- [ ] Event-triggered pushes (eclipse, retrograde, ingress) capped at 5/week
- [ ] Settings: granular toggles per push type
- [ ] "No weekend notifications" toggle
- [ ] Quiet hours (default 9pm–7am)

---

## 📋 Backlog — Phase 12: Settings, Account, Privacy Dashboard

- [ ] `SettingsView` with all 5 sections
- [ ] `EditBirthInfoView` (reuses onboarding forms)
- [ ] Manage subscription deep link
- [ ] Restore purchases action + toast
- [ ] Sign out flow
- [ ] `PrivacyDashboardView` ("what we know / what we don't")
- [ ] Export-my-data → JSON archive via `.fileExporter`
- [ ] Delete-account flow (3-step + 30-day grace + local wipe)
- [ ] Help & FAQ view
- [ ] Send feedback via `MFMailComposeViewController`
- [ ] Open-source acknowledgements view

---

## 📋 Backlog — Phase 13: Search, Glossary, Help Center

- [ ] `GlossaryStore` — 200+ entries in `Resources/Glossary.json`
- [ ] CI script ensuring every astrological term in shipped UI is wrapped in `GlossaryLink`
- [ ] `SearchView` (pull-down on Today)
- [ ] Search analytics (top-100 queries)
- [ ] Help threading (12 root topics, 25 articles)

---

## 📋 Backlog — Phase 14: Accessibility, Localization, Performance

- [ ] VoiceOver audit pass — zero unlabeled interactive elements
- [ ] Dynamic Type audit — Accessibility XL clean across all primary screens
- [ ] Reduce Motion audit — every animation has crossfade fallback
- [ ] Color contrast audit (WCAG 2.1 AA)
- [ ] Instruments Time Profiler — cold launch < 1.5s on iPhone 13
- [ ] Instruments Allocations — peak memory < 150MB during palm CV
- [ ] Instruments Energy Log — clean background suspension
- [ ] 500-item LazyVStack scroll perf at 60fps
- [ ] Localization scaffold via String Catalogs (`.xcstrings`) — EN + ES at launch
- [ ] RTL audit
- [ ] Voice Control test pass
- [ ] Crash reporting integration (Sentry or Apple Diagnostics)
- [ ] Memory leak gate (Instruments Leaks zero on TestFlight cut)
- [ ] Battery test (≤ 8% drain in 30min active use on iPhone 13)

---

## 📋 Backlog — Phase 15: Beta + Compliance + 1.0.0

- [ ] App Store screenshots (6.9in + 6.5in, all 10 slots)
- [ ] App Store preview video
- [ ] App Store metadata (title / subtitle / description / keywords)
- [ ] Privacy policy at lumina.app/privacy
- [ ] Terms of service at lumina.app/terms
- [ ] App Store Connect Privacy Nutrition Label
- [ ] `PrivacyInfo.xcprivacy` manifest
- [ ] TestFlight beta with 100 external testers
- [ ] Beta feedback triage (P0/P1 fixed pre-submission)
- [ ] Pre-submission compliance review (3.1.2(c), 5.1.1, 4.3, 1.1.6, 1.4.4)
- [ ] Press kit at lumina.app/press
- [ ] Launch checklist
- [ ] gitleaks final pass
- [ ] First-week support rota staffed

---

## 📋 Backlog — Cross-cutting (parallel to phases)

### Backend
- [x] **[2026-04-29]** Fastify + TS scaffold; astronomy-engine; `/chart`; vitest
- [x] **[2026-04-29]** Wire `EphemerisService.chart()` to backend
- [x] **[2026-04-29]** Placidus iterative cusps + closed-form Asc/MC + whole-sign fallback
- [x] **[2026-04-29]** 5 Ptolemaic aspects with orbs
- [x] **[2026-04-29]** Sidereal house variant via Lahiri ayanamsha
- [ ] Transits & progressions endpoints
- [ ] `/synastry`, `/composite`, `/davison` endpoints
- [ ] Swap `astronomy-engine` → `swisseph` once Pro license clears
- [ ] Production deploy to Fly.io (Dockerfile, healthcheck, secrets, auto-sleep)
- [ ] In-memory LRU cache (key on birth-data hash)
- [ ] Rate limiting (Fastify plugin keyed on `X-Lumina-Secret`)
- [ ] ElevenLabs `/generate-audio` endpoint
- [ ] RAG corpus chunking + embedding pipeline (~1,940 chunks)
- [ ] pgvector HNSW index post-insert
- [ ] Edge function for daily-reading throttle

### SwiftData migrations
- [ ] `SchemaMigrationPlan` from version 1 onward (no shipping without one)
- [ ] Encryption at rest for `JournalEntry` (CryptoKit + Keychain)

### Test strategy
- [ ] Snapshot test harness (3 sizes × 2 schemes per shipped View)
- [ ] Integration test: `/chart` against astro.com 5 fixed dates per CI run
- [ ] `docs/QA_SCRIPTS.md` with 15 manual flows that block release

### Observability
- [ ] Crash reporting
- [ ] Custom analytics (≤ 60 events)
- [ ] Backend health dashboard
- [ ] AI cost dashboard with daily anomaly alerts

---

## ✅ Completed

- [x] **[2026-04-29]** Phase 0 bootstrap — `project.yml`, design tokens, service-actor stubs, `RootView` splash, CI workflow, secrets injection
- [x] **[2026-04-29]** SwiftLint strict + custom rules for hex / fonts / magic spacing
- [x] **[2026-04-29]** Backend Fastify + TS ephemeris MVP (Placidus + Whole-Sign + Sidereal + 5 aspects + tests)
- [x] **[2026-04-29]** iOS `EphemerisService` actor with HTTP round-trip + decode tests
- [x] **[2026-05-08]** New 16-phase ROADMAP.md cut, navigation IA spec at `docs/NAVIGATION.md`, branch `claude/roadmap-navigation-improvements-yqxV2`
- [x] **[2026-05-08]** Phase 1 starter scaffolding landed: `AppRouter`, `LuminaTab`, `LuminaDeepLink`, `MainTabsView`, design-system v2 components (`LuminaButton`, `LuminaCard`, `LuminaTextField`, `LuminaSegmentedControl`, `LuminaSkeleton`, `LuminaEmptyState`, `LuminaErrorState`, `LuminaBadge`, `LuminaError`, `GlossaryLink`/`GlossaryStore`)
- [x] **[2026-05-08]** Phase 1 sprint follow-up: `LuminaRadii` + `LuminaShadows` tokens, `Haptics` wrapper, `LuminaConfirmationDialog` extension, `LuminaError.from(_:)` mapping for `EphemerisService.ServiceError` and `URLError`. Migrated existing components to the new tokens. Added `DesignTokensAndErrorTests` covering token monotonicity, error mapping, and analytics-key uniqueness.

---

## 🚧 Blockers

| Blocker | Impact | Owner |
|---|---|---|
| PP Editorial New font license — confirm purchase | Type system locked to fallback | — |
| Swiss Ephemeris Pro license (CHF 1,550) | Cannot swap from astronomy-engine | — |
| ElevenLabs voice ID — record brand voice session | Phase 5 audio blocked | — |
| Custom palm U-Net Core ML model — train on PolyU/CASIA | Phase 6 blocked | — |
| Supabase project credentials | Auth + RAG corpus blocked | — |
| Apple Developer enrollment + signing artifacts | TestFlight + App Store launch blocked | — |
| Legal review of fortune-telling framing copy | App Review risk | — |
