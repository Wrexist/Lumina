# ROADMAP.md — Lumina Complete Development Roadmap

> 12 phases · 34 build weeks · 147 tracked tasks · iOS 26 App Store

---

## Quick Reference

| Phase | Name | Weeks | Tasks | Est. |
|---|---|---|---|---|
| 0 | Bootstrap | 1–2 | 14 | 10 dev-days |
| 1 | Core Infrastructure | 3–6 | 19 | 16 dev-days |
| 2 | Onboarding + Paywall | 7–9 | 14 | 12 dev-days |
| 3 | Birth Chart | 10–12 | 12 | 11 dev-days |
| 4 | Daily Reading | 13–15 | 13 | 10 dev-days |
| 5 | Palm Reading | 16–19 | 15 | 16 dev-days |
| 6 | Compatibility | 20–23 | 15 | 14 dev-days |
| 7 | Human Design | 24–26 | 13 | 10 dev-days |
| 8 | Journal | 27–28 | 10 | 7 dev-days |
| 9 | Friends + Social | 29–30 | 9 | 6 dev-days |
| 10 | Polish + App Store | 31–34 | 20 | 14 dev-days |
| 11 | Post-Launch + v2 | Month 9–18 | 12 | 24+ dev-weeks |

---

## Infrastructure Cost at Scale (10k MAU)

| Service | Monthly Cost | Notes |
|---|---|---|
| Anthropic Claude claude-opus-4-6 | ~$1,344 | Daily readings + palm + compatibility at 70% DAU |
| ElevenLabs TTS | ~$22 | Creator plan, 30k+ chars/month |
| Supabase Pro | ~$25 | pgvector + auth + storage |
| OneSignal | ~$9 | Growth plan |
| Fly.io (Swiss Eph backend) | ~$7 | Hobby plan, auto-sleep |
| **Total infra** | **~$1,407/month** | 1.76% of $79,920 net revenue |

One-time costs: Swiss Ephemeris Pro license CHF 1,550 (~$1,750) · PP Editorial New font license ~$400 · ElevenLabs voice clone session ~$0 (included in Creator plan)

---

## Phase 0 — Bootstrap
**Weeks 1–2 · 10 dev-days**

Xcode project initialization, CI/CD pipeline, design system, secrets management, Supabase backend setup.

### Tasks

- [ ] Initialize Xcode 17 project — SwiftUI app template, Swift 6 strict concurrency enabled, iOS 26 deployment target, bundle ID `com.lumina.app`
- [ ] Add Swift Package Manager dependencies: RevenueCat 5.x, Supabase Swift 2.x, Lottie iOS 4.x, OneSignal XCFramework 5.x
- [ ] Configure `.swiftlint.yml` — strict mode, custom rules blocking raw hex color literals, hardcoded font names, magic spacing numbers in views
- [ ] Configure `.swiftformat` — trailing commas, sorted imports, consistent blank lines
- [ ] Set up `Config.xcconfig` + `scripts/inject_env.sh` — secrets injection pipeline from `.env.local` into Xcode build
- [ ] GitHub Actions CI — 6-job workflow: SwiftLint, build + type-check, unit tests, Swift 6 concurrency audit (data races as errors), gitleaks, Node.js backend
- [ ] Xcode Cloud — archive + TestFlight workflow, signing certificates, provisioning profiles
- [ ] `LuminaColors.swift` — full brand palette + dark mode adaptive variants
- [ ] `LuminaTypography.swift` — PP Editorial New + Söhne + GT America Mono with ViewModifier helpers
- [ ] `LuminaSpacing.swift` — 8pt grid system, semantic aliases, corner radii
- [ ] Create full project folder structure with `.gitkeep` and README stubs
- [ ] Create placeholder stub actors for all Core services with TODO comments
- [ ] Install and register custom fonts in `Info.plist` UIAppFonts
- [ ] Supabase project — enable pgvector, run schema migrations, configure RLS policies

### Acceptance Criteria

- `xcodebuild build` passes with zero warnings on iPhone 16 Pro simulator
- All 6 CI jobs green on first push to `main`
- SwiftLint `--strict` produces zero violations
- All 3 custom font families render in `#Preview` macro
- `scripts/inject_env.sh` generates valid `Config.xcconfig` from `.env.example`
- Supabase live with pgvector active, RLS enabled on all tables

