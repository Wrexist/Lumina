# TASK.md — Lumina Sprint Tracker

> Updated at the end of every Claude Code session.
> Format: `[STATUS] Task description — notes`
> Statuses: `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked

---

## 🔥 Active Sprint — Project Bootstrap

### Infrastructure
- [ ] Initialize Xcode 17 project (SwiftUI, Swift 6, iOS 26 deployment target)
- [ ] Configure Swift Package Manager dependencies (RevenueCat, Supabase, Lottie, OneSignal)
- [ ] Set up `Config.xcconfig` + `scripts/inject_env.sh` for secrets injection
- [ ] Configure SwiftLint `.swiftlint.yml` — strict mode
- [ ] Configure SwiftFormat `.swiftformat`
- [ ] Set up GitHub Actions CI workflow (type-check + lint + test)
- [ ] Set up Xcode Cloud for TestFlight distribution
- [ ] Create Supabase project — auth, user_profiles table, pgvector extension

### Design System
- [ ] Create `LuminaColors.swift` with full brand palette
- [ ] Create `LuminaTypography.swift` — PP Editorial New + Söhne + GT America Mono
- [ ] Create `LuminaSpacing.swift` — 8pt grid constants
- [ ] Install and register custom fonts in `Info.plist`
- [ ] Create `LuminaButton` component (primary, secondary, ghost variants)
- [ ] Create `LuminaCard` component with glass effect
- [ ] Create `LuminaTextField` component

### Core Services
- [ ] `EphemerisService.swift` — actor wrapping Swiss Eph Node API
- [ ] `LuminaAIClient.swift` — actor wrapping Anthropic API (claude-opus-4-6)
- [ ] `IAPManager.swift` — RevenueCat actor, entitlement check helper
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

*(Nothing yet — project in bootstrap phase)*

---

## 🚧 Blockers

| Blocker | Impact | Owner |
|---|---|---|
| PP Editorial New font license — confirm purchase | Design system blocked | — |
| Swiss Ephemeris Pro license (CHF 1,550) — purchase + server setup | Daily reading blocked | — |
| ElevenLabs voice ID — record brand voice | Audio reading blocked | — |
| Custom palm U-Net model — train on PolyU/CASIA data or find pre-trained | Palm CV blocked | — |
| Supabase RAG corpus — curate + embed (Liz Greene, Steven Forrest, Robert Hand) | AI readings blocked | — |
