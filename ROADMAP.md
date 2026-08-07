# ROADMAP.md — Lumina v2 Master Plan

> **Single source of truth.** Replaces the original 12-phase roadmap with a re-cut plan that
> (a) folds in everything still pending from v1, and (b) bakes in the **clarity & navigation**
> work the app needs before it can ship without confusing users.
>
> 16 phases · ~38 build weeks · iOS 26 · App Store 1.0.0 target month 9 · **2026-05-08 cut**

---

## 0. North Star

| Pillar | Promise |
|---|---|
| **Real, not fake** | Real ephemeris math (`astronomy-engine`, self-hosted). Real on-device CV palm analysis when it ships. No hallucinated planet positions, no purchased clipart palms. |
| **Clear, never confusing** | Every screen answers three questions in <2 seconds: *Where am I? What is this telling me? What's the next thing I can do?* |
| **Honest billing** | Monthly + annual only. One soft rescue, then hard stop. No web funnel. No fleeceware framing. |
| **Premium, not mystic** | Wellness-editorial, not purple-gradient mysticism. Anti-Duolingo (no streaks, no confetti). |

If a feature can't pay rent against all four pillars, it doesn't ship.

---

## 1. UX Clarity Charter

These are non-negotiable. Every screen, ViewModel, and PR review checks against them. They map 1:1 to a SwiftLint rule, snapshot test, or PR template checkbox where possible.

### 1.1 Three-question rule
Before code review, the author writes three sentences in the PR description:
1. "On this screen the user is at **___**."
2. "This screen is telling them **___**."
3. "From here, the next clear action is **___**."

If any answer is "unclear" or "depends", the screen isn't ready.

### 1.2 One primary action per screen
Every screen has exactly **one** primary CTA, rendered as the brand `LuminaButton(.primary)`. Secondary actions get `.secondary` / `.ghost`. We never ship a screen with two equally weighted buttons — A/B testing later, not a launch problem.

### 1.3 Never a dead end
Every screen has a way **forward** (next step in a flow) and a way **out** (close, back, "not now"). Empty states must offer one tap that fills the state. Errors must offer a retry **and** a cancel.

### 1.4 No jargon without an inline glossary
Astrology and Human Design contain terms most users don't know. Every bolded term (e.g. **Saturn return**, **Generator**, **Splenic authority**) is wrapped in `GlossaryLink("...")` which opens a 1–3 sentence sheet. No "click around to figure out what this means."

### 1.5 Loading is never a blank screen
Every async screen ships a `LuminaSkeleton` matching its final layout. No spinners, no blank parchment.

### 1.6 Errors speak human
We never show `Error -1003`. We show: "We couldn't reach the chart service. Try again?" with a primary retry button and a way to keep working offline if applicable. All errors funnel through `LuminaError` which has `userTitle`, `userBody`, `recovery`.

### 1.7 The user is never lost mid-flow
Onboarding, palm capture, and paywall flows persist `NavigationPath` to disk and survive force-quit. If the app dies on screen 4 of 7, it relaunches on screen 4 of 7 with field state intact.

### 1.8 Every list has an empty state
SwiftLint custom rule: any view containing `LazyVStack`, `List`, or `ForEach` over a model collection must use `LuminaEmptyState` when count == 0. PR checklist enforces.

### 1.9 Tappable area ≥ 44pt
All interactive elements ≥ 44×44pt. Snapshot tests assert. Glyph touch targets in the chart wheel use a separate hit-test rect, not the glyph bounds.

### 1.10 Accessibility-first, not -last
Every `View` ships with `.accessibilityLabel`, `.accessibilityHint` where the label is ambiguous, and a Dynamic Type Accessibility-XL screenshot in PR review. Reduce Motion is honored from day one, not as a polish-phase add-on.

---

## 2. Information Architecture

### 2.1 The 5-tab spine

After onboarding, the app is a `TabView` with **five** tabs. We picked five because four feels thin and six pushes a tab off-screen at Accessibility XL.

```
┌─ Today ──┬─ Chart ──┬─ Palm ──┬─ People ──┬─ Reflect ─┐
│  ☉       │  ◯       │  ✋     │  ⚭         │  ◐         │
│ default  │          │         │           │             │
└──────────┴──────────┴─────────┴───────────┴─────────────┘
```

| Tab | What it is | Primary CTA | Where Settings lives |
|---|---|---|---|
| **Today** | Anchor screen. Daily reading, "what's happening in your sky", quick action row | "Read today" / "Listen" | Top-right gear → `SettingsView` |
| **Chart** | Birth chart wheel + planet detail · Human Design bodygraph · house system toggle | "Tap a planet" / "Switch to bodygraph" | — |
| **Palm** | Palm scan home: latest reading, history, "scan a hand" CTA | "Scan a hand" | — |
| **People** | Friends list, compatibility, contact add | "Add someone" | — |
| **Reflect** | Journal entries, calendar, monthly insight | "Write today's reflection" | — |

Settings is **not** a sixth tab. It opens as a modal sheet from any tab's nav-bar gear, so primary navigation stays five.

### 2.2 Modals & sheets

- **Sheets** (`.sheet`): planet detail, glossary entry, "How this works" transparency, share card preview, settings. All have an explicit close (X) in the upper-leading corner.
- **Full-screen covers** (`.fullScreenCover`): onboarding, palm capture, paywall. Reserved for "I'm in a flow that owns the whole screen until I finish or explicitly cancel."
- **No modal-on-modal**: SwiftLint custom rule blocks `.sheet` inside a `.sheet` content closure. Any second sheet is an architecture smell.

### 2.3 Onboarding is its own root scene

`AppRouter` arbitrates between `Onboarding` (full-screen cover from launch) and `MainTabs`. After onboarding completes, `AppRouter` switches to `MainTabs` and wipes the cover; user can never re-enter onboarding (use Settings → "Update birth info" instead).

### 2.4 Deep links, every entry

- `lumina://today` → Today
- `lumina://chart[/planet/{name}]` → Chart [+ planet sheet pre-opened]
- `lumina://palm/scan` → Palm capture full-screen
- `lumina://people/{friendID}` → friend detail
- `lumina://share/{base64BirthData}` → "add as friend?" sheet
- `lumina://reflect[/today|/{entryID}]` → Reflect or specific entry