### Tech Notes

- Swift 6 strict concurrency ON from day 1 — retrofitting later costs 3× the time
- Use `@Observable` (iOS 17+) not `@Published` — never mix Combine and Observable in the same project
- `ModelContainer` injected at app root in `LuminaApp.swift`, not at feature level
- PP Editorial New requires paid font license from Production Type — confirm before design work

### Risk Flags

- PP Editorial New license (~$400) — order immediately, delivery can take days
- Swiss Ephemeris Pro license (CHF 1,550) needed before Phase 1 backend build — order in Week 1
- Xcode Cloud free tier is limited — upgrade to paid plan if CI minutes exceeded

---

## Phase 1 — Core Infrastructure
**Weeks 3–6 · 16 dev-days**

Swiss Eph Node.js backend, EphemerisService actor, RevenueCat IAP, Supabase auth, Palm CV pipeline, RAG corpus embedding.

### Tasks

- [ ] Build Swiss Ephemeris Node.js microservice — Fastify + TypeScript + `sweph` npm, `/chart`, `/transits`, `/composite`, `/health` endpoints
- [ ] Ephemeris service — input validation, error handling, bearer token auth, rate limiting (1k req/min)
- [ ] Deploy ephemeris service to Fly.io — HTTPS, auto-sleep, health check pings, environment secrets
- [ ] `EphemerisService.swift` actor — bearer auth, fetch + cache, all domain models
- [ ] Define all domain models: `Planet`, `HouseCusp`, `Aspect`, `ChartData`, `TransitData`, `BirthData`, `HouseSystem` enum
- [ ] Supabase auth — Sign in with Apple + email magic link, session observer on `@MainActor`
- [ ] `IAPManager.swift` actor + `PurchasesDelegate` — `isPremium` entitlement, consumable tracking, typed errors
- [ ] RevenueCat project setup — link App Store Connect, create all offerings, configure 6 products
- [ ] `RAGRetriever.swift` — Supabase pgvector cosine similarity, transit-keyed queries, top-3 retrieval
- [ ] `LuminaAIClient.swift` actor — Anthropic API client, all 4 generation endpoints
- [ ] Chunk + embed RAG corpus (~1,940 chunks total across 4 books) via `text-embedding-3-small`, HNSW index
- [ ] Write all AI system prompt `.txt` files (4 prompts)
- [ ] `PalmCaptureSession.swift` — AVCaptureSession, CMSampleBuffer pipeline, lighting assessment
- [ ] `HandPoseDetector.swift` — `VNDetectHumanHandPoseRequest`, 21 landmarks, palm bounding box
- [ ] Train/adapt palm line segmentation Core ML model — U-Net, PolyU/CASIA data, target mIoU ≥ 0.88, < 25MB quantized
- [ ] `LineSegmenter.swift` — Core ML inference, 256×256 ROI, 4-channel mask output, morphological closing
- [ ] `PalmFeatureExtractor.swift` — skeletonization, geometric feature extraction
- [ ] OneSignal SDK integration, push token registration, 4 segments
- [ ] Unit tests for all Core services

### Acceptance Criteria

- Swiss Eph `/chart` returns correct positions within ±1° for 5 test birth dates
- `EphemerisService` returns `ChartData` in < 300ms from network, < 5ms from cache
- `IAPManager.isPremium` updates within 1s of sandbox purchase event
- `RAGRetriever` returns relevant chunks for 8/10 test transit queries (manual review)
- Palm CV pipeline processes test hand image: all 4 line masks detected, mIoU ≥ 0.88
- All unit tests pass on CI, coverage > 60% on Core services

### Tech Notes

- Swiss Eph AGPL: buy Pro license before ANY server commit that uses the library
- Core ML model: quantize with 6-bit palettization + structured pruning in `coremltools 7.x`
- pgvector HNSW index: `CREATE INDEX ON corpus_chunks USING hnsw (embedding vector_cosine_ops)` after all chunks inserted
- ElevenLabs audio generated server-side (Node.js backend) — iOS binary must not contain ElevenLabs API key
- Palm CV confidence threshold: reject captures with hand pose confidence < 0.85

