# TASK.md — Lumina Sprint Tracker

> Updated at the end of every Claude Code session.
> Format: `[STATUS] Task description — notes`
> Statuses: `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
> See `ROADMAP.md` for the full 16-phase plan and `docs/NAVIGATION.md` for IA & UX rules.

---

## 📌 Latest — Full app review: critical fixes + tab declutter (2026-07-02, branch `claude/app-review-improvements-8w40x9`)

Four parallel review passes over the whole app, then fixes:

- [x] **Birth instant correctness** — pickers were sent verbatim (wrong day/time zone for every chart); new `BirthMoment` anchors instants at the birth place; QR payload now shares Y/M/D components; zone-aware compatibility scoring
- [x] **Human Design corrections** — mandala `zeroOffset` was one gate off (0° Aries now correctly Gate 25); centers define only via complete channels
- [x] **Palm CV** — Vision landmarks rescaled to pixel space (aspect-ratio skew misclassified hand types)
- [x] **Onboarding** — resume-after-paywall no longer loses birth data; wheel defaults commit; back-and-edit invalidates the computed chart
- [x] **Reflect** — no more phantom calendar entries; soft-delete/editor crash paths closed; softer-prompt escape hatch wired up
- [x] **Today freshness** — day rollover + birth-info edits now reload; transit failure shows retry instead of false "quiet sky"; 10s request timeouts
- [x] **Tab declutter** — Today 11 blocks → 6 with one coordinated load + skeletons; Chart wheel promoted to hero; Palm hub merged to one honest card; Settings "Soon" rows collapsed to footnotes
- [x] **Round 3 — progression & delight** (same branch): chart discovery band (placements as a collection), Moments milestone system + timeline (anti-streak), daily "Know your chart" quiz from the real chart, daily reading reveal ritual
- [ ] Follow-ups parked: transit alerts re-plan on launch/birth-edit (currently die after 5), config guards for unexpanded `$(...)` placeholders, Sign in with Apple nonce, paywall price from the StoreKit product, daily reflection reminder (new-feature idea)

---

## 📌 App capabilities: IAP, push, auth, universal links, 3D Moon (2026-07-01, branch `claude/app-capabilities-plan-br64fe`)

Full plan at `docs/CAPABILITIES-PLAN.md`. Turns an Xcode capabilities audit
("Push Notifications: No", "Sign in with Apple: No", "Associated Domains: No",
"In-App Purchase: no explicit toggle but `Purchases.configure()` never
called") into real, shipped code:

- [x] RevenueCat wired for real (`IAPManager`, `PremiumStatus`, onboarding trial + Settings rows)
- [x] OneSignal wired for real (`PushNotificationManager`, single permission prompt, Palm waitlist tag)
- [x] Sign in with Apple + Keychain session (`AuthManager`, `SignInView`), Supabase exchange layered on best-effort
- [x] Universal links (`https://lumina.app/...`) alongside `lumina://`; QR share migrated; `apple-app-site-association` ready to deploy
- [x] Immersive 3D Moon (`MoonSphere3DView`, SceneKit) — the real ephemeris phase angle drives the lit/dark terminator; "View in 3D" on the Today "Tonight's Moon" card
- [ ] Background Modes (`audio`) — deliberately deferred until Phase 5's audio player exists
- [!] Owner action items outstanding: RevenueCat/OneSignal/Supabase dashboards, `lumina.app` domain + hosting, Apple Developer capability registration — see `docs/CAPABILITIES-PLAN.md` "Owner action items"

---

## 📌 Growth + Release infra (2026-07, branch `claude/adoring-euler-yEDvq`)

