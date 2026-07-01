# App Capabilities — Implementation Plan

Source: an Xcode/App ID capabilities audit of the current build. Reproduced
here with the plan to turn each "No" into a real, shipped feature (or, for
HealthKit, a documented non-goal).

| Capability | Needed today? | Why |
|---|---|---|
| Push Notifications | No | OneSignal is a dependency but never initialized (`AppDelegate.swift` is a TODO stub). Only local notifications ship, which need zero capability. |
| Sign in with Apple | No | No auth flow exists at all — `.notSignedIn` is a defined `LuminaError` case with no code path that triggers it. App runs fully unauthenticated. |
| Associated Domains | No | All sharing (QR codes, friend links) uses the custom `lumina://` scheme, not `https://` universal links. |
| Background Modes | No | Local notifications use calendar triggers (no background execution needed); WidgetKit refresh is system-managed. |
| HealthKit | N/A | No HealthKit code anywhere. |
| In-App Purchase | No explicit toggle | On-by-default for every App ID. Separate code gap: RevenueCat's SDK is a dependency but `Purchases.configure()` is never called. |

This doc plans the five real rows. **HealthKit stays out of scope** — nothing
in the product (astrology, palm CV, journaling) touches health data, and
adding the capability with no feature behind it is pure App Review risk for
zero benefit. No further action on HealthKit.

---

## Status — [2026-07-01]

Items 1–4 are implemented and pushed (branch `claude/app-capabilities-plan-br64fe`):

- **§1 IAP** — `IAPManager` calls the real RevenueCat SDK; `PremiumStatus` is
  the MainActor-observable mirror; wired into onboarding's trial CTA and
  Settings' "Manage subscription" / "Restore purchases" rows.
- **§2 Push** — `PushNotificationManager` wraps OneSignal; `AppDelegate` now
  initializes it; `NotificationPermission` routes through it (one prompt,
  not two); Palm's "notify me" tags a waitlist segment. The best-effort
  `com.apple.developer.usernotifications.channel` entitlement added for the
  Broadcast Capability was **removed on 2026-07-01** — a signed
  `ios-testflight.yml` archive confirmed it against a real provisioning
  profile and Apple rejected it ("not a valid entitlement"), exactly the
  risk flagged when it was added unverified. Per-device APNs push
  (`aps-environment`) is unaffected.
- **§3 Sign in with Apple** — `AuthManager` + Keychain session + `SignInView`
  fully work standalone; `SupabaseAuthService` layers the identity-token
  exchange on top best-effort (silently no-ops until Supabase exists).
  Settings' row is real: sign in / sign out.
- **§4 Universal links** — `LuminaDeepLink` accepts both schemes; the QR
  share flow emits `https://lumina.app/share/...`; `web/apple-app-site-association`
  + `web/README.md` are ready to deploy once the domain exists.
- **§5 Background Modes** — **not added**. Deliberately deferred: there is no
  audio feature yet to justify the capability (Phase 5 is still blocked on
  ElevenLabs), and adding a capability with nothing behind it is the same
  anti-pattern this whole audit exists to fix. Revisit when Phase 5 ships.

None of items 2–4 can be end-to-end verified without the respective owner
provisioning (OneSignal app + APNs key, Supabase project, `lumina.app`
domain) and, for push/Sign in with Apple specifically, a signed device
build — CI can only confirm these compile and behave correctly in their
dev-safe no-op state.

---

## Summary — what to build, what's blocked, what order