### Risk Flags

- Core ML model training requires GPU access and PolyU dataset license — start as parallel track in Week 1
- RAG corpus requires legally obtained books — do not scrape or violate copyright
- RevenueCat + StoreKit 2 sandbox testing requires physical device — simulator IAP is unreliable

---

## Phase 2 — Onboarding + Paywall
**Weeks 7–9 · 12 dev-days**

7-screen onboarding flow, chart reveal animation, hard paywall, Supabase auth, deferred notification permission.

### Tasks

- [ ] Screen 1 — Brand promise: PP Editorial New italic, parchment background, 0.8s fade-in, no skip
- [ ] Screen 2 — Name + birth date: TextField + DatePicker wheel
- [ ] Screen 3 — Birth time: wheel picker + "I don't know — use noon" equally prominent
- [ ] Screen 4 — Birth place: MapKit city autocomplete, time zone confirmation
- [ ] Screen 5 — Motivation: 4 tap targets, stores in UserDefaults, seeds paywall copy
- [ ] Screen 6 — Chart reveal: SVG wheel draw animation + Lottie + audio chime
- [ ] Screen 7 — Palm scan intro: optional, live preview, prominent skip
- [ ] `OnboardingViewModel` — state machine, persists to SwiftData on completion
- [ ] `NavigationPath` with resume-on-kill persistence
- [ ] Hard paywall view — personalized feature list, $9.99/$59.99, 7-day trial, cancel instructions, RevenueCat
- [ ] Discount rescue paywall — fires once on first decline, 30% off promo offer
- [ ] Supabase Sign in with Apple flow, create `user_profiles` row
- [ ] Deferred notification permission — contextual, post-paywall
- [ ] Onboarding analytics — all 14 key events tracked

### Acceptance Criteria

- Full onboarding completes in < 90 seconds (timed)
- "I don't know" path: chart loads, ASC/MC hidden, no crash
- Chart reveal animation at 60fps on iPhone 13
- RevenueCat sandbox: trial starts, subscription activates post-trial
- Rescue paywall fires exactly once per install on first decline
- Sign in with Apple: `user_profile` created in Supabase within 5s
- `NavigationPath` survives app kill at any step

### Tech Notes

- MapKit geocoder: add offline fallback (manual coordinate entry) for airplane mode
- Chart reveal: precompute all positions in background `Task` before animation starts
- Motivation type stored in `UserDefaults` before auth — paywall reads it before SwiftData is ready
- Never show `$0.33/day` framing — Apple Guideline 3.1.2(c) enforcement active April 2026

### Risk Flags

- App Review may reject palm-reading onboarding as "fortune telling" — frame as "AI analysis" + entertainment disclaimer
- MapKit geocoder requires `com.apple.developer.maps` entitlement in provisioning profile

---

## Phase 3 — Birth Chart
**Weeks 10–12 · 11 dev-days**

Interactive Canvas wheel, planet tap detail sheets, house system toggle, share card generator, deep-link handler.

### Tasks

- [ ] `BirthChartView` — wheel (55% of screen) + interpretations scroll below
- [ ] Chart wheel Canvas renderer — 12 houses, zodiac ring, 10 planet glyphs, 5 aspect line types, retro markers
- [ ] Planet glyph hit-testing — CGRect bounding box dictionary, 44pt touch targets
- [ ] `PlanetDetailView` `.sheet(item:)` — degree, sign, house, retrograde, RAG interpretation
- [ ] House system picker — Placidus / Whole Signs / Sidereal segmented control
- [ ] `BirthChartViewModel` — EphemerisService fetch, planet interpretation cache
- [ ] Unknown birth time handling — hide house cusps, informational banner
- [ ] Retrograde dashed orbit ring visual
- [ ] Aspect legend expandable card
- [ ] Zodiac sign tap — 3-sentence sign profile sheet
- [ ] Share card via `ImageRenderer` — 1080×1080 and 1080×1920
- [ ] Deep-link inbound handler — `lumina://chart/{base64BirthData}`