Viral/dopamine features (all CI-green, merged via PR #5):
- [x] Cosmic signature — identity card + richer shareable profile
- [x] Shareable compatibility result (send-it-to-them loop)
- [x] Share today's reading (daily distribution loop)
- [x] New-moon / full-moon rituals on the Moon card
- [x] "What makes your chart rare" curiosity-gap standout
- [x] Onboarding reveal → instant shareable "meet your signature" moment
- [x] **Home-screen Cosmic Signature widget** (Sun · Moon · Rising) — WidgetKit extension, App Group, green first try

Release / store (this commit):
- [x] `ios-testflight.yml` — signed device archive → TestFlight via ASC API-key cloud signing (workflow_dispatch)
- [x] `ios/ExportOptions.plist`, version indirection (app+widget in lockstep)
- [x] `docs/TESTFLIGHT.md` (secret checklist + Apple-side runbook) · `docs/APP-STORE-LISTING.md` (copy-paste, ASO-optimized)
- [!] Actual TestFlight upload — blocked on Apple Developer signing + the 3 ASC secrets (owner action; see `docs/TESTFLIGHT.md`)
- [ ] Conversational "Ask your chart" — blocked on Anthropic key provisioning

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

- [~] 8 onboarding screen views — all 8 wired with real validation, "Why we ask" sheets, MapKit autocomplete, and real `EphemerisService` call on reveal; final polish (animation choreography, inline error transitions) pending
- [x] **[2026-05-08]** `OnboardingProgressBar` (8 dots, no labels)
- [x] **[2026-05-08]** `OnboardingState` `@Observable` model + resume-on-kill persistence via `OnboardingStorage` (UserDefaults / in-memory). SwiftData migration deferred until SwiftData enters the project broadly.
- [x] **[2026-05-08]** Inline validation on `Name`, `BirthDate`, `BirthPlace` via `OnboardingState.validationMessage(for:)`
- [x] **[2026-05-08]** "Why we ask" inline explainer (`WhyWeAsk` view) on every sensitive field (Name, BirthDate, BirthTime, BirthPlace)
- [x] **[2026-05-08]** MapKit `BirthPlaceSearch` autocomplete; user picks a suggestion to capture lat/lon + IANA time zone
- [x] **[2026-05-08]** `OnboardingScreens.ChartReveal` calls real `EphemerisService.chart(for:)` and falls through to synthesised readiness on missing-config dev builds
- [x] **[2026-05-08]** Manual lat/lon fallback (`ManualBirthPlaceSheet`) for offline / geocoder-down cases — name, lat, lon, IANA time-zone picker
- [x] **[2026-05-08]** Soft post-onboarding paywall offer (`PaywallOfferView`, `.fullScreenCover`) on the WhatNext step with explicit "Continue free"
- [x] **[2026-05-08]** Discount rescue paywall (once per install, gated by `PaywallTracker`)
- [x] **[2026-07-01]** Sign in with Apple — `AuthManager`/`SignInView` shipped and reachable from Settings (not yet the contextual post-chart-reveal prompt originally scoped here — that placement refinement is still open). The Supabase identity-token exchange is best-effort and no-ops until the project exists; see `docs/CAPABILITIES-PLAN.md` §3.
- [~] Deferred notification permission — `NotificationPermission` helper landed and reachable from Settings; the contextual prompt after the first daily reading lands with the Today tab build-out
- [ ] 14 onboarding analytics events
- [ ] "Update birth info" Settings surface that reuses these forms
- [x] **[2026-05-08]** `UserBirthDataStore` writes `BirthData` to UserDefaults on completion so every other tab can read from one source

---

## 📋 Backlog — Phase 3: Today

- [x] **[2026-05-08]** `TodayHubView` — hero + Big-3 + headline + transit list + quick-actions row, all wired
- [x] **[2026-05-08]** `TodayViewModel` — loads natal chart from `UserBirthDataStore`, falls through to sample chart on missing-config dev builds
- [x] **[2026-06-03]** Real transits replace the fabricated headline pool — `TodayViewModel` fetches `/transits` concurrently with the chart; `todayLines(from:)` + `TransitPhrasing` render the tightest contact as the headline and up to 3 secondary rows, with an honest "a quiet sky today" empty state
- [ ] `ContentGenerator.swift` (transits → RAG → claude-opus-4-6)
- [ ] ElevenLabs TTS via Node `/generate-audio`
- [ ] Audio cache (FileManager, 7-day TTL, 50MB LRU)
- [ ] Daily reading SwiftData cache (invalidate at midnight)
- [x] **[2026-05-08]** Quick-actions horizontal scroller wired to `AppRouter.selectedTab` for in-app deep-link to Chart / Reflect / People / Palm
- [ ] Empty + offline + error states for the audio/reading card
- [ ] Server-side daily-reading throttle (Supabase edge function)
- [ ] OneSignal daily push 7:30–9:00 AM local
- [ ] "Why this reading?" transparency sheet showing transit JSON + 3 RAG snippets

---

## 📋 Backlog — Phase 4: Birth Chart

- [x] **[2026-05-08]** `ChartHubView` layout (mode picker, big-3, wheel, house picker, interpretations card)
- [x] **[2026-05-08]** Chart wheel `Canvas` renderer (`ChartWheelView`, single-pass, Asc-aligned rotation)
- [x] **[2026-05-08]** Glyph hit-testing via overlay `Button`s with 44pt touch targets
- [x] **[2026-05-08]** `PlanetDetailSheet` `.sheet(item:)` with degree, sign, house, retrograde, copy-stub interpretation
- [x] **[2026-05-08]** House system `LuminaSegmentedControl` wired to `BirthChartViewModel.reload()`
- [x] **[2026-05-08]** Big 3 (Sun / Moon / Rising) band
- [x] **[2026-05-08]** Aspect lines through chart center, color + weight by aspect type
- [x] **[2026-05-08]** Unknown-birth-time graceful state — banner above the wheel + houses already hidden in the renderer
- [x] **[2026-05-08]** Retrograde marker — small "℞" glyph drawn just outside each retrograde planet
- [x] **[2026-05-08]** `AspectLegend` expandable card — five aspect types with color swatches, line widths, degrees, plain-English meaning
- [x] **[2026-05-08]** `lumina://chart/planet/<name>` deep-link handler — Chart tab consumes `AppRouter.pendingPresentation` and presents the matching `PlanetDetailSheet`
- [ ] Zodiac sign profile sheet (tap a sign glyph on the wheel)
- [ ] Share card via `ImageRenderer`
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

- [x] **[2026-05-08]** `PalmHubView` — empty-state shell, "How this works" sheet, differentiator card, premium card, blocker note. The full capture pipeline lands when the Core ML palm U-Net is available (currently blocked).
- [x] **[2026-05-08]** "How this works" transparency modal (`PalmTransparencyView`) — 5-step pipeline explainer + privacy promise card
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
- [ ] SwiftData `PalmReading` storage
- [ ] History view
- [ ] Free-tier scan gating
- [ ] Pre-capture practice run animation
- [ ] Both-hands flow
- [ ] Skip-without-narration path

---

## 📋 Backlog — Phase 7: Compatibility (People tab)

- [x] **[2026-05-08]** `Friend @Model` (UUID id, name, birth date/time/place, source enum, cached compatibilityScore)
- [x] **[2026-05-08]** Manual friend entry form (`AddFriendView`) reusing the Phase-2 MapKit `BirthPlaceSearch` plus a "time unknown" toggle
- [x] **[2026-05-08]** Friend list + detail (`PeopleHubView`, `FriendDetailView`) with score badge, score card, birth-info card, remove via `LuminaConfirmationDialog`
- [x] **[2026-05-08]** Compatibility score (`CompatibilityScorer.score(_:_:)`) — symmetric, range-bounded, element + modality-aware. Replace with synastry-aspect-weighted algorithm once `/synastry` lands.
- [x] **[2026-05-08]** "Don't know their time?" path — toggle on `AddFriendView` defaults `birthTime` to nil
- [x] **[2026-05-08]** Privacy disclosure card on `PeopleHubView` (empty + populated states)
- [x] **[2026-05-08]** Share-my-chart QR (`ShareQRView`) — encodes `BirthData` as `lumina://share/<base64-json>` via CoreImage CIQRCodeGenerator
- [ ] Contact import via `CNContactStore` filtered by birthday
- [ ] QR scanner (`AVCaptureMetadataOutput`)
- [ ] Backend `/synastry` endpoint
- [ ] Backend `/composite` endpoint
- [ ] Backend `/davison` endpoint
- [ ] Synastry bi-wheel `Canvas` renderer
- [ ] LLM 5-dimension report
- [ ] Crush Report IAP $4.99
- [ ] Encrypted Supabase friends backup (Premium)

---

## 📋 Backlog — Phase 8: Human Design (lives in Chart tab)

- [x] **[2026-05-08]** `HumanDesignMandala` — 64-gate sequence at 5.625°/gate, gate-and-line by ecliptic longitude
- [x] **[2026-05-08]** `HumanDesignCenter` — 9 centers + complete gate ownership (64 gates exactly once, disjoint)
- [x] **[2026-05-08]** `HumanDesignActivation.compute(from:)` — natal chart → personality-side activations + defined centers
- [x] **[2026-05-08]** `BodygraphView` — Canvas renderer with tappable centers (defined / open) on a normalised 0–1 layout
- [x] **[2026-05-08]** `CenterDetailSheet` — per-center activated gates + which planet activated each
- [x] **[2026-05-08]** Chart-tab Astrology / Human Design segmented control wired through to the bodygraph
- [ ] Design-side "88° solar arc" chart (requires backend `/design` endpoint) → Type / Profile / Authority
- [x] **[2026-05-08]** Channel rendering — full 36-channel `HumanDesignChannels.all` table; defined channels (both gates activated) render as a Canvas line bridging the two centers
- [ ] HD glossary integration with `GlossaryLink`
- [ ] Astrology-HD crossover callouts
- [ ] Premium gate (type + profile free)

---

## 📋 Backlog — Phase 9: Reflect (Journal)

- [x] **[2026-05-08]** `JournalPromptGenerator` (deterministic per-day pool + softer-prompt counterpart + transit-key shape; LLM-backed transit pipeline lands with Phase 5)
- [x] **[2026-05-08]** `JournalEntryView` with 1s debounced auto-save and live word count
- [x] **[2026-05-08]** `JournalEntry @Model` (UUID id, date, prompt, body, transitKey, wordCount, createdAt, updatedAt)
- [x] **[2026-05-08]** `JournalCalendarView` month-grid with entry-dot indicators
- [x] **[2026-05-08]** `JournalEntryDetailView` read-only with edit / delete via `LuminaConfirmationDialog`
- [x] **[2026-05-08]** Word counter (no streaks, no celebratory animation)
- [x] **[2026-05-08]** `@Query(sort:order:)` fetch with `LazyVStack`-style `ForEach` for recents (5) and full calendar
- [ ] Pattern detection after 30th entry (LLM batch — wires with Phase 5 pipeline)
- [ ] Monthly pattern view (Premium)
- [~] Premium gate — soft Plus banner once entries.count ≥ 3; full paywall gating ships with RevenueCat in Phase 16
- [x] **[2026-05-08]** Face ID lock toggle persisted via `AppPreferences`; `ReflectHubView` shows a locked screen and routes through `AppLock.unlock(.reflectTab)`
- [ ] Markdown export (Premium)
- [x] **[2026-05-08]** Sensitive-prompt softer alternative path (`JournalPromptGenerator.softerPrompt(for:)`); UI tap-out wires when the LLM transit pipeline lands
- [x] **[2026-05-08]** `ModelContainer(for: JournalEntry.self)` registered at `LuminaApp` `WindowGroup`

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

> OneSignal wiring plan (AppDelegate init, capability/entitlement, token
> registration, segment tagging): `docs/CAPABILITIES-PLAN.md` §2.

- [x] **[2026-05-08]** `NotificationPermission` helper — `@MainActor @Observable`, `request()`/`refreshStatus()`, `Status` enum mapped from `UNAuthorizationStatus`
- [x] **[2026-05-08]** `NotificationSettingsView` reachable from Settings → Notifications (state-aware CTA: turn on / open iOS Settings / all set)
- [ ] OneSignal SDK integration + token registration + 4 segments
- [ ] Daily morning push (wired through OneSignal)
- [ ] Weekly "week ahead" Sunday push (Premium)
- [ ] Event-triggered pushes (eclipse, retrograde, ingress) capped at 5/week
- [ ] Granular per-push-type toggles in NotificationSettingsView
- [ ] "No weekend notifications" toggle
- [ ] Quiet hours (default 9pm–7am)

---

## 📋 Backlog — Phase 12: Settings, Account, Privacy Dashboard

- [x] **[2026-05-08]** `SettingsView` with all 5 sections wired to the gear icon
- [x] **[2026-05-08]** `EditBirthInfoView` — reuses Phase-2 `BirthPlaceSearch` and `WhyWeAsk`; hydrates from `UserBirthDataStore`, writes back on save; manual-coordinates fallback
- [x] **[2026-05-08]** `PrivacyDashboardView` — "what's on this device / what's on our server / what's never stored" with live counts from SwiftData and UserDefaults
- [x] **[2026-07-01]** Manage subscription deep link — opens the App Store subscriptions page from Settings. `docs/CAPABILITIES-PLAN.md` §1
- [x] **[2026-07-01]** Restore purchases action + toast — Settings row calls `IAPManager.restorePurchases()`, shows a `LuminaSnackbarView` result. `docs/CAPABILITIES-PLAN.md` §1
- [x] **[2026-07-01]** Sign out flow — Settings "Sign out" row via `AuthManager.signOut()`; clears Keychain session only, never local SwiftData. `docs/CAPABILITIES-PLAN.md` §3
- [ ] `PrivacyDashboardView` ("what we know / what we don't")
- [ ] Export-my-data → JSON archive via `.fileExporter`
- [ ] Delete-account flow (3-step + 30-day grace + local wipe)
- [x] **[2026-05-08]** Help & FAQ view (`HelpView`) — 12 hand-written articles across 6 topics, `.searchable` over title + body
- [~] Send feedback — in-app form shipped (`FeedbackView`); MFMailComposeViewController + diagnostic-dump attachment still pending
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
- [x] **[2026-06-03]** `/transits` endpoint — transit→natal cross-aspects (tight orbs, applying/separating, sorted by orb) + pure `computeTransits` lib, 13 tests; shared `requireSharedSecret` auth helper
- [ ] Progressions endpoint (secondary progressions)
- [ ] `/synastry`, `/composite`, `/davison` endpoints
- [ ] Swap `astronomy-engine` → `swisseph` once Pro license clears
- [ ] Production deploy to Fly.io (Dockerfile, healthcheck, secrets, auto-sleep)
- [ ] In-memory LRU cache (key on birth-data hash)
- [ ] Rate limiting (Fastify plugin keyed on `X-Lumina-Secret`)
- [ ] ElevenLabs `/generate-audio` endpoint
- [ ] RAG corpus chunking + embedding pipeline (~1,940 chunks)
- [ ] pgvector HNSW index post-insert
- [ ] Edge function for daily-reading throttle

### App capabilities

> Full plan (Xcode capabilities, code, owner action items, sequencing):
> `docs/CAPABILITIES-PLAN.md`.

- [x] **[2026-07-01]** RevenueCat core wiring — `IAPManager` calls `Purchases.configure/purchase/restore` for real, dev-safe no-op without a real key; `PremiumStatus` mirror; wired into onboarding trial + Settings "Manage subscription"/"Restore purchases". No new Xcode capability needed. Still needs a real `REVENUECAT_API_KEY_IOS` + RevenueCat dashboard config to do anything live. Plan §1.
- [x] **[2026-07-01]** OneSignal core wiring — `PushNotificationManager` + `AppDelegate` init + `NotificationPermission` routing (one prompt, not two) + Palm waitlist tag. Push Notifications capability + entitlement added to `project.yml`. (The broadcast-capability key `com.apple.developer.usernotifications.channel` was later **removed** — it failed the signed TestFlight archive because the capability isn't enabled on the App ID and nothing uses channel pushes yet; re-add once provisioned.) End-to-end push delivery still needs a signed device build. Plan §2.
- [x] **[2026-07-01]** Sign in with Apple — `AuthManager` (Keychain session, works standalone) + `SignInView` + `SupabaseAuthService` (best-effort identity-token exchange, no-ops until Supabase exists) + real Settings row (sign in / sign out). Plan §3.
- [x] **[2026-07-01]** Associated Domains / universal links — `LuminaDeepLink` parses `https://lumina.app/...` alongside `lumina://`; QR share migrated; `web/apple-app-site-association` + `web/README.md` ready to deploy once the domain exists. Plan §4.
- [ ] Background Modes (`audio`) — deliberately **not** added yet; add only when Phase 5's audio player ships. Adding it now would recreate the exact "capability with nothing behind it" anti-pattern this audit exists to fix. Plan §5.

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

### ✅ Audit remediation pass — [2026-06-03], branch `claude/adoring-euler-yEDvq`

Full audit at `docs/AUDIT-2026-06-03.md`; fixes (all CI-verified once build settles):

- [x] **CI unblocked** — root-caused 369 pre-existing SwiftLint violations from `brew`-latest pulling rules the codebase never satisfied (207 `switch_case_on_newline` alone). Reconciled `.swiftlint.yml` to the house style; lint + backend green again.
- [x] **R0 launch integrity** — added `Assets.xcassets` (AppIcon + AccentColor), `Localizable.xcstrings`, `PrivacyInfo.xcprivacy`; `UIUserInterfaceStyle: Light`.
- [x] **R1 data integrity** — fixed the journal blank-entry insert (`NavigationLink` eager destination), `ModelContext.saveOrLog`, cusp-count guards, `@Attribute(.unique)`, future-day calendar guard, score-out-of-body.
- [x] **R2 security** — Reflect Face ID re-locks on background; share QR carries reduced `SharedBirthData` (no exact time/precise coords) via base64url; Anthropic key removed from the shipped Info.plist.
- [x] **R3 paywall** — rescue offer now actually presents (in-place variant swap); honest trust copy; `PaywallTracker` seen/declined split.
- [x] **R4 navigation** — `settings`/`help`/`share` deep links resolve; pending links replayed post-onboarding; ChartHubView cold-launch race fixed; QR share round-trip implemented (`AcceptShareView`); HelpView nested-stack removed.
- [x] **R5/R6** — stable `CompatibilityScorer` hash; Today renders all 4 states (sample fallback `#if DEBUG`); accessible error color; Dynamic Type scaling; secure-field a11y; "1th house" ordinal; Settings dead-end chevrons removed; HD "defined → activated (personality-side)" honesty copy.
- [x] **R7 backend** — noon-local timezone correctness, host-TZ-independent CLI, constant-time secret compare, rate limiter, security headers, body-size cap, birthDate bounds, Dockerfile + fly.toml (30 → 43 tests).
- [x] **[2026-06-03]** Onboarding per-step persistence + WhatNext card routing (land on the chosen tab) + planet-glyph de-clustering (`ChartWheelLayout`, conjunct glyphs stack at staggered radii).
- [ ] Remaining backlog (R8): soft-delete-with-undo, gitleaks/coverage CI gates, snapshot tests, native iOS 26 glass API.

### ✅ Feature pass — real transits + chart-wheel — [2026-06-03], branch `claude/adoring-euler-yEDvq`

All CI-verified (runs #52, #54 green on Xcode 26.3 / iOS 26; backend 56 tests):

- [x] **Real "today" transits** — retired the fabricated day-of-year headline pool (literal hallucinated planetary positions) in favour of the real backend computation. Backend `/transits` (transit→natal cross-aspects, tight 2–3° orbs, applying/separating derived from `isRetrograde`, solar-return contacts kept); iOS `EphemerisService.transits(for:at:)`, `TransitReading`/`TransitsResult` models, pure `TransitPhrasing`, and `TodayViewModel` fetching chart + transits concurrently. Honest "a quiet sky today" empty state.
- [x] **Chart-wheel glyph de-clustering** — `ChartWheelLayout` stacks conjunct planet glyphs at staggered radii (circle cut at largest gap to handle the 0°/360° seam) so each stays legible and tappable.
- [x] **Shared backend auth** — extracted constant-time `requireSharedSecret` used by `/chart` and `/transits`.

### ✅ Audit pass 2 — premium / clarity / a11y — [2026-06-04], branch `claude/adoring-euler-yEDvq`

Full audit at `docs/AUDIT-2026-06-04.md`. Landed:

- [x] **Premium glyphs** — zodiac/planet glyphs forced to monochrome text (U+FE0E) so they render in brand gold, never OS colour-emoji. Caught by the new CI screenshot render. Regression-tested.
- [x] **Copy clarity** — purged all user-facing roadmap phase numbers + dev jargon ("Anthropic/ElevenLabs", "RAG", "Core ML", "endpoint", "Export to JSON", "Phase N" badges) across ~10 screens; refreshed stale synastry copy.
- [x] **Real synastry in People** — `FriendDetailView` shows real chart-to-chart aspects (`SynastryPhrasing`) via the backend `/synastry` endpoint, replacing the date-only placeholder.
- [x] **Dynamic Type** — `LuminaTypography` already scales (text styles); fixed the 8 remaining hero/icon `.system(size:)` sites with `@ScaledMetric` (+ `minimumScaleFactor` in HStacks). VoiceOver labels swept — only an invisible placeholder needed hiding.
- [x] **No-Mac UI preview** — `ScreenshotTests` renders key screens to PNGs; CI uploads them as artifacts and emits base64 in the log for retrieval through the egress allowlist.
- [ ] Remaining: glossary inline-term affordance (R-GLOSS-1); soft-delete-with-undo (R-NAV-1); gitleaks + coverage CI gates.

### ✅ Grounded interpretation engine + synastry depth — [2026-06-04], branch `claude/adoring-euler-yEDvq`

The unblocked grounding layer beneath the (blocked) conversational/RAG reading.
All CI-verified (runs #63, #66 green):

- [x] **`PlacementInterpreter`** — per-placement readings (planet × sign × house × retrograde); wired into `PlanetDetailSheet`, replacing the "coming soon" card.
- [x] **`AspectInterpreter`** + Chart-tab "Your strongest aspects" card — every real aspect interpreted in plain language.
- [x] **Synastry depth** — `CompatibilityScorer.score(fromSynastry:)` (real aspect-weighted 0–100, replaces the date heuristic in Friend detail) + `SynastrySummary` (relationship-dynamic headline) in `FriendDetailView`.
- [x] **"Ask your chart"** (deterministic) — `ChartOracle` + `ChartQAView`: tap a curated question, get an answer read from the real chart (Big 3 / strongest aspect / dominant element / retrogrades / focal planet). The honest, unblocked version of the category's #1 gap.
- [x] **"Why these?" transparency sheet** (Today) — shows the exact transit data behind the reading (COMPETITIVE-ANALYSIS gap G7).
- [x] **Browsable Glossary screen** — surfaces the previously-unused `Glossary.json` content, linked from Help.
- [ ] Next (unblocked): Big-3 tappable interpretations; transit-tied Reflect prompts; soft-delete-with-undo.
- [!] Blocked (need provisioning): conversational free-text "ask your chart" + RAG daily reading (Supabase + Anthropic key); narrated audio (ElevenLabs); palm pipeline (Core ML model).

### ✅ Excellence sprint — timing / relationships / palm / sharing / notifications — [2026-06-05], branch `claude/adoring-euler-yEDvq`

Worked top-down through `docs/EXCELLENCE-PLAN.md`. All CI-verified (runs #77–#80 green; notifications + palm + share in #81). Backend 97 tests.

- [x] **"What's coming" forecast** — backend `/forecast` root-finds the exact instant each transiting aspect perfects over a window (`lib/forecast.ts` sign-change + bisect); iOS `ForecastView` + Today "What's coming" card. The category's "timing" promise, done for real.
- [x] **Composite chart** — backend `/composite` (shorter-arc midpoint merge + aspect engine, `lib/composite.ts`); iOS `CompositeCard` ("your relationship as one chart") in Friend detail.
- [x] **Moon phase** — backend `/moon` (angle + illumination + next new/full via astronomy-engine); Today "Tonight's Moon" card with the matching SF Symbol.
- [x] **Big-3 tappable readings** — Sun/Moon → `PlanetDetailSheet`, Rising → new `AscendantInterpreter` + `AscendantDetailSheet`.
- [x] **Transit-tied Reflect prompt** — `TransitPrompt` shapes the journal prompt from the day's strongest transit; falls back to the date pool offline.
- [x] **Local transit notifications** — opt-in, on-device (`UNUserNotificationCenter`, no OneSignal), capped at 5, delivered 9am on the day, never doom. `TransitNotificationPlanner` + `TransitNotificationScheduler` + Settings toggle.
- [x] **Palm Phase A engine** — `PalmReader` + `PalmFeatureExtractor` derive the four classical hand types from real geometry, with a compile-checked `VNHumanHandPoseObservation` adapter. Fully unit-tested; live capture UI is the remaining device-gated piece.
- [x] **Share your chart** — `ChartShareCard` rendered via `ImageRenderer` → PNG → `ShareLink` from the Chart toolbar (`ChartShareButton`).
- [x] **Secondary progressions** — backend `/progressions` (day-for-a-year) + Today "Your current chapter" card (progressed Moon/Sun, `ProgressedChapter`).
- [x] **Gitleaks secret-scan CI gate** — new `secrets` job + `.gitleaks.toml` allowlist; enforces "no keys in source" automatically (CI-verified green).
- [ ] Next (unblocked): soft-delete + undo; empty-state pass; motion/haptics polish; app icon; coverage CI gate; returns/retrogrades; palm live-capture UI (device).

### ✅ Excellence sprint II — timing depth / UX / brand — [2026-06-06], branch `claude/adoring-euler-yEDvq`

Continued top-down through `docs/EXCELLENCE-PLAN.md`. All CI-verified green; backend 119 tests.

- [x] **Retrogrades** — backend `/retrogrades` (apparent-velocity root-finding for current state + next station) + Today "Retrogrades" card (hidden when the sky is clear). The "is Mercury retrograde?" question, for real.
- [x] **Returns** — backend `/returns` (next Jupiter/Saturn return, numbered by count since birth) + an imminent-only Today card (shows within a year).
- [x] **Soft-delete + Undo** — `LuminaSnackbarView` + deferred-commit `.task(id:)`; swipe (People) / long-press (Reflect), recoverable for ~4s.
- [x] **App icon** — refined gold crescent + sparkle on midnight (replaces the flat orb); `scripts/generate_app_icon.mjs` (dependency-free Node PNG encoder, opaque RGB).
- [x] **Reduce-motion fix** — the in-app override was a dead toggle; `LuminaMotion` now combines it with the OS setting (LuminaButton/LuminaSkeleton).
- [x] Empty-state pass verified (new cards hide when empty; lists have empty states); more backend edge tests (composite antipodal, direct-planet retrograde).
- [ ] Deferred: coverage CI gate (needs a Mac-measured baseline to avoid breaking CI); snapshot-harness scale-up; palm live-capture UI (device).

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