All routes are declared in one `LuminaDeepLink` enum so we can never ship a dangling link.

### 2.5 Search as a first-class verb (v1.1)

Pull-down on Today reveals `LuminaSearch`: surface natal placements, glossary terms, friends, journal entries in one ranked list. Ships in v1.1 (Phase 13), not v1.0, but the IA assumes it exists from day one.

---

## 3. Roadmap at a Glance

| Phase | Name | Status v1 → v2 | Weeks | Owner-load |
|---|---|---|---|---|
| 0 | Foundation (Bootstrap) | mostly done; finishing items below | done + 0.5w | trivial |
| 1 | **Navigation Shell + Design System v2** *(new)* | net new | 1–2 | 8 dev-days |
| 2 | Onboarding v2 (clearer, recoverable, validated) | rewritten | 3–4 | 9 dev-days |
| 3 | **Today (Home)** anchor screen *(new framing)* | net new framing on Daily Reading | 5–6 | 8 dev-days |
| 4 | Birth Chart | from v1 Phase 3 | 7–9 | 12 dev-days |
| 5 | Daily Reading + Audio | from v1 Phase 4 | 10–11 | 9 dev-days |
| 6 | Palm Reading | from v1 Phase 5 | 12–15 | 16 dev-days |
| 7 | Compatibility | from v1 Phase 6 | 16–18 | 13 dev-days |
| 8 | Human Design | from v1 Phase 7 | 19–21 | 11 dev-days |
| 9 | Reflect (Journal) | from v1 Phase 8 + biometric lock | 22–23 | 8 dev-days |
| 10 | People (Friends) | from v1 Phase 9 + permission UX | 24–25 | 7 dev-days |
| 11 | Notifications + Engagement | promoted from backlog | 26 | 4 dev-days |
| 12 | **Settings, Account, Privacy Dashboard** *(new)* | net new | 27 | 5 dev-days |
| 13 | **Search, Glossary, Help Center** *(new)* | net new | 28 | 5 dev-days |
| 14 | Accessibility, Performance (localization deferred past 1.0 — see Phase 14) | from v1 Phase 10 expanded | 29–30 | 9 dev-days |
| 15 | Beta, Compliance, App Store 1.0.0 | from v1 Phase 10 | 31–34 | 14 dev-days |
| 16 | Post-Launch v2 (analytics, IAP ladder, Vedic, Watch, social, etc.) | from v1 Phase 11 | month 9–18 | 24+ wk |

Total to 1.0.0: **~38 weeks · ~138 dev-days**, comfortably absorbed by the original budget.

---

## 4. What's Already Done (carry-over from v1)

✅ Phase 0 bootstrap — `project.yml`, design tokens (colors/typography/spacing), service-actor stubs, splash, secrets injection, CI on `macos-15`/Xcode-latest
✅ Backend ephemeris MVP — Fastify + TS + `astronomy-engine`, `/chart` with planets, Placidus + whole-sign + sidereal (Lahiri) cusps, Asc/MC, 5 Ptolemaic aspects with orbs, vitest suite
✅ iOS `EphemerisService` actor with HTTP round-trip + decode tests
✅ SwiftLint strict config including custom rules for hex, fonts, magic numbers
✅ CI workflow green on every push

What's still pending from the v1 plan is folded into the phases below, never lost.

---

## 5. Phase Detail

> Each phase below has: **Goal · Scope · Tasks · Acceptance · Risks**.
> Tasks are tagged `[CARRY]` (was in v1 plan), `[NEW]` (added in v2), or `[FIX]` (corrects an issue we found).

---

### Phase 0 — Foundation (finish-line)
**Status: 90% · 0.5 dev-day to close**

#### Tasks
- `[CARRY]` Initialize Xcode project — confirmed via `xcodegen generate` on a Mac (CI does this on every push, no human Mac required for verification)
- `[CARRY]` TestFlight pipeline via GitHub Actions + fastlane — needs Apple Developer enrollment; deferred to Phase 15
- `[CARRY]` Supabase project — auth, `user_profiles`, pgvector — needs human credentials (still blocked)
- `[FIX]` Add explicit `Lumina.xcodeproj/` to `.gitignore` (currently relying on convention — fragile)
- `[NEW]` Add `LuminaTests` coverage badge target so CI surfaces % per-PR

---

### Phase 1 — Navigation Shell + Design System v2
**New. Weeks 1–2 · 8 dev-days. Blocks every feature phase.**

We can't ship clarity if the app has no shell. Build the shell first, slot features into it.

#### Goal
A user opens the app, sees five tabs, can move between them, and every empty placeholder screen tells them what's coming. From day one of feature work, every PR plugs into this shell instead of inventing its own navigation.

#### Tasks