### Acceptance Criteria

- Correct planet positions for 3 test dates verified against astro.com
- All 10 planet taps respond with correct detail sheet
- House system toggle re-renders in < 400ms
- Share card exports at 2× without memory warning
- Unknown birth time: no crash, ASC/MC hidden, banner shows
- Deep-link round-trip works between two devices

### Tech Notes

- Canvas single-pass rendering required for 60fps — no individual SwiftUI shapes per element
- Render order: house arcs → zodiac ring → aspect lines → planet glyphs
- `ImageRenderer` requires `@MainActor` and synchronous render

### Risk Flags

- Canvas hit-testing is manual math — budget 2 extra days
- `ImageRenderer` crashes if view has lazy-loaded content — pre-load all glyphs before export

---

## Phase 4 — Daily Reading
**Weeks 13–15 · 10 dev-days**

Transit-grounded Claude reading, RAG retrieval, ElevenLabs TTS audio, SwiftData caching, daily morning push.

### Tasks

- [ ] `DailyReadingViewModel` — TransitData fetch, ContentGenerator call, audio state management, refresh throttle
- [ ] `ContentGenerator.swift` — transits → RAG → LLM prompt → `ReadingContent`
- [ ] Reading generation: transits JSON + 3 RAG chunks → claude-opus-4-6, 800 tokens, temp 0.7
- [ ] ElevenLabs TTS — Node.js `/generate-audio` endpoint, iOS downloads and caches MP3
- [ ] Audio cache — FileManager, keyed by transitKey, 7-day TTL, 50MB LRU eviction
- [ ] `DailyReadingView` — date header (GT Mono small-caps), mood glyph, PP Editorial New title, Söhne body
- [ ] Audio playback bar — sticky, ElevenLabs voice avatar, play/pause, 15s skip, scrub
- [ ] "What's happening in your sky" — 3-card collapsible transit summary
- [ ] SwiftData `DailyReading` cache — invalidate at midnight or transitKey change
- [ ] Share card — `ImageRenderer` title + mood glyph + wordmark
- [ ] Skeleton loading state — Lottie constellation animation
- [ ] Offline graceful degradation — cached reading, relative timestamp
- [ ] Server-side refresh throttle — 1×/day/user via Supabase edge function
- [ ] OneSignal daily push — transit-specific copy, 7:30–9:00 AM local, planet glyph image

### Acceptance Criteria

- Reading body references at least one natal placement (verified for 10 test users)
- Generation in < 3s on 4G (p95 across 20 calls)
- Audio plays without buffering on 4G
- Cached reading loads in < 50ms
- Push at correct local time ± 5min
- AI cost per reading < $0.01

### Tech Notes

- Never stream LLM response — render atomically when complete
- ElevenLabs API key must NOT be in iOS binary — generate server-side
- TransitKey deterministic from BirthData + calendar date — no randomness

### Risk Flags

- RAG corpus quality is the primary lever — manually review 30+ generated readings before launch
- ElevenLabs Starter = 30k chars/month — upgrade to Creator ($22/mo) before 1k users

---

## Phase 5 — Palm Reading
**Weeks 16–19 · 16 dev-days**

On-device Core ML line segmentation, trace overlay, manual correction handles, AI narration, transparency modal. The category's most significant technical differentiator.

### Tasks

- [ ] `PalmScanView` — full-screen AVCapture, hand outline SVG guide, lighting indicator, palm fill %
- [ ] Real-time hand pose overlay — `VNDetectHumanHandPoseRequest` on each frame, 21 landmarks when confidence > 0.85
- [ ] Auto-capture trigger — pose confidence > 0.92, fill 40–70%, lighting ≥ 0.4, stable 500ms
- [ ] `LineSegmenter` actor — Core ML U-Net inference, 256×256 grayscale ROI, 4-channel Float32 mask
- [ ] Line mask post-processing — morphological closing, Hilditch skeletonization, connected-component labeling
- [ ] Trace overlay Canvas — life (sage), heart (blush), head (celestial), fate (gold) over captured image
- [ ] Manual correction UI — DragGesture handles on start/end/midpoints, commit on CTA
- [ ] `PalmFeatureExtractor` — normalized length, curvature, branch count, endpoint positions
- [ ] Palm narration: PalmFeatures JSON + ChartData → claude-opus-4-6, 600 tokens, temp 0.4 → `PalmNarration`
- [ ] `PalmReadingView` — 4 accordion cards + synthesis card with chart crossover callout
- [ ] "How this works" transparency modal — shows actual segmentation mask, confirms no photo upload
- [ ] SwiftData `PalmReading` storage — features, reading text, trace PNG path
- [ ] History view — LazyVStack of past scans with trace thumbnails
- [ ] Free tier enforcement — 1 scan/month gated, upgrade prompt on 2nd attempt
- [ ] Capture failure states — LowLighting, HandNotDetected, HandTooSmall, HandObscured (each with illustration)

