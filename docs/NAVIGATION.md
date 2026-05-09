# NAVIGATION.md — Lumina Information Architecture & UX Clarity

> Living spec. Every navigation, screen, or component PR must read this first.
> Last cut: 2026-05-08, branch `claude/roadmap-navigation-improvements-yqxV2`.

---

## 1. The clarity contract

A user opening Lumina at any screen must answer three questions in <2 seconds:

1. **Where am I?** — page title in PP Editorial, breadcrumb if nested
2. **What is this telling me?** — hero content, single sentence at the top
3. **What can I do next?** — exactly one primary CTA, one or two secondary actions

If a screen fails any of those, it isn't done. PR template enforces.

---

## 2. The 5-tab spine

```
┌─────────┬─────────┬────────┬─────────┬───────────┐
│  Today  │  Chart  │  Palm  │  People │  Reflect  │
│   ☉     │   ◯     │   ✋   │   ⚭     │   ◐       │
└─────────┴─────────┴────────┴─────────┴───────────┘
```

| Tab | Default content (signed-in returning user) | Default content (first-time, post-onboarding) |
|---|---|---|
| **Today** | Today's reading + transit list + quick actions | "Generating your first reading…" skeleton, completes in <3s |
| **Chart** | Birth chart wheel, default Placidus | Same — chart is computed at end of onboarding |
| **Palm** | History list with "Scan a hand" primary CTA | Empty state: "Scan your hand for the first time" CTA |
| **People** | Friends list sorted by recency | Empty state: "Add your first friend" CTA |
| **Reflect** | Today's prompt, calendar below | Empty state: "Today's prompt is ready" CTA |

### Why five tabs and not four/six?

- **Four** is too thin: Reflect (journal) and People (friends) are both retention-critical and shouldn't share a tab.
- **Six** pushes the last tab off-screen at Dynamic Type Accessibility XL — Apple's tab bar collapses to "More". That breaks discoverability for our most accessibility-sensitive users.

### Tab labels are short, mono-cased, and identical for every user

Names: `Today · Chart · Palm · People · Reflect`. We never localize these into longer phrases (Spanish: `Hoy · Carta · Mano · Gente · Reflejar`). Each is ≤ 7 chars.

### Tab icon is the source of truth, label is the safety net

Icons use the brand glyph set (sun, wheel, hand, infinity-knot, half-moon). Labels are *always* shown — never icon-only.

---

## 3. Screen taxonomy

Every screen is exactly one of:

| Type | Examples | Navigation behavior |
|---|---|---|
| **Hub** | Today, Chart, Palm, People, Reflect | One per tab. Bottom of nav stack. Cannot be popped. |
| **Detail** | Planet detail, Friend detail, Journal entry | Pushed onto the current tab's `NavigationStack`. Has explicit back. |
| **Sheet** | Settings, Glossary entry, Share preview, "How this works" | Slides up. Has explicit close (X) upper-leading. Cannot push more sheets. |
| **Full-screen cover** | Onboarding, Palm capture, Paywall | Owns the whole screen. Has explicit dismissal (Skip / Close / "Maybe later"). |

**Rule: a hub never presents another hub.** If you find yourself wanting that, the architecture is wrong.

---

## 4. Empty, loading, and error states

Every async / data-driven view ships **all four** states. No exceptions.

| State | Component | Notes |
|---|---|---|
| Loading | `LuminaSkeleton` | Mirrors final layout. Lottie constellation only on first cold launch of the day, never on navigation. |
| Empty | `LuminaEmptyState` | Single illustrative glyph + 1-sentence body + 1 primary CTA. CTA must fill the empty state. |
| Error | `LuminaErrorState` | Mapped from `LuminaError`. Always offers retry + cancel. Never shows error codes. |
| Loaded | the actual content | — |

**SwiftLint rule** `lumina_no_dead_end_list` blocks any `LazyVStack` / `List` / `ForEach` over a model collection that doesn't have an empty-state branch.

---

## 5. The primary-CTA rule