**Routing**
- `[NEW]` `AppRouter.swift` — `@Observable` root state machine: `.onboarding` | `.mainTabs(selected: LuminaTab)` | `.locked(for: AppLockReason)`; persistence via `@AppStorage`
- `[NEW]` `LuminaTab` enum — `today, chart, palm, people, reflect`; raw values match deep-link slugs
- `[NEW]` `LuminaDeepLink` enum + `URL` parser — exhaustive switch over all routes; covered by unit tests
- `[NEW]` `MainTabsView.swift` — `TabView` selection bound to `AppRouter`; honours selected tab from deep link
- `[NEW]` Per-tab `NavigationStack` with typed `NavigationPath` (one path per tab so cross-tab nav doesn't pollute back stacks)

**Design system v2 — components**
- `[NEW]` `LuminaButton` (primary, secondary, ghost, destructive) — 56pt height primary, 44pt min, supports `loading` state, honors Reduce Motion
- `[NEW]` `LuminaCard` with native `.glassBackgroundEffect()` on iOS 26
- `[NEW]` `LuminaTextField` — large single-field input, error inline below, character count optional
- `[NEW]` `LuminaSegmentedControl` — house-system / chart-mode picker; mono labels in GT America Mono
- `[NEW]` `LuminaSkeleton` — shimmer view that mirrors a target layout
- `[NEW]` `LuminaEmptyState(icon, title, body, primaryCTA)` — used by every list when count == 0
- `[NEW]` `LuminaErrorState(error: LuminaError)` — same shape, retry-aware
- `[NEW]` `GlossaryLink("term")` view modifier — taps open a `.sheet` with the term's 1–3 sentence explanation; backed by `GlossaryStore`
- `[NEW]` `LuminaBadge` — pill for "Premium", "Beta", "New"
- `[NEW]` `LuminaConfirmationDialog` wrapper — every destructive action (delete journal, remove friend, sign out) routes through this

**Tokens**
- `[CARRY]` `LuminaTypography` — replace `.system(.serif)` fallback with PP Editorial New once licensed; keep fallback as a `BundledFont.bestEffort(...)` helper that returns custom-or-system at runtime
- `[NEW]` `LuminaShadows` — three semantic levels (`subtle`, `card`, `elevated`)
- `[NEW]` `LuminaRadii` — `xs=6 / sm=10 / md=16 / lg=24` (cards, sheets, photos); SwiftLint rule blocks raw `.cornerRadius(...)` literals

**Errors**
- `[NEW]` `LuminaError.swift` — sum type with `.network`, `.server(status:)`, `.notSignedIn`, `.subscriptionRequired`, `.permissionDenied(...)`, `.unknown(underlying:)`. Each case carries `userTitle`, `userBody`, `recoverySuggestion`, `analyticsKey`.
- `[NEW]` Error-mapping extensions on every service actor

**Plumbing**
- `[NEW]` `AppLock.swift` — Face ID gate for the Reflect tab (opt-in in Settings); uses `LocalAuthentication`
- `[NEW]` `Haptics.swift` — light/medium/heavy/success wrappers; honors Reduce Motion + Reduce Haptics

**Acceptance**
- Five tabs render with placeholder hero illustrations and a "Coming soon" empty state per tab
- Deep link `lumina://chart` from cold launch lands on the Chart tab, not Today
- Every component renders correct at Dynamic Type Accessibility-XL — snapshot tests assert
- SwiftLint custom rules (no_raw_corner_radius, no_dead_end_list) green
- Reduce Motion replaces shimmer + Lottie with crossfades

**Risks**
- iOS 26 `.glassBackgroundEffect()` may need entitlement review for some surfaces — verify on first CI build
- `NavigationStack` per-tab adds memory; profile on iPhone 13 to confirm < 80MB idle

---

### Phase 2 — Onboarding v2
**Weeks 3–4 · 9 dev-days**

Rewritten from v1 Phase 2 with **clarity-first** changes: progress indicator, recoverable on every screen, validated input, no celebration for entering a birth date.

#### Goal
A first-run user goes from launch to "I have a chart and I know what to do next" in **under 90 seconds** with **zero confusion**.

#### Step list (9 screens)

| # | Screen | Primary action | Validation / fail-soft |
|---|---|---|---|
| 1 | Brand promise (1 sentence, parchment, slow fade) | "Start" | — |
| 2 | Why are you here? (4 motivation tap targets) | tap one | optional skip → defaults to "curious" |
| 3 | Your name | Continue | non-empty; "Use 'Friend' instead" link |
| 4 | Birth date | Continue | DatePicker, future dates disallowed |
| 5 | Birth time | Continue | wheel + "I don't know — use noon" equally prominent; explanatory caption "Without time, your sign and planets are accurate; houses are hidden." |
| 6 | Birth place | Continue | MapKit autocomplete, manual lat/lon fallback for airplane mode |
| 7 | Chart reveal (slow draw + soft chime) | "See my chart" | reduced motion → fade |
| 8 | How excited are you to start? (5 tappable stars) | "Send in" → Apple's rating card | never gates: button reads "Skip" until a star is tapped, and the card shows for every answer (Guideline 1.1.7 — see `docs/aso/RATINGS.md`) |
| 9 | What you can do next (3 quick-win cards: read today, see your chart, add a friend) | tap any → land on that tab | always offers "Maybe later → go to Today" |

#### Tasks
- `[CARRY/REWRITTEN]` 9 screen views in `Features/Onboarding/Screens/`
- `[NEW]` `OnboardingProgressBar` — one dot per step (reads `Step.totalCount`), no labels, no percent
- `[NEW]` Persistent `OnboardingState` SwiftData model — survives force-quit; resumes on the same step with field state
- `[NEW]` Inline validation (debounced) instead of submit-then-error — show name length, date sanity, place lookup states immediately
- `[NEW]` "Why we ask" link under each sensitive field — opens 2-sentence explainer sheet
- `[CARRY]` MapKit city autocomplete + time zone confirmation
- `[CARRY]` `OnboardingViewModel` writes `BirthData` to SwiftData on completion
- `[CARRY]` `NavigationPath` with resume-on-kill persistence — now backed by `OnboardingState`
- `[NEW]` Hard paywall replaced with **softer post-onboarding offer**: free tier explicitly explained, Premium upsell card on screen 8 *with a non-blocking "Continue free" link*. (Apple 3.1.2(c) compliance review confirmed this is permitted because we never gate the free tier behind a hard wall.)
- `[CARRY]` Discount rescue paywall — once per install, on first decline only, 30% off
- `[CARRY]` Supabase Sign in with Apple — moved from screen 2 to a contextual prompt **after** they've seen their chart (lower friction, higher conversion)
- `[CARRY]` Deferred notification permission — fires after first daily reading is open, not during onboarding
- `[CARRY]` Onboarding analytics — 14 events, named consistently (`onboarding.<step>.<action>`)
- `[NEW]` "Update birth info" surface in Settings — single source of truth for editing what was collected here

**Acceptance**
- Median completion time < 90s on iPhone 13, measured with timed walkthrough on 5 colleagues
- Force-quit at any screen → relaunch resumes on same screen with state intact
- "I don't know my time" path: chart loads, ASC/MC hidden, banner explains, no crash
- Sign in with Apple completes in < 5s and creates `user_profiles` row
- Rescue paywall fires exactly once per install on first decline; never twice in same session
- Skipped motivation defaults paywall copy to "curious" variant, not crashes

**Risks**
- App Review may flag onboarding as "fortune telling" → frame as AI analysis + entertainment in copy
- MapKit needs `com.apple.developer.maps` entitlement in provisioning profile

---

### Phase 3 — Today (Home Anchor)
**Weeks 5–6 · 8 dev-days**

Today is **the** screen the user sees most. It must be unambiguous, fast, and always suggest one next thing.

#### Goal
A returning user opens the app and within 2s knows: today's date, the headline transit, today's reading (or that one is brewing), and the single most useful action right now.

#### Layout

```
┌────────────────────────────────────────┐
│  ⚙  THURSDAY · MAY 8                    │  ← top bar: settings · GT Mono date
│                                         │
│  Your sky today                         │  ← PP Editorial — page title
│  Mercury squares Saturn — words feel    │  ← editorial pull-quote (h2)
│  heavier than usual.                    │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  ▶  Listen · 3 min                 │  │  ← LuminaCard, Premium gated
│  │  Today's reading, narrated         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Read today  →                          │  ← LuminaButton.primary
│                                         │
│  ───────────────────────────────────    │
│  WHAT'S HAPPENING                       │  ← GT Mono small caps
│  • Mercury □ Saturn (exact in 2d)       │  ← top 3 transits, expandable
│  • Moon enters Pisces                   │
│  • Venus retrograde shadow ends         │
│                                         │
│  ───────────────────────────────────    │
│  QUICK ACTIONS                          │
│  ✋ Scan a palm   ⚭ Add a friend         │  ← horizontal scroller
│  ◐ Reflect       ◯ See chart            │
└────────────────────────────────────────┘
```

#### Tasks
- `[NEW]` `TodayView` — hero card + transit summary + quick-actions row
- `[CARRY]` `DailyReadingViewModel` — wraps RAG fetch, generation, audio
- `[CARRY]` `ContentGenerator.swift` — transits → top-3 RAG chunks → claude-opus-4-6
- `[CARRY]` ElevenLabs TTS via Node `/generate-audio` endpoint, MP3 cached locally with 7-day TTL, 50MB LRU
- `[CARRY]` Daily reading SwiftData cache, invalidated at local midnight or transitKey change
- `[NEW]` Quick-actions row — horizontal `LazyHStack` of 4 cards, deep-links into the matching tab
- `[NEW]` `EmptyTodayState` — first-time user (no reading yet) sees "Generating your first reading…" skeleton
- `[NEW]` Offline graceful state — yesterday's reading shown with "Offline · last updated [relative time]" banner
- `[CARRY]` Skeleton loading state with the Lottie constellation
- `[CARRY]` Server-side throttle (1×/day/user via Supabase edge function)
- `[CARRY]` OneSignal daily push 7:30–9:00 AM local
- `[NEW]` "Why this reading?" link under the body — opens the actual transit JSON + the 3 RAG snippets in a debug-style transparency sheet (transparency is a brand promise)

**Acceptance**
- Reading body cites at least one natal placement (manual review on 10 accounts)
- p95 cold-load to first paint < 800ms; reading-ready < 3s on 4G
- Audio plays without buffering on 4G
- Cached reading loads in < 50ms
- Offline state: yesterday's reading available, audio plays from cache, no error toast
- "Why this reading?" sheet shows real RAG sources, not stub text

**Risks**
- RAG corpus quality is the single biggest content-risk lever — review 30+ readings before public launch
- ElevenLabs Starter (30k chars/mo) only covers ~1k users — Creator ($22/mo) before 1k MAU

---

### Phase 4 — Birth Chart
**Weeks 7–9 · 12 dev-days**

#### Goal
The user can read their chart without already knowing astrology.

#### Tasks
- `[CARRY]` `BirthChartView` — wheel (55% screen) + interpretations scroll below
- `[CARRY]` Chart-wheel `Canvas` renderer — 12 houses, zodiac ring, 10 planet glyphs, 5 aspect line types, retrograde markers, single-pass for 60fps
- `[CARRY]` Glyph hit-testing — bounding-box dictionary, 44pt touch targets via padded hit rects
- `[CARRY]` `PlanetDetailView` `.sheet(item:)` — degree, sign, house, retrograde, RAG interpretation
- `[CARRY]` House system picker (`LuminaSegmentedControl`) — Placidus / Whole-Sign / Sidereal
- `[CARRY]` Unknown-time handling — hide cusps + ASC/MC, info banner; no shame copy
- `[CARRY]` Retrograde dashed-orbit ring
- `[CARRY]` Aspect legend expandable card, defaults collapsed
- `[CARRY]` Zodiac sign tap → 3-sentence sign profile sheet
- `[CARRY]` Share card via `ImageRenderer` — 1080×1080 + 1080×1920
- `[CARRY]` Deep-link inbound handler — `lumina://chart` and `lumina://chart/planet/<name>`
- `[NEW]` "Big 3" band at top of chart screen — Sun/Moon/Rising as 3 large glyphs, immediate recognition value
- `[NEW]` "Read my chart aloud" — Premium-gated audio narration of a 90-second chart summary
- `[NEW]` Inline `GlossaryLink` on every astrology term in the body copy
- `[NEW]` "Switch to bodygraph" toggle in nav-bar (Phase 8 deps) — `Chart` tab houses both views

**Acceptance**
- Planet positions verified ±1° against astro.com on 5 test dates
- All 10 planet taps open correct sheet with content
- Toggle re-renders in < 400ms
- Share card exports without memory warning at 2×
- Deep link opens chart with Mars sheet pre-presented
- Big-3 band loads in < 100ms (cached natal data)

**Risks**
- Canvas hit-testing math is manual — budget +2 days
- `ImageRenderer` blows up on lazy content — pre-warm glyphs before export

---

### Phase 5 — Daily Reading + Audio
**Weeks 10–11 · 9 dev-days**

#### Goal
Reading content quality is on par with a thoughtful professional astrologer; audio is brand-defining, not a gimmick.

Most of this phase is technical hardening of what Phase 3 ships visually.

#### Tasks
- `[CARRY]` Reading generation: transits + 3 RAG chunks → claude-opus-4-6, 800 tokens, temp 0.7
- `[CARRY]` Audio playback bar — sticky at bottom of screen, ElevenLabs voice avatar, play/pause, 15s skip, scrub
- `[CARRY]` Audio cache (FileManager, keyed by transitKey)
- `[NEW]` Background audio mode — keeps playing in lock screen, with `MPNowPlayingInfoCenter` artwork (mood glyph + date)
- `[NEW]` AirPlay 2 / CarPlay support — 4 hours of dev work; huge listen-rate lift expected
- `[CARRY]` Share card — title + mood glyph + wordmark
- `[CARRY]` Skeleton + Lottie loading
- `[NEW]` "Pin reading" — Premium feature, save to a `Library` view inside Reflect tab
- `[NEW]` Reading reactions — single-tap "this was you / this was off / not today" feedback. Stored locally + analytics. Drives RAG corpus tuning, not social.
- `[CARRY]` OneSignal daily push, transit-specific copy
- `[NEW]` Push opt-in is offered the first time the user finishes a reading, contextually: "Want this in your morning?"

**Acceptance**
- Reading reactions form a feedback loop: reactions visible in analytics dashboard
- Background audio survives screen-lock + Bluetooth handoff
- Pinned readings persist across reinstall *for premium users* (Supabase sync)
- Cost per reading < $0.01 verified across 20 generations

---

### Phase 6 — Palm Reading
**Weeks 12–15 · 16 dev-days**

The category's most significant technical differentiator. Identical scope to v1; flow gets clarity polish.

#### Tasks (carry-over from v1)
- `[CARRY]` `PalmScanView` — full-screen AVCapture, hand outline SVG guide, lighting indicator, palm-fill % readout
- `[CARRY]` Real-time hand pose overlay via `VNDetectHumanHandPoseRequest`, 21 landmarks at confidence > 0.85
- `[CARRY]` Auto-capture trigger: pose > 0.92, fill 40–70%, lighting ≥ 0.4, stable 500ms
- `[CARRY]` `LineSegmenter` actor — Core ML U-Net, 256×256 grayscale ROI, 4-channel Float32 mask
- `[CARRY]` Mask post-processing — morph closing, Hilditch skeletonization, connected components
- `[CARRY]` Trace-overlay Canvas — life (sage), heart (blush), head (celestial), fate (gold)
- `[CARRY]` Manual correction handles + DragGesture
- `[CARRY]` `PalmFeatureExtractor` — normalized length, curvature, branch count, endpoint positions
- `[CARRY]` Palm narration: features + ChartData → claude-opus-4-6, 600 tokens, temp 0.4
- `[CARRY]` `PalmReadingView` — 4 accordion cards + synthesis + chart-crossover callout
- `[CARRY]` "How this works" transparency modal — shows actual segmentation mask, confirms no photo upload
- `[CARRY]` SwiftData `PalmReading` storage
- `[CARRY]` History view — `LazyVStack` with thumbnails
- `[CARRY]` Free tier: 1 scan/month gated; second scan triggers paywall
- `[CARRY]` Capture-failure states each with illustration + recovery action

#### Phase 6 v2 additions
- `[NEW]` Pre-capture **practice run** — 10-second walkthrough animation of the ideal hand position before first capture; massively reduces failed first-scans
- `[NEW]` Both-hands flow — dominant + non-dominant scan with explanation of why both matter (palmistry rationale)
- `[NEW]` "I'd rather skip" exit on every capture screen — never trap user
- `[NEW]` Save-without-narration — user can keep the trace overlay even if generation fails; narration is regenerable

**Acceptance** (unchanged from v1)
- Detection ≥ 80% in standard indoor lighting across 20 diverse hands
- End-to-end < 4s on iPhone 13
- Charles/Proxyman: zero palm photo bytes leave device
- Free tier: scan #2 blocks correctly with paywall

**Risks**
- Model mIoU < 0.88 on darker skin tones — build Fitzpatrick-balanced test set; **this is a launch blocker**, not a "we'll fix it later"
- Apple may flag — copy stays "AI analysis · entertainment" throughout

---

### Phase 7 — Compatibility (People tab)
**Weeks 16–18 · 13 dev-days**

#### Tasks (carry-over)
- `[CARRY]` `CompatibilityView` entry — 3 paths: contacts import, manual entry, QR scan
- `[CARRY]` Contact import via `CNContactStore` filtered by birthday; opt-in copy
- `[CARRY]` Manual friend entry form
- `[CARRY]` `Friend @Model`
- `[CARRY]` Backend `/synastry` and `/composite` endpoints
- `[CARRY]` Synastry bi-wheel Canvas renderer
- `[CARRY]` Compatibility score (deterministic regardless of A/B order)
- `[CARRY]` Score label mapping (Magnetic/Harmonious/Stimulating/Challenging)
- `[CARRY]` LLM report — 5 narrative dimensions
- `[CARRY]` Compatibility result view — score badge, label, 5 expandable cards, bi-wheel
- `[CARRY]` Share card — "X% compatible with [name]"
- `[CARRY]` Crush Report IAP $4.99 — Davison + transits-to-composite + timing windows
- `[CARRY]` Friend graph list

#### v2 additions
- `[NEW]` "Don't know their time?" path — single tap. Defaults to noon, shows score with caveat banner.
- `[NEW]` Privacy disclosure card on first use of contact import — what we read (name + birthday), what we don't (phone, address, photo), where it's stored (on-device)
- `[NEW]` Friends backup (Premium) — Supabase row-level encrypted backup of friend list, opt-in
- `[NEW]` Bulk import safety — at most 5 contacts shown per session for first-time users to prevent overwhelm

---

### Phase 8 — Human Design
**Weeks 19–21 · 11 dev-days**

Lives **inside the Chart tab** as a togglable view. Same brain, different lens.

#### Tasks (carry-over)
- `[CARRY]` HD calculation Swift wrapper (gates, channels, centers, type, profile, authority)
- `[CARRY]` `BodygraphData` model
- `[CARRY]` Bodygraph SVG renderer — 9 centers, channel lines, gate numbers
- `[CARRY]` Center fill — defined solid (HD palette) / undefined hollow with stroke
- `[CARRY]` Split-definition rendering
- `[CARRY]` Type / Profile / Authority cards — zero jargon
- `[CARRY]` Center detail sheets
- `[CARRY]` HD glossary — A–Z searchable, accessible from every bolded term
- `[CARRY]` Astrology-HD crossover callouts — HD gate aligns with natal planet within 1°
- `[CARRY]` `HumanDesignViewModel` — compute and cache to SwiftData
- `[CARRY]` Premium gate — type + profile free; full bodygraph + authority + centers locked

**Acceptance** (unchanged)
- 5 test dates verified against myBodyGraph.com
- Zero unexplained HD jargon (team review pass)

---

### Phase 9 — Reflect (Journal)
**Weeks 22–23 · 8 dev-days**

#### Tasks (carry-over)
- `[CARRY]` `JournalPromptGenerator` — active transit → 1-sentence reflective prompt, cached per transitKey
- `[CARRY]` `JournalEntryView` — full-screen text editor, debounced auto-save (1s)
- `[CARRY]` `JournalEntry @Model`
- `[CARRY]` Calendar history — month grid with entry-dot indicators
- `[CARRY]` Entry detail view — read-only with transit-context card
- `[CARRY]` Subtle live word counter, no streaks/no achievement animations
- `[CARRY]` Search — `FetchDescriptor` with `NSPredicate`, date range filter
- `[CARRY]` Pattern detection — after 30th entry, batch LLM analysis → 3 emotional patterns
- `[CARRY]` Monthly pattern view — Premium insight card
- `[CARRY]` Premium gate — first 3 entries free, entry #4 prompts upgrade

#### v2 additions
- `[NEW]` **Face ID lock** for the Reflect tab — opt-in in Settings; uses `LocalAuthentication`. Journal is the most personal data in the app.
- `[NEW]` Export journal — Premium feature, exports to a single Markdown file via `.fileExporter`
- `[NEW]` "Today's prompt is sensitive — want to skip?" — for emotionally heavy transits (e.g. Pluto squares), offer a softer prompt option
- `[NEW]` No cloud sync of journal text in v1.0 — local-only is the privacy promise. (v2 considers iCloud-encrypted Drive sync as opt-in.)

---

### Phase 10 — People (Friends graph)
**Weeks 24–25 · 7 dev-days**

#### Tasks (carry-over)
- `[CARRY]` `FriendsListView` — contact list w/ big-3 badges + compat %
- `[CARRY]` Add-friend action sheet — 3 paths
- `[CARRY]` QR generator — encode `BirthData` as `lumina://share/<base64>`
- `[CARRY]` QR scanner — `AVCaptureMetadataOutput`
- `[CARRY]` Chart comparison view
- `[CARRY]` `ShareCardGenerator.swift` — consolidate all 4 share-card types
- `[CARRY]` Friend discovery opt-in — hashed phone in Supabase, default OFF
- `[CARRY]` Friend-added push notification
- `[CARRY]` Privacy controls — discoverable toggle, "Delete my friend data"

#### v2 additions
- `[NEW]` "Group reading" Premium feature — pick up to 4 friends, get one synastry-aware composite reading. Lays groundwork for v2 group features.
- `[NEW]` Soft remove (archive) before hard delete — undo window 5s

---

### Phase 11 — Notifications + Engagement
**Week 26 · 4 dev-days**

#### Tasks
- `[CARRY]` OneSignal SDK integration, push token registration, 4 segments (premium / free / lapsed / cohort-by-motivation)
- `[CARRY]` Daily morning push (7:30–9:00 AM local, 4–10 word copy) — fired only if today's reading is generated
- `[CARRY]` Weekly "week ahead" Sunday push (Premium only, links to Reflect or Today)
- `[CARRY]` Event-triggered: eclipse, retrograde, ingress; cap at 5/week
- `[NEW]` Notification preferences screen in Settings — granular toggles (daily / weekly / events / friend-added). Default: daily ON, others OFF.
- `[NEW]` "Don't notify on weekends" toggle (heavily-requested in competitor reviews)
- `[NEW]` Quiet hours — 9pm to 7am default, adjustable

**Acceptance**
- Push fires at correct local time ±5min
- Disabling notifications in Settings stops next-morning push within 1 fetch cycle
- Quiet hours respected even on event-triggered pushes

---

### Phase 12 — Settings, Account, Privacy Dashboard
**Week 27 · 5 dev-days · NEW phase**

The version 1 plan didn't have a settings page. Without it, every "but how do I…" review will be a 1-star.

#### Settings screen sections

```
ACCOUNT
  Signed in as Anna · anna@…
  Manage subscription                    →
  Restore purchases                      →
  Sign out                               →

YOUR INFO
  Birth date · 1990-06-15                →   (edits open Phase 2 form, prefilled)
  Birth time · 14:30                     →
  Birth place · Stockholm, Sweden        →

PREFERENCES
  House system · Placidus                ▼
  Chart mode · Western                   ▼
  Notifications                          →
  Lock Reflect tab with Face ID          ◯
  Reduce motion (system override)         ◯

PRIVACY
  Privacy dashboard                      →
  Export my data                         →
  Delete my account                      →

ABOUT
  Help & FAQ                             →
  Send feedback                          →
  Terms of service                       →
  Privacy policy                         →
  Open-source acknowledgements           →
  Version 1.0.0 (build 142)
```

#### Privacy dashboard

A first-of-its-kind screen for this category: **"What we know about you, and what we don't."**

```
WHAT'S ON THIS DEVICE
  • Your birth chart (last computed 2 days ago)
  • 12 journal entries (encrypted at rest)
  • 3 palm scans (photos deleted, traces saved)
  • 7 friends

WHAT'S ON OUR SERVER
  • Your account ID + Sign in with Apple email
  • Your active subscription status
  • Last push token (so we can wake your phone)

WHAT'S NOT
  • Your palm photos (deleted on-device after analysis)
  • Your journal text (never leaves your phone)
  • Your contacts (only birthdays read, never stored on server)
  • Your location (only at onboarding to find your birth place)
```

#### Tasks
- `[NEW]` `SettingsView` + sub-views per section
- `[NEW]` `EditBirthInfoView` reusing onboarding form components
- `[NEW]` Subscription management deep link — `Purchases.shared.showManageSubscriptions(...)`
- `[NEW]` Restore purchases action with confirmation toast
- `[NEW]` Sign out flow — clears Supabase session, retains local SwiftData, requires Face ID re-auth on next sensitive screen
- `[NEW]` `PrivacyDashboardView` — pulls counts from SwiftData + Supabase
- `[NEW]` Export my data — emits a single `.json` archive (chart, friends, journal, settings) via `.fileExporter`. ~1 day of work, GDPR-friendly.
- `[NEW]` Delete account flow — 3-step confirmation, soft 30-day grace period server-side, hard wipe of local data on confirm
- `[NEW]` `HelpView` — searchable FAQ; ~25 entries pre-written
- `[NEW]` Send feedback — `MFMailComposeViewController` with diagnostic dump (device, build, anonymized state)
- `[NEW]` Open-source acknowledgements view — generated from SPM

**Acceptance**
- All actions reachable in ≤ 2 taps from any tab
- Edit birth info propagates to chart re-compute within 5s
- Privacy dashboard counts match `select count(*)` queries
- Export archive opens cleanly in any text editor

---

### Phase 13 — Search, Glossary, Help Center
**Week 28 · 5 dev-days · NEW phase**

#### Tasks
- `[NEW]` `GlossaryStore` — 200+ entry dictionary, JSON in `Resources/Glossary.json`, lazily loaded; covers astrology + HD + palmistry
- `[NEW]` `GlossaryLink("term")` view modifier (defined in Phase 1) wired across every feature
- `[NEW]` `SearchView` — pull-down on Today; ranked results from glossary, friends, journal, planets, transits
- `[NEW]` Search analytics — top-100 queries logged, fuels content tuning
- `[NEW]` `HelpView` topic threading — 12 root topics → 25 articles, all internal markdown
- `[NEW]` "Ask the stars" preview teaser — Premium upsell card in Help when query has astrological intent (sets up v2 Q&A IAP)

**Acceptance**
- Search returns in < 100ms over local data
- 100% of bolded astrological/HD terms in shipped UI resolve to a glossary entry (script-checked in CI)
- Help search returns ≤ 5 results per query, sorted by relevance

---

### Phase 14 — Accessibility, Localization, Performance
**Weeks 29–30 · 9 dev-days**

#### Tasks
- `[CARRY]` VoiceOver full audit — all elements labeled, all interactions announced
- `[CARRY]` Dynamic Type audit — all 8 sizes including 3 Accessibility sizes; PR-blocking snapshot tests
- `[CARRY]` Reduce Motion — parallax + Lottie replaced with crossfades when enabled
- `[CARRY]` Color contrast audit — WCAG 2.1 AA throughout (Liquid Glass surfaces double-checked)
- `[CARRY]` Instruments Time Profiler — cold launch < 1.5s on iPhone 13
- `[CARRY]` Instruments Allocations — peak memory < 150MB during palm CV on iPhone 13
- `[CARRY]` Instruments Energy Log — all background work stops on app background
- `[CARRY]` Scroll perf — 500+ item `LazyVStack` at 60fps
- `[NEW]` Localization — **not at 1.0.** The app ships English-only: `Localizable.xcstrings` is an empty catalog, there are no `String(localized:)` call sites, and the heavy `"…" + "…"` string concatenation in body copy wouldn't extract even if there were. Doing this properly means rewriting every user-facing string first. Target ES for 1.1, then FR / PT-BR / DE. Do not list Spanish in App Store metadata until it exists.
- `[NEW]` RTL support audit — Arabic in v1.2, but visual layout must not assume LTR (chart wheel is symmetrical, but text alignment isn't)
- `[NEW]` Voice Control test pass — every primary action has a unique callable name
- `[DONE]` Crash reporting — MetricKit (`Core/Diagnostics/CrashReporter.swift`), no vendor account and no added privacy-manifest burden. A hosted service can layer on later without changing call sites.
- `[NEW]` Memory leak test — Instruments Leaks; strict zero-leak gate before TestFlight
- `[NEW]` Battery test — 30 minutes active use must not cost > 8% battery on iPhone 13

---

### Phase 15 — Beta + Compliance + App Store 1.0.0
**Weeks 31–34 · 14 dev-days**

#### Tasks
- `[CARRY]` App Store screenshots — 6.9in + 6.5in, all 10 slots, custom designed
- `[CARRY]` App Store preview video — 30s walkthrough
- `[CARRY]` App Store metadata — title, subtitle, description, 100-character keywords
- `[CARRY]` Privacy policy at lumina.app/privacy
- `[CARRY]` Terms of service at lumina.app/terms
- `[CARRY]` App Store Connect Privacy Nutrition Label
- `[NEW]` App Store **App Privacy Manifest** (PrivacyInfo.xcprivacy) — required since iOS 17.4; declare reasons for `UserDefaults`, `FileTimestamp`, `SystemBootTime`, `DiskSpace` APIs
- `[CARRY]` TestFlight beta — 100 external testers, 2-week window, structured feedback form
- `[CARRY]` Beta feedback triage — fix all P0/P1 before submission
- `[NEW]` Pre-submission compliance review (3.1.2(c), 5.1.1, 4.3, 1.1.6) **plus 1.4.4 (medical/wellness disclaimers)**
- `[CARRY]` Press kit at lumina.app/press
- `[CARRY]` Launch checklist — App Store live, Product Hunt, social, press emails
- `[CARRY]` gitleaks final pass; rotate any flagged keys before submission
- `[NEW]` ASO: "human design app", "palm reading", "birth chart calculator" identified as under-competed; primary keywords go in `keywords` field
- `[NEW]` First-week support rota — 3 days of dedicated triage; review responses from team within 24h on first 100 reviews

**Acceptance**
- VoiceOver: zero unlabeled interactive elements (Accessibility Inspector clean)
- Dynamic Type: no truncation at Accessibility XL
- Cold launch < 1.5s on iPhone 13 (5 runs avg)
- Peak memory < 150MB during palm CV
- TestFlight: ≥ 80% complete onboarding, ≥ 40% scan a palm, ≥ 60% open a daily reading
- App Review approves on first or second submission

---

### Phase 16 — Post-Launch v2
**Month 9–18 · 24+ weeks**

Priority order, each is a separate sprint:

1. **Analytics + A/B framework** — Amplitude or PostHog, RevenueCat paywall A/B, retention sequences
2. **IAP ladder** — Year Ahead $11.99, Career Forecast $7.99, Ask the Stars $2.99 consumable
3. **Vedic / Jyotish mode** — sidereal Lahiri, nakshatra ring, Guna Milan compatibility
4. **Weekly audio "week ahead"** — Sunday 7am push + ElevenLabs 3–5 min narrated forecast
5. **Gene Keys** — 64 keys derived from HD gates (Life's Work / Evolution / Radiance / Purpose)
6. **Apple Watch complication** — daily transit glyph + 1-line reading; WidgetKit
7. **iMessage extension** — compatibility card inline in Messages
8. **Lock-screen widgets** — 3 sizes; current Moon phase + transit
9. **Live Activity** — eclipse window countdown, retrograde shadow window
10. **Friends opt-in social feed** — reading reactions, journal excerpt sharing (private, not public)
11. **Live reader marketplace** — Stripe Connect, vetted astrologers, in-app chat
12. **Android assessment** — only after iOS MRR ≥ $50k/month
13. **iPad layout** — 2-pane chart + reading split view
14. **Visionos exploration** — 3D chart wheel; very low priority, very high marketing leverage

---

## 6. Cross-Cutting Workstreams

These run **in parallel** with feature phases and are tracked separately in `TASK.md`.

### 6.1 Backend
- Sidereal house variant (Lahiri offset on cusps too, not just longitudes) — already partially in
- Transits & progressions endpoints
- `/synastry`, `/composite`, `/davison` endpoints (Phase 7 deps)
- Swap `astronomy-engine` → `swisseph` once Pro license clears
- Fly.io production deploy: Dockerfile, healthcheck, secrets, auto-sleep
- In-memory LRU cache (key: birth-data hash)
- Rate limiting via Fastify plugin (key on `X-Lumina-Secret`)
- ElevenLabs `/generate-audio` endpoint
- RAG corpus chunking + embedding pipeline (~1,940 chunks across 4 books)
- pgvector HNSW index post-insert
- Edge function for daily-reading throttle

### 6.2 Models / SwiftData
- `User`, `BirthData`, `NatalChart`, `DailyReading`, `PalmReading`, `JournalEntry`, `Friend`, `OnboardingState`, `AppSettings`
- All models versioned via `SchemaMigrationPlan` from day one — never ship without a migration plan
- Encryption at rest for journal entries (CryptoKit symmetric, key in Keychain)

### 6.3 Test strategy
- **Unit tests**: every actor in Core; every ViewModel state transition
- **Snapshot tests**: every shipped View at 3 sizes (compact, regular, Accessibility XL) and 2 schemes (light/dark)
- **Integration tests**: backend `/chart`, `/synastry`, `/composite` validated against astro.com on 5 fixed birth dates per CI run
- **Manual QA scripts**: `docs/QA_SCRIPTS.md` — 15 step-by-step user flows that block release

### 6.4 Observability
- Sentry-style crash reporting (privacy-preserving)
- Custom analytics events (Amplitude or PostHog) — fewer than 60 events total to avoid event-soup
- Backend health dashboard — Fly.io metrics + Prometheus exporter
- AI cost dashboard — daily $/user, alerts on 2× normal

---

## 7. Definition of Done (per task)

Before a task is `[x]`:

1. Compiles with zero warnings under Swift 6 strict concurrency
2. SwiftLint `--strict` passes on touched files
3. Unit tests written and green
4. Snapshot test added if a new View; 3 sizes × 2 schemes
5. Accessibility label/hint set on every new interactive element
6. PR description answers the **three-question rule** (§1.1)
7. No `print()` in shipped code
8. No P0/P1 `TODO(lumina):` left unaddressed
9. `LEARNINGS.md` updated if a new gotcha was discovered
10. `TASK.md` flipped to `[x]`
11. Conventional commit on the active feature branch
12. PR opened against `develop`

---

## 8. Branching Strategy

```
main          ← App Store production releases only (tagged)
develop       ← always-green integration branch
claude/<task> ← Claude Code working branches (current: claude/roadmap-navigation-improvements-yqxV2)
feature/*     ← human-driven feature work, branched from develop
fix/*         ← bug fixes
release/*     ← release prep (version bump, final QA)
```

Never commit directly to `main` or `develop`.

---

## 9. Version Milestones

| Version | Contents | Target |
|---|---|---|
| 0.2.0 | Phase 1 — Navigation Shell + Design System v2 | Week 2 |
| 0.3.0 | Phase 2 — Onboarding v2 | Week 4 |
| 0.4.0 | Phase 3 — Today (anchor screen) | Week 6 |
| 0.5.0 | Phases 4–5 — Birth Chart + Daily Reading + Audio | Week 11 |
| 0.6.0 | Phase 6 — Palm Reading | Week 15 |
| 0.7.0 | Phase 7 — Compatibility (TestFlight internal) | Week 18 |
| 0.8.0 | Phases 8–10 — Human Design + Reflect + People | Week 25 |
| 0.9.0 | Phases 11–13 — Notifications + Settings + Search | Week 28 |
| 0.95.0-beta | Phase 14 — Accessibility + Localization + Performance | Week 30 |
| 1.0.0-rc | Phase 15 — TestFlight external beta + App Store submission | Week 33 |
| 1.0.0 | App Store release | Week 34 |
| 1.1.0 | Analytics, IAP ladder, retention sequences | Month 10 |
| 1.2.0 | Vedic mode, weekly audio, FR/DE/PT-BR | Month 12 |
| 1.3.0 | Gene Keys + Watch complication + iMessage | Month 14 |
| 2.0.0 | Social feed + live reader marketplace + iPad | Month 18 |

---

## 10. Open questions / blockers (parked here, mirrored in TASK.md)

| Blocker | Impact | Owner |
|---|---|---|
| PP Editorial New license (~$400) | Type system locked to fallback | — |
| Swiss Eph Pro license (CHF 1,550) | Swap from astronomy-engine deferred | — |
| ElevenLabs voice ID (record session) | Audio reading blocked | — |
| Custom palm U-Net model (PolyU/CASIA) | Palm CV blocked | — |
| Supabase project credentials | Auth + RAG blocked | — |
| Apple Developer enrollment + signing | TestFlight + 1.0.0 launch blocked | — |
| Legal review of fortune-telling framing copy | App Review risk | — |

---

*Cut 2026-05-08, branch `claude/roadmap-navigation-improvements-yqxV2`. Supersedes the original v1 roadmap (preserved in git history at `3f99c70`).*