### Acceptance Criteria

- Line detection succeeds ≥ 80% in standard indoor lighting across 20 diverse hands
- End-to-end time < 4s on iPhone 13
- Trace overlay pixel-aligned with captured image (no drift)
- Manual correction handles drag at 60fps
- Transparency modal shows actual segmentation mask from current scan
- Network traffic confirmed: no palm photo bytes in outbound requests (Charles/Proxyman test)
- Free tier: scan #2 correctly blocked with paywall

### Tech Notes

- Core ML inference on Vision framework queue (background), deliver to `@MainActor` via `MainActor.run`
- Store capture resolution in `PalmCaptureSession`, scale overlay Canvas to match exactly
- Transparency modal: save actual Float32 mask as normalized grayscale `UIImage` at capture time
- Palm image cleared from memory immediately after Core ML inference

### Risk Flags

- Core ML model mIoU < 0.88 on diverse skin tones — build balanced Fitzpatrick scale test set
- Lighting failures will be top complaint — budget 3 days for guidance UX
- Apple may flag as "fortune telling" — copy must state AI analysis + entertainment framing

---

## Phase 6 — Compatibility
**Weeks 20–23 · 14 dev-days**

Synastry bi-wheel, composite chart, 5 narrative dimensions, contact import, Crush Report IAP.

### Tasks

- [ ] `CompatibilityView` entry — 3 add paths: contact import, manual entry, QR scan
- [ ] Contact import — `CNContactStore`, filter by birthday, privacy prompt copy
- [ ] Manual friend entry form — name + birth date + optional time/place
- [ ] `Friend @Model` — name, birthDate, birthTime?, birthLat/Lon?, importSource, compatibilityScore
- [ ] Swiss Eph `/synastry` endpoint — two BirthData → inter-chart aspects + bi-wheel JSON
- [ ] Swiss Eph `/composite` endpoint — midpoint composite from two birth dates
- [ ] Synastry bi-wheel Canvas renderer — outer ring (A), inner ring (B), inter-chart aspect lines
- [ ] `CompatibilityViewModel` — synastry + composite + LLM orchestration
- [ ] Compatibility score algorithm — weighted aspects, normalized 0–100
- [ ] Score label mapping — Magnetic/Harmonious/Stimulating/Challenging
- [ ] LLM report — 5 narrative dimensions, 60–100 words each
- [ ] Compatibility result view — score badge, label, 5 expandable cards, bi-wheel
- [ ] Share card — "X% compatible with [name]" + label + glyph, 1080×1080 and 1080×1920
- [ ] Crush Report IAP ($4.99) — Davison chart + transits-to-composite + timing windows
- [ ] Friend graph list — compatibility %, sort/search, pull-to-refresh

### Acceptance Criteria

- Synastry bi-wheel renders correct inter-chart aspects for 3 test pairs (astrodienst.com verification)
- Compatibility score is deterministic regardless of A/B order
- All 5 narrative dimensions present, each > 50 words
- Contact import < 2s for 500 contacts
- Crush Report unlocks within 5s of sandbox purchase
- Share card renders correctly in iOS share sheet

### Tech Notes

- `/synastry` and `/composite` endpoints must be stubbed in Phase 1 backend
- Store Friend records only in SwiftData — never sync to server
- Bi-wheel Canvas: outer ring at 90% radius, inner at 65%
- Compatibility score seeded deterministically from both birthDate values