Every hub and full-screen cover has **exactly one** primary CTA, rendered as `LuminaButton(.primary)`.

- "primary" = filled, parchment-on-celestial, 56pt height
- "secondary" = outlined, celestial-on-parchment, 44pt height
- "ghost" = text-only, no border, used for "Maybe later" or "Skip"
- "destructive" = filled, parchment-on-error-red, only inside `LuminaConfirmationDialog`

We allow at most one primary + two secondary on a single screen. If a feature wants three primary actions, it's actually three screens.

---

## 6. Onboarding flow (8 screens)

```
launch
  → 1. Brand promise
  → 2. Why are you here? (motivation)
  → 3. Your name
  → 4. Birth date
  → 5. Birth time (with "I don't know")
  → 6. Birth place (with manual fallback)
  → 7. Chart reveal
  → 8. What you can do next ───┐
                                ↓
                          MainTabs(.today)
```

### Persistence

`OnboardingState` is a SwiftData model that stores `currentStep`, all field values, and the navigation path. Updated on every field change. On launch:
- if `currentStep == .complete`: route to `MainTabs(.today)`
- else: route to `Onboarding(resumeAt: currentStep)`

### Recoverability

Force-quit at any screen → relaunch resumes on that screen with field state intact. Tested in CI by killing the app process during simulator UI tests.

### "I don't know" paths

- **Birth time unknown**: chart computed at noon, ASC/MC + cusps hidden, banner explains
- **Birth place unknown / offline**: manual lat/lon entry, "We'll save this — you can correct it later"
- **Sign in skipped**: account deferred until a feature actually requires it (e.g., friend backup)

---

## 7. Deep-link routing

Single declaration, single parser, never two callsites computing the same URL:

```swift
enum LuminaDeepLink: Equatable, Sendable {
    case today
    case chart(planet: String?)
    case palmScan
    case palmHistory
    case people(friendID: UUID?)
    case acceptShare(birthData: BirthData)
    case reflect(entryID: UUID?)
    case settings
    case help(topicID: String?)
}
```

`LuminaDeepLink.from(url:)` is the **only** place `URL` parsing happens. Unit tests cover every case + every malformed URL.

---

## 8. Settings is reachable in one tap from every hub

Top-trailing nav bar gear icon on Today, Chart, Palm, People, Reflect — opens `SettingsView` as a `.sheet`. We never bury settings under a "More" menu or behind a profile avatar.

---

## 9. Confirmation patterns

Every destructive action uses `LuminaConfirmationDialog`:

```swift
.confirmationDialog(
    "Delete this entry?",
    isPresented: $showDeleteConfirm
) {
    Button("Delete", role: .destructive) { ... }
    Button("Keep", role: .cancel) { }
} message: {
    Text("This can't be undone.")
}
```

Soft-delete-with-undo is preferred over modal confirmations when feasible (`Friend` archive, `JournalEntry` trash). 5-second snackbar undo.

---

## 10. Glossary system

Any astrology, palmistry, or HD term in body copy is wrapped in `GlossaryLink`:

```swift
Text("Today, ")
+ GlossaryLink("Saturn return")
+ Text(" enters its second exact aspect…")
```

Tapping opens a `.sheet` with a 1–3 sentence explanation from `Glossary.json`. The glossary is searchable from the Today pull-down (Phase 13).

**CI gate**: a script greps every shipped .swift file for known terms not wrapped in `GlossaryLink` and fails the build if any are bare.

---

## 11. Naming conventions for user-facing copy

| Concept | We say | We don't say |
|---|---|---|
| Today's reading | "Your sky today" / "Read today" | "Daily horoscope" |
| Birth chart | "Your chart" | "Natal chart" (in nav, but ok in body) |
| Palm reading | "Read my hand" | "Palmistry session" |
| Compatibility | "You & them" | "Synastry analysis" |
| Journal | "Reflect" | "Daily journal" |
| Friends | "People" | "Contacts" / "Network" |
| Premium | "Lumina Plus" | "Premium" / "Pro" |
| Login | "Sign in" | "Log in" |
| Birth time unknown | "I'm not sure" | "Unknown" / "N/A" |