| # | Item | New Xcode capability | Code work | Hard-blocked on | Can build now? |
|---|---|---|---|---|---|
| 1 | **IAP — wire RevenueCat** | None (already on by default) | `Purchases.configure()`, entitlement mapping, call sites in onboarding/paywall/settings | A real `REVENUECAT_API_KEY_IOS` + products configured in the RevenueCat dashboard | **Yes, fully** — code ships now, no-ops safely without a real key (same pattern as every other service in this repo) |
| 2 | **Push — wire OneSignal** | Push Notifications, `remote-notification` background mode | `AppDelegate` init, token registration, tie into existing `NotificationPermission`, segment tagging | A real `ONESIGNAL_APP_ID` + an APNs auth key uploaded to the OneSignal dashboard + Apple Developer push capability enabled on the App ID | **Scaffolding yes, end-to-end no** — needs a signed device build to verify a push actually arrives |
| 3 | **Sign in with Apple** | `com.apple.developer.applesignin` | `AuthManager` actor, `SignInWithAppleButton`, Keychain session, sign-out flow, `.notSignedIn` trigger paths | **Supabase project** (doesn't exist yet — `supabase-swift` has zero call sites in this repo today) | **UI scaffolding yes, real auth no** — there's nothing to authenticate against until Supabase exists |
| 4 | **Associated Domains / universal links** | `applinks:lumina.app` | Universal-link handling in `LuminaDeepLink`/`.onOpenURL`, `apple-app-site-association` file, web fallback page | **A real `lumina.app` domain + hosting** (doesn't exist — Phase 15's privacy/terms pages are in the same boat) | **Parsing scaffolding yes, real link no** — nothing to host the AASA file on |
| 5 | **Background Modes: audio** | `audio` background mode | `MPNowPlayingInfoCenter` + background playback (already tracked as Phase 5 backlog) | ElevenLabs audio pipeline (already a known blocker) | Defer — no reason to add the capability before the feature that needs it exists |

Recommended build order: **1 → 2 (scaffolding) → 4 (scaffolding) → 3
(scaffolding) → 5 (deferred until Phase 5)**. RevenueCat is the only one with
zero external blockers on the *code* side, so it's the highest-value first
step — it turns on the monetization the paywall UI has been simulating since
Phase 2.

---

## 1. In-App Purchase — wire RevenueCat for real

**Current state.** `IAPManager` (`Lumina/Core/IAP/IAPManager.swift`) and
`Entitlements.swift` are a clean actor shape with the right seam — but
`configure(apiKey:)` and `currentEntitlements()` are both TODO stubs, and
**nothing in the app calls `IAPManager` at all** (`grep` confirms the only
reference to `IAPManager` is its own `.shared`). The entire paywall flow
(`PaywallOfferView`, `OnboardingFlowView.handleStartTrial()`,
`PaywallTracker`) is fully built and reachable, but "Start 7-day free trial"
today just calls `persistAndComplete()` — no purchase happens, and Premium
features are gated by nothing (there's no `isPremium` check anywhere yet).

**Why this is the highest-priority item.** No new Xcode capability is
needed — In-App Purchase is on by default for every App ID. This is a pure
code gap, and `REVENUECAT_API_KEY_IOS` is already plumbed end-to-end
(`.env.example` → `inject_env.sh` → `project.yml` → `Info.plist`
`LuminaRevenueCatAPIKeyIOS`) — it's only missing a real value and the actual
SDK calls.

**Plan:**
1. `AppDelegate.application(_:didFinishLaunchingWithOptions:)` — read
   `LuminaRevenueCatAPIKeyIOS` from `Bundle.main.infoDictionary`, call
   `await IAPManager.shared.configure(apiKey:)` (per `LEARNINGS.md`, init here
   not in `LuminaApp.init` — SwiftUI Previews call `init()` in the simulator
   and would crash if configured too early).
2. `IAPManager.configure(apiKey:)` — call
   `Purchases.configure(withAPIKey:)`, guard against a placeholder/empty key
   (same "missing config → dev-safe no-op" pattern `EphemerisService` and
   `LuminaAIClient` already use) so CI/simulator builds without a real key
   don't crash.
3. `IAPManager.currentEntitlements()` — map
   `Purchases.shared.customerInfo().entitlements` to `Set<Entitlement>`.
   Adopt `PurchasesDelegate` per the `LEARNINGS.md` pattern (cache
   `isPremium`, update via `purchases(_:receivedUpdated:)` — don't call
   `getCustomerInfo()` on every view appear).
4. Add a real purchase call: `IAPManager.purchase(package:)` wrapping
   `Purchases.shared.purchase(package:)`, surfacing `LuminaError` on failure
   (cancellation should be silent, not an error toast).
5. Wire call sites:
   - `OnboardingFlowView.handleStartTrial()` — replace the TODO with an
     actual purchase call; only call `persistAndComplete()` on success (or
     on user-cancel, per the "never trap the user" rule — cancelling a
     purchase should behave like "Continue free", not get stuck).
   - Add a `PremiumGate` helper (or an `@Environment` flag) that views can
     check instead of each hand-rolling entitlement logic — the Reflect
     (monthly patterns), Palm (unlimited scans), People (Crush Report),
     Chart (narrated audio, once Phase 5 ships) gates already exist as UI
     but currently gate on nothing.
   - Settings → "Manage subscription" deep link
     (`itms-apps://apps.apple.com/account/subscriptions`) and "Restore
     purchases" action (`Purchases.shared.restorePurchases()`) — both are
     already backlogged in TASK.md Phase 12, unblocked by this work.
6. RevenueCat dashboard setup (owner action, not code): create the
   `lumina_plus` entitlement (must match `Entitlement.luminaPlus`'s raw
   value), monthly + annual products only (Critical Rule #3 — no weekly
   tier), attach to App Store Connect subscription products.

**Acceptance criteria:** a CI/simulator build with an empty
`REVENUECAT_API_KEY_IOS` still boots and shows the paywall (no crash, no
premium features unlocked); a signed device build with a real sandbox
Apple ID can complete a trial purchase and `isPremium` flips true within one
`customerInfo` update.

**Testing given no-Mac:** `Purchases.configure` and `customerInfo()` mapping
are unit-testable with RevenueCat's mock/test doubles in `LuminaTests`
(actor logic, entitlement mapping) — CI covers this. The actual App
Store sandbox purchase flow needs a signed device build (TestFlight), same
constraint as the rest of IAP/push testing.

---

## 2. Push Notifications — wire OneSignal

**Current state.** `OneSignal` is a Swift Package dependency
(`project.yml`) and `LuminaOneSignalAppID` is plumbed through
`Info.plist`, but `AppDelegate` line 12 is a bare TODO comment — the SDK is
never touched. Only `TransitNotificationScheduler` ships today, and it's
explicitly local-only (`UNUserNotificationCenter`, calendar triggers, "no
OneSignal, no server push" by design per its own doc comment) — that's a
different, working feature and stays as-is.

**New Xcode capabilities needed:**
- **Push Notifications** capability on the `app.lumina.ios` App ID
  (Developer portal) + entitlement `aps-environment` in
  `Lumina/Lumina.entitlements` (added via `project.yml`
  `targets.Lumina.entitlements.properties`, same pattern already used for
  the App Group).
- **Background Modes → Remote notifications** — only required if OneSignal
  needs to deliver silent/background pushes (e.g. badge refresh, content
  update). For a v1 "daily reading is ready" alert push, this is **not**
  required — a standard alert push wakes the app via the normal
  notification-tap path. Recommendation: skip this background mode for v1,
  add it only if/when a silent-push use case is scoped.
- ~~`com.apple.developer.usernotifications.channel`~~ — **not a real
  entitlement.** This was a best-effort guess at a Broadcast Capability
  sub-toggle; a signed archive against a real provisioning profile
  confirmed Apple rejects it. There is no channel/broadcast entitlement
  exposed via Xcode's capability editor today, so OneSignal segment
  broadcasts go out as ordinary per-device APNs sends (fan-out handled on
  the OneSignal side, not via an app entitlement) — no code or capability
  change needed for that.

**Plan:**
1. `AppDelegate` — `OneSignal.initialize(appId, withLaunchOptions: launchOptions)`
   before requesting any notification permission (per `LEARNINGS.md`).
   Guard on a non-empty/non-placeholder app ID, same dev-safe-no-op pattern
   as IAP.
2. Bridge `OneSignal`'s permission API with the existing
   `NotificationPermission` helper (`Core/Notifications/NotificationPermission.swift`)
   rather than duplicating a second permission flow — one prompt, one
   `Status` enum, both local and OneSignal-delivered notifications ride the
   same OS authorization.
3. Token/subscription registration — OneSignal handles APNs token exchange
   internally once initialized; add tagging for the 4 planned segments
   (premium / free / lapsed / cohort-by-motivation per `ROADMAP.md`) via
   `OneSignal.User.addTag(...)` once `UserBirthDataStore`/`IAPManager`
   state is available.
4. Keep the **contextual permission timing** already decided in
   `LEARNINGS.md`: prompt after the paywall, ideally on the "your daily
   reading is ready" moment — not a cold first-launch prompt.
5. Server-side sends (daily morning push, weekly "week ahead", event
   pushes capped at 5/week — all already TASK.md Phase 11 backlog items)
   are a OneSignal-dashboard/API concern, not app code, once the app is
   registering devices.
6. Update the `PalmHubView.swift:93` TODO ("wire to Anthropic email capture
   or OneSignal segment") once tagging exists.

**Owner action items:** create the OneSignal app, get `ONESIGNAL_APP_ID`;
generate an APNs auth key (`.p8`) in the Apple Developer portal and upload
it to the OneSignal dashboard (one key covers all environments, no need to
manage separate dev/prod certs); enable **Push Notifications** on the
`app.lumina.ios` identifier.

**Acceptance criteria:** a signed TestFlight build registers a device with
OneSignal (visible in the OneSignal dashboard as a subscribed user) and a
test push sent from the dashboard is received and deep-links to the Today
tab via the existing `LuminaDeepLink` handling.

**Testing given no-Mac:** CI's simulator build (`CODE_SIGNING_ALLOWED=NO`)
can verify the app still compiles and boots with the capability/entitlement
added (same pattern the widget's App Group used — signing is skipped so
entitlements aren't validated against a profile). Actual push delivery can
only be verified on a signed device build via `ios-testflight.yml`.

---

## 3. Sign in with Apple

**Current state.** There is no auth flow of any kind. `.notSignedIn` exists
in `LuminaError` with full copy (`userTitle`/`userBody`/`recoveryActionTitle`)
but is never thrown or referenced by any view. `supabase-swift` is a
declared package dependency with **zero `import Supabase` sites in the
codebase** — this is further behind than push or IAP, because there's
nothing to authenticate against yet.

**Why this is blocked deeper than the others.** Sign in with Apple's
on-device half (the `ASAuthorizationController` flow) is buildable today
with zero external dependencies. But a sign-in that goes nowhere is not a
useful feature — the entire point (per `ROADMAP.md`: sync birth chart /
journal / friends across devices, "Sign out flow — clears Supabase
session") requires a backend identity to exchange the Apple identity token
for a session. That backend is Supabase, and the Supabase project is a
**pre-existing blocker** (`TASK.md` Blockers table: "Supabase project
credentials — Auth + RAG corpus blocked"). This item can't reach "done"
before that blocker clears.

**New Xcode capability:** Sign in with Apple
(`com.apple.developer.applesignin`) — entitlement added the same way as the
App Group, via `project.yml` `targets.Lumina.entitlements.properties`.

**Plan (buildable now, unblocked):**
1. `Core/Auth/AuthManager.swift` — new `@MainActor @Observable` actor-adjacent
   class (mirrors the `AppLock`/`NotificationPermission` shape) wrapping
   `ASAuthorizationController` with an `ASAuthorizationControllerDelegate`
   + `ASAuthorizationControllerPresentationContextProviding` conformance.
   Exposes `signIn() async throws -> AppleIDCredential` (userIdentifier,
   email, fullName — email/name are only provided on the *first*
   authorization, so persist them immediately).
2. A `SignInWithAppleButton` (native SwiftUI wrapper) in a new
   `Features/Auth/SignInView.swift`, styled per `LuminaButton` conventions
   where possible (Apple's HIG constrains the button's own styling, so this
   is one of the few places brand tokens don't fully apply — document that
   in a comment).
3. Session persistence seam: a `Keychain`-backed `AuthSession` struct
   (userIdentifier + cached display info), following this repo's
   established persistence-seam pattern (`AppRouterStorage` /
   `OnboardingStorage`'s protocol-backed storage, not a new bespoke
   mechanism) — but Keychain, not UserDefaults, since this is an identity
   credential.
4. `ASAuthorizationAppleIDProvider().getCredentialState(forUserID:)` on
   launch to detect revoked/signed-out state and clear the local session.

**Plan (blocked on Supabase, do only once the project exists):**
5. `import Supabase`; `SupabaseClient(supabaseURL:supabaseKey:)` using the
   already-plumbed `LuminaSupabaseURL`/`LuminaSupabaseAnonKey`.
6. Exchange the Apple identity token via Supabase's native Sign in with
   Apple support: `client.auth.signInWithIdToken(credentials:
   OpenIDConnectCredentials(provider: .apple, idToken: ...))`. This is the
   one Supabase-side integration that needs one-time dashboard config
   (enable the Apple provider in Supabase Auth settings using the same Team
   ID / Services ID / key — standard Supabase+Apple setup, documented in
   Supabase's own docs).
7. Trigger `.notSignedIn` from the real gaps it's meant to cover — sync
   actions (backup friends list, cross-device chart sync) become the first
   call sites that actually throw it instead of it being dead code.
8. Sign-out flow (Settings, already TASK.md Phase 12 backlog): clear
   Supabase session + Keychain, **retain local SwiftData** (per
   `ROADMAP.md` line 630 — sign-out is not a data wipe), require Face ID
   re-auth on next sensitive screen.
9. `user_profiles` row creation timing: per `ROADMAP.md` line 259, this
   moved from onboarding screen 2 to a **contextual prompt after the user
   has seen their chart** — same "don't gate the free experience"
   philosophy as the paywall. Sign-in should never block reaching the
   first chart reveal.

**Acceptance criteria:** on a signed device/simulator with a real Apple ID,
tapping "Sign in with Apple" from its contextual entry point completes in
under 5 seconds and (once Supabase exists) creates exactly one
`user_profiles` row per Apple user ID, with a second sign-in reusing it.

**Testing given no-Mac:** the `ASAuthorizationController` flow itself needs
a signed context to test meaningfully (Sign in with Apple doesn't
function in an unsigned CI simulator build the way local notifications do)
— CI can only verify it compiles. Full verification is a TestFlight/device
task, gated further by Supabase provisioning.

---

## 4. Associated Domains / universal links

**Current state.** Every *viral* share flow (`ChartShareButton`,
`CompatibilityShareButton`, `DailyReadingShareButton`) shares a rendered PNG
file with **no link at all** — nice image, no way back to the app for a
recipient who doesn't have it installed. The one flow that does carry a
link is friend-to-friend chart sharing (`ShareQRView` /
`AcceptShareView`), which encodes `lumina://share/<base64url-json>`.
Custom URL schemes have two real problems this doesn't fix today: (a) if
the recipient doesn't have Lumina installed, the link does *nothing* —
there's no App Store fallback; (b) any other app could in principle
register the same `lumina://` scheme.

**New Xcode capability:** Associated Domains
(`applinks:lumina.app`), entitlement added via `project.yml`
`targets.Lumina.entitlements.properties` alongside the existing App Group
entry.

**Hard blocker:** hosting `https://lumina.app/.well-known/apple-app-site-association`
requires a real domain with real hosting — **this doesn't exist yet**.
`ROADMAP.md`/`TASK.md` Phase 15 already has `lumina.app/privacy`,
`/terms`, and `/press` as unshipped, so this is one deliverable (a small
static site) that unblocks universal links, the privacy policy URL, the
terms URL, and the press kit simultaneously — worth scoping as one small
web project rather than four.

**Plan (buildable now, unblocked):**
1. Extend `LuminaDeepLink` to parse `https://lumina.app/...` paths with the
   *same* cases the `lumina://` scheme already handles (chart planet,
   friend share, settings, help) — one parser, two schemes in, same
   `AppRouter.handle(deepLink:)` sink. `LuminaDeepLink.init?(url:)` should
   accept either scheme uniformly rather than branching by feature.
2. Add `.onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` in
   `LuminaApp`/`RootView` alongside the existing `.onOpenURL` handling, both
   feeding the same `AppRouter.handle(deepLink:)`.
3. Migrate the friend-share QR payload (`ShareQRView`) from
   `lumina://share/<data>` to `https://lumina.app/share/<data>` — same
   payload shape, new scheme, so `AcceptShareView`'s decode logic is
   unchanged. This is the one existing feature that directly benefits: a
   scanned QR now opens either the app (if installed) or a web landing page
   with an App Store link (if not) instead of doing nothing.
4. Add web fallback content awareness: the AASA file plus a minimal static
   landing page (`lumina.app/share/*` → "Open in Lumina" / App Store
   badge) is a **web deliverable**, not Swift — scope it alongside the
   Phase 15 privacy/terms pages rather than as new iOS work.

**Plan (blocked on the domain, do once hosting exists):**
5. Generate and publish
   `.well-known/apple-app-site-association` (`applinks` → `appID` `<TeamID>.app.lumina.ios`,
   `paths` → the share/chart/settings/help routes) at the domain root over
   HTTPS with no redirects (Apple's CDN fetch requirements are strict about
   this).
6. Confirm the Team ID (documented in `docs/TESTFLIGHT.md` as
   `S3U8B8HH96` — reuse it here rather than re-deriving).

**Acceptance criteria:** tapping a `https://lumina.app/share/...` link on a
device with Lumina installed opens the app directly to `AcceptShareView`
with no Safari interstitial; the same link on a device without the app
opens Safari to a working landing page.

**Testing given no-Mac:** universal link *validation* (Apple fetching and
caching the AASA file) can't be verified without the real domain live —
Apple's `swcutil` diagnostic tooling is also Mac-only. CI can unit-test the
`LuminaDeepLink` parser against both schemes without any network access,
which is most of the actual logic risk.

---

## 5. Background Modes

**Current state — correctly "No" today.** `TransitNotificationScheduler`
uses `UNCalendarNotificationTrigger` (OS-scheduled, no app code runs in the
background) and the WidgetKit timeline refresh is system-managed
(`WidgetCenter`/`TimelineProvider`, not a background-mode-gated API). No
background execution happens today, so no capability is warranted today.

**When it becomes needed:** TASK.md Phase 5 (Daily Reading + Audio) already
backlogs "Background audio + `MPNowPlayingInfoCenter` artwork" and "AirPlay
2 / CarPlay support" — background audio playback is the one concrete,
already-planned feature that will need the **Audio, AirPlay, and Picture
in Picture** background mode. That phase is itself blocked on the
ElevenLabs voice pipeline (existing blocker).

**Plan:** do nothing now. When Phase 5's audio player is built, add
`UIBackgroundModes: [audio]` to `Info.plist` (via `project.yml`
`info.properties`) alongside the `AVAudioSession` category setup
(`.playback`) and `MPRemoteCommandCenter` wiring. Re-evaluate whether push
ever needs `remote-notification` background mode at that time too (it
still won't, unless a silent-push use case is scoped — see §2).

No action item; revisit when Phase 5 unblocks.

---

## Owner action items — consolidated

Everything below only the account/domain owner can do (mirrors the
existing `TASK.md` Blockers table format):

| Action | Unblocks |
|---|---|
| Create RevenueCat account, configure `lumina_plus` entitlement + monthly/annual products, get API key | §1 IAP |
| Create OneSignal app, get App ID, generate + upload an APNs auth key, enable Push Notifications capability on `app.lumina.ios` | §2 Push |
| Provision the Supabase project (already tracked) | §3 Sign in with Apple |
| Register `lumina.app` domain + hosting; enable the Sign in with Apple provider in Supabase Auth settings | §3, §4 |
| Register Associated Domains capability + Sign in with Apple capability on the `app.lumina.ios` identifier in the Developer portal | §3, §4 |

---

## How this maps onto existing tracking

- `TASK.md` Phase 2 already lists "Sign in with Apple (deferred to after
  first chart reveal)" — this doc is the detailed plan for that line.
- `TASK.md` Phase 11 already lists the OneSignal backlog items — this doc
  sequences the `AppDelegate`/`NotificationPermission` wiring that unlocks
  them.
- `TASK.md` Phase 12 already lists "Manage subscription deep link",
  "Restore purchases action + toast", "Sign out flow" — all unblocked by
  §1 and §3 respectively.
- The RevenueCat core-wiring gap (§1) had no dedicated TASK.md line before
  this doc — `ReflectHubView.swift`'s comment ("the actual purchase wires
  through RevenueCat in Phase 16") is a mislabel: ROADMAP.md Phase 16 is
  the *post-launch IAP ladder* (Year Ahead, Career Forecast, etc.), not the
  core `Purchases.configure()` wiring, which blocks every existing Premium
  gate today and should ship independently of Phase 16.