### Risk Flags

- Contact permission rejection rate ~40% — contextual copy and timing critical
- Bi-wheel Canvas renderer most complex drawing in app — allocate 3 dedicated days

---

## Phase 7 — Human Design
**Weeks 24–26 · 10 dev-days**

Bodygraph SVG renderer, Type/Profile/Authority cards, HD glossary, astrology-HD crossover callouts. No competitor ships this in a polished consumer interface.

### Tasks

- [ ] Human Design calculation — Swift wrapper for bodygraph logic (gates, channels, centers, type, profile, authority)
- [ ] `BodygraphData` model — type, profile, authority, definedCenters, openCenters, channels, activatedGates
- [ ] Bodygraph SVG renderer — 9 centers as geometric shapes, channel lines, gate numbers
- [ ] Center fill logic — defined: solid fill per HD color, undefined: hollow with stroke
- [ ] Split definition rendering — visual gap in split bodygraphs
- [ ] Type card — 3 sentences, strategy, signature, not-self, zero HD jargon
- [ ] Profile card — life theme + role narrative, 2 sentences
- [ ] Authority card — "how you make aligned decisions" specific to user's type
- [ ] Center detail sheets — tap any center for plain-English meaning
- [ ] HD glossary — A–Z searchable, NavigationLink from every bolded term
- [ ] Astrology-HD crossover callouts — HD gate aligns with natal planet within 1°
- [ ] `HumanDesignViewModel` — compute from BirthData, cache in SwiftData
- [ ] Premium gate — type + profile free, full bodygraph + authority + centers locked

### Acceptance Criteria

- Bodygraph renders correct type/profile/authority for 5 test dates (myBodyGraph.com verification)
- All 9 centers with correct defined/undefined state and HD color
- Zero unexplained HD jargon in Type/Profile/Authority cards (team review)
- HD glossary accessible from all bolded terms in all HD cards
- Premium gate shows correct gated state and upgrade prompt

### Tech Notes

- Use standard HD color palette inside bodygraph only — not Lumina brand palette
- Bodygraph SVG uses absolute pixel positions (400×600 canonical) — scale with `containerRelativeFrame`
- HD calculation edge cases: test 50+ birth dates against myBodyGraph.com

### Risk Flags

- Ra Uru Hu's specific textual descriptions are IP of Jovian Archive — write all copy independently
- HD calculation has many edge cases (split definition, PHS, Incarnation Cross) — budget extra test time

---

## Phase 8 — Journal
**Weeks 27–28 · 7 dev-days**

Transit-tied daily prompts, SwiftData entries, calendar history, longitudinal pattern detection.

### Tasks

- [ ] `JournalPromptGenerator` — active transit → 1-sentence reflective prompt, cached per transitKey
- [ ] `JournalEntryView` — full-screen text editor, auto-save debounced 1s
- [ ] `JournalEntry @Model` — id, date, prompt, body, transitKey, mood, wordCount
- [ ] Calendar history view — month grid with entry dot indicators
- [ ] Entry detail view — read-only with transit context card
- [ ] Word count — subtle live counter, no streaks or achievement animations
- [ ] Journal search — SwiftData `FetchDescriptor` with NSPredicate, date range filter
- [ ] Pattern detection — after 30th entry: batch LLM analysis of transit keys + summaries → 3 emotional patterns
- [ ] Monthly pattern view — Premium: insight card in journal history
- [ ] Journal premium gate — first 3 entries free, entry #4 triggers paywall

### Acceptance Criteria

- Prompt generates in < 1s (from cache)
- No data loss on force-quit during typing
- Calendar renders 12 months without scroll lag
- Pattern detection fires after 30th entry
- Search returns in < 100ms for 500 entries

### Tech Notes

- Auto-save: `.onChange(of: entryText)` → `Task { try await Task.sleep(...); save() }`, cancel on new change
- Pattern detection batch call: send transit keys + 3-word summaries only, not full entry text
- Journal entries are highly personal — emphasize local-only storage in privacy policy

---

## Phase 9 — Friends + Social
**Weeks 29–30 · 6 dev-days**