These are enforced by the copy review checklist in PR template, not lint.

---

## 12. Loading thresholds (when to show what)

| Wait | Treatment |
|---|---|
| < 100ms | nothing — render the result |
| 100–300ms | `LuminaSkeleton` instantly |
| 300ms–3s | skeleton continues; primary CTA dims |
| 3–10s | skeleton + status sentence ("Computing your chart…") |
| > 10s | timeout → `LuminaErrorState` with retry |

Server-side timeouts: 8s for `/chart`, 6s for daily reading generation, 4s for synastry. Beyond that, fail to retry — never spin forever.

---

## 13. Animation budget

- Slow gyroscope star parallax (8pt magnitude, 120° range)
- 90s chart wheel rotation on first reveal only
- Light haptics on planet glyph tap (`.light`)
- `.smooth` cross-fades on view transitions (200ms)
- Lottie constellations on **only** the first cold-launch loading skeleton of the day

We never use:
- spring bounces on content cards
- confetti, achievement bursts, streak animations (premium signal stays intact)
- screen-shake of any kind
- progress percentages with animated digits

`@Environment(\.accessibilityReduceMotion)` swaps every animation for a 100ms crossfade. PR review checks this for every new animated view.

---

## 14. Permissions request choreography

Every permission asks **after** value is shown, never on first launch.

| Permission | When asked |
|---|---|
| Notifications | After user finishes their first daily reading |
| Camera (palm) | When they tap "Scan a hand" — never sooner |
| Contacts | When they tap "Add from contacts" inside People |
| Face ID (Reflect lock) | When they toggle the setting on |
| Location (rare — only manual edit) | If they tap "Use current location" in birth place edit |

Each system prompt is preceded by a `LuminaCard` "Why we ask" pre-prompt with copy + a non-blocking "Not now" path. This raises opt-in rate ~30% in our category.

---

## 15. Anti-patterns (do not ship these)

- **Onboarding hard paywall with no exit**: Apple now actively rejects. We use a soft post-onboarding offer with explicit "Continue free."
- **Two equally weighted buttons**: collapses decision-making. Pick one primary.
- **Modal-on-modal**: blocks SwiftLint custom rule.
- **Spinner-only loading**: every async screen has a `LuminaSkeleton`.
- **"Learn more" with no destination**: every link must resolve to a real sheet, page, or external URL.
- **Mystic purple gradients**: brand pillar violation.
- **Confetti, streaks, or "x days in a row" gamification**: anti-pattern in this category.
- **Hidden cancel-subscription**: in Settings → Account → "Manage subscription" routes to Apple's native flow in one tap.
- **Hidden delete-account**: same — Settings → Privacy → "Delete my account."

---

## 16. Pull-down search (Phase 13)

Any hub supports a pull-down gesture (≥ 60pt) to reveal a `LuminaSearch` field. Search ranks results across:
1. Glossary entries (highest match weight)
2. Friends (by name)
3. Journal entries (full-text in v1.1; in v1.0 just by date)
4. Planets / placements ("my mars", "my 7th house")
5. Help articles

Returns ≤ 5 results per source, total ≤ 15. Render in < 100ms over local data; no network roundtrip.

---

## 17. Accessibility checklist for every PR

- [ ] Every interactive element has `.accessibilityLabel`
- [ ] Hint added if label is ambiguous
- [ ] Touch target ≥ 44pt (snapshot test confirms)
- [ ] Snapshot at Dynamic Type Accessibility XL has no truncation
- [ ] Color contrast ≥ 4.5:1 for body, 3:1 for large
- [ ] Reduce Motion replaces parallax/Lottie with crossfade
- [ ] VoiceOver order is logical (top-down, leading-trailing)
- [ ] Voice Control: every primary action callable by visible label

PR template requires all eight ticks.