Friend graph, QR deep-links, comprehensive share card system, chart comparison, opt-in friend discovery.

### Tasks

- [ ] `FriendsListView` — contact list with big 3 badges, compatibility %, add FAB
- [ ] Add friend action sheet — 3 paths: Contacts, manual entry, QR scan
- [ ] QR code generator — encode BirthData as `lumina://share/{base64}`, render via CoreImage
- [ ] QR code scanner — AVCaptureMetadataOutput, parse URL, create Friend record
- [ ] Chart comparison view — side-by-side big 3, compatibility score, full report CTA
- [ ] Share card system v2 — consolidate all 4 types into `ShareCardGenerator.swift`
- [ ] Friend discovery opt-in — hashed phone in Supabase when toggle on, default off
- [ ] Friend-added push notification — OneSignal via Supabase edge function
- [ ] Privacy controls — discoverable toggle, "Delete my friend data" action

### Acceptance Criteria

- QR round-trip: generate A → scan B → correct Friend record created
- All 4 share card types render in iOS share sheet at 1080×1080
- Friend discovery: hashed phone stored only when toggle on, removed when off
- Friend list loads instantly from SwiftData (no network)

### Tech Notes

- QR payload: BirthData only (name + date + time? + place) — never user ID or auth tokens
- Phone hashing: `CryptoKit SHA256(E.164 format)` before storing
- No friend data in Supabase unless user explicitly opts into discovery

---

## Phase 10 — Polish + App Store Launch
**Weeks 31–34 · 14 dev-days**

Full accessibility audit, performance profiling, App Store screenshots and metadata, legal documents, TestFlight beta, App Review submission, press kit.

### Tasks

- [ ] VoiceOver full audit — all elements labeled, all interactions announced
- [ ] Dynamic Type audit — all 8 sizes including 3 Accessibility sizes
- [ ] Reduce Motion support — parallax and Lottie replaced with fades when enabled
- [ ] Color contrast audit — WCAG 2.1 AA throughout
- [ ] Instruments Time Profiler — cold launch < 1.5s on iPhone 13
- [ ] Instruments Allocations — peak memory < 150MB during palm CV on iPhone 13
- [ ] Instruments Energy Log — all background work stops on app background
- [ ] Scroll performance — 500+ item LazyVStack profiles at 60fps
- [ ] App Store screenshots — 6.9in + 6.5in, all 10 slots, custom designed
- [ ] App Store preview video — 30s walkthrough
- [ ] App Store metadata — title, subtitle, description, 100-character keyword field
- [ ] Privacy policy — comprehensive, hosted at lumina.app/privacy
- [ ] Terms of service — entertainment disclaimer, subscription terms, at lumina.app/terms
- [ ] App Store Connect Privacy Nutrition Label — accurate, complete
- [ ] TestFlight beta — 100 external testers, 2 weeks, structured feedback form
- [ ] Beta feedback triage — fix all P0 (crash) and P1 (broken feature) before submission
- [ ] App Review submission — after pre-review checklist (3.1.2(c), 5.1.1, 4.3, 1.1.6)
- [ ] Press kit — lumina.app/press with all assets
- [ ] Launch day checklist — App Store live, Product Hunt, social posts, press emails
- [ ] gitleaks clean pass on final commit before submission

### Acceptance Criteria

- VoiceOver: zero unlabeled interactive elements (Accessibility Inspector scan)
- Dynamic Type: no truncation at Accessibility XL on any primary screen
- Cold launch < 1.5s on iPhone 13 (5 runs averaged)
- Peak memory < 150MB during palm CV on iPhone 13
- First App Store submission passes Review (target < 2 attempts)
- TestFlight: ≥ 80% complete onboarding, ≥ 40% scan palm, ≥ 60% open daily reading

### Tech Notes

- App Reviewer will test palm reading — ensure it works in Cupertino office lighting conditions
- Screenshots: shoot on physical device — simulator font rendering differs
- Run gitleaks on final commit — one accidentally committed key = binary rejection

### Risk Flags

- "Fortune telling" rejection: frame all copy as "AI analysis" + entertainment — Apple Guideline 1.1.6
- Screenshot design requires real app state — start in Week 29 in parallel with polish
- App Review takes 1–7 days — submit in Week 33 for Week 34 launch buffer

---

## Phase 11 — Post-Launch + v2
**Month 9–18 · 24+ dev-weeks**

Analytics, retention optimization, IAP ladder activation, Gene Keys, Vedic, social feed, Watch app, live reader marketplace, Android assessment.

### v2 Feature Priorities (in order)

1. **Analytics + A/B testing** — Amplitude/Mixpanel, RevenueCat paywall A/B, retention push sequences
2. **IAP ladder activation** — Year Ahead ($11.99), Career Forecast ($7.99), Ask the Stars ($2.99)
3. **Vedic/Jyotish mode** — sidereal Lahiri, nakshatra ring, Vedic compatibility (Guna Milan)
4. **Weekly audio "week ahead"** — Sunday 7AM push + ElevenLabs 3–5min narrated forecast
5. **Gene Keys hologenetic profile** — 64 Gene Keys from HD gates (Life's Work, Evolution, Radiance, Purpose)
6. **Apple Watch complication** — WidgetKit, daily transit glyph + one-line reading
7. **iMessage extension** — compatibility card inline in Messages
8. **Social feed** — opt-in friends-only: reading reactions, journal excerpt sharing
9. **Live reader marketplace** — Stripe Connect, vetted astrologers, iMessage-style chat
10. **Android assessment** — after iOS MRR hits $50k/month

### v2 Acceptance Criteria

- D7 retention > 35% (top-quartile RevenueCat Health & Fitness benchmark)
- Month-1 premium conversion > 4%
- IAP ladder: > 5% of premium users purchase a consumable in first 30 days
- Weekly audio: ≥ 50% of premium users play within 24h of Sunday delivery

### v2 Risk Flags

- Live reader marketplace is a separate product complexity — Stripe Connect + KYC + payout = 6+ weeks
- Android only worth building after iOS MRR validates ($50k+/month) — otherwise splits focus
- Gene Keys: Richard Rudd's text is copyrighted — write all descriptions independently

---

## Definition of Done (per task)

A task is complete when:
1. Code compiles with zero warnings under Swift 6 strict concurrency
2. SwiftLint `--strict` passes on modified files
3. Unit tests written and passing (where applicable)
4. Feature tested on physical iPhone (not only simulator) for UI/CV tasks
5. No `print()` statements left in code
6. No `TODO(lumina):` tags that were flagged as P0/P1
7. `LEARNINGS.md` updated if new gotchas were discovered
8. `TASK.md` status updated to `[x]`
9. Committed to feature branch with conventional commit message
10. Feature branch PR opened against `develop`

---

## Branching Strategy

```
main          ← production releases only
develop       ← integration branch, always green CI
feature/*     ← individual feature work, branch from develop
fix/*         ← bug fixes, branch from develop (or main for hotfixes)
release/*     ← release prep branches (bump version, final QA)
```

Never commit directly to `main` or `develop`.

---

## Version Milestones

| Version | Contents | Target |
|---|---|---|
| 0.1.0 | Phase 0–1 complete, all Core services functional | Week 6 |
| 0.2.0 | Phase 2: Onboarding + Paywall | Week 9 |
| 0.3.0 | Phase 3–4: Birth Chart + Daily Reading (TestFlight internal) | Week 15 |
| 0.4.0 | Phase 5: Palm Reading (TestFlight internal) | Week 19 |
| 0.5.0 | Phase 6: Compatibility (TestFlight internal) | Week 23 |
| 0.6.0 | Phase 7–9: Human Design + Journal + Friends | Week 30 |
| 0.9.0-beta | Phase 10: TestFlight external beta (100 testers) | Week 32 |
| 1.0.0 | App Store submission | Week 33 |
| 1.0.x | Post-launch bug fixes | Month 9 |
| 1.1.0 | Analytics + IAP ladder + retention sequences | Month 10 |
| 1.2.0 | Vedic mode + weekly audio | Month 12 |
| 1.3.0 | Gene Keys + Watch complication | Month 14 |
| 2.0.0 | Social feed + live reader marketplace | Month 18 |
