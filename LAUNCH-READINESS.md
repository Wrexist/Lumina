# Lumina — Pre-Launch Readiness Punch List

> Compiled 2026-08-04 from eight parallel audits (build/CI, crash & correctness, feature
> completeness, backend, App Store submission, tests & security, UX/a11y, docs-vs-reality).
> Every P0 below was independently re-verified by hand — including three findings that
> were **retracted** as false positives (see *Corrections* at the end).

---

## Verdict

The engineering discipline here is genuinely above average: zero `!`/`try!`/`as!`/`fatalError`
in the entire app (SwiftLint enforces it as an error), `#if DEBUG` guards that refuse to fake
data in release, honest error mapping, and a deep-link parser that correctly rejects
`evil.lumina.app`. Loading and empty states are near-universal.

The gaps are not spread thin — they cluster in four places:

1. **Money.** The subscription sells six features and gates none of them.
2. **The outside world.** No domain, no deployed backend, and a config pipeline that
   corrupts the backend URL — so charts and shares both die in a real build.
3. **Claims.** README, paywall, App Store metadata, Help articles, and the published
   privacy policy all describe features that don't exist in the binary.
4. **Secrets.** A live API key on `main` that the CI secret gate is structurally unable to see.

None of this is unrecoverable, but the app is **not** currently launch-ready, and the green
CI checkmark is measuring the wrong things. Realistic estimate: **P0+P1 is 3–5 focused weeks.**

---

## Status — 2026-08-06, art integration + metadata pass

The 26 generated assets are wired into the app (see `docs/ASSET-BRIEF.md` §
*Where each asset landed*), and the App Store metadata now lives in
`metadata/app-store.json` behind a linter (`docs/aso/`).

Doing that work surfaced **five more instances of the same defect this audit
was created for** — shipped copy describing an app that doesn't exist. None
were in the P0/P1 list, because the list was built from the code as it was,
and all five sat in places nobody re-reads:

| Found | Where | Now |
|---|---|---|
| "Lumina is a premium astrology and **palm-reading** app… on-device palm analysis" | `HelpView` — two articles above the FAQ admitting palm isn't built | Rewritten; the Palm help topic is gone; `ReleaseAccuracyTests` fails the build on a repeat |
| Four palmistry glossary definitions for a feature with no surface | `Glossary.json`, under "every term in Lumina" | `GlossaryStore.shipped(_:)` filters them, keyed to `LuminaTab.visible` |
| "Lumina **actually traces your lines** with an on-device model trained on real palm images" | `PalmHubView` — present tense, no model exists | Rewritten to future tense with an explicit "isn't built yet" |
| "We never sync names or birthdays to a server" | `TabPreviews` — the People **screenshot**, after the real card was corrected | Corrected; the screenshot suite now uses the real components |
| `tarot` in the keyword field | previous listing draft — no tarot deck in the app | Removed; `aso_lint.py` fails on it |

Plus two dead-link classes: every published support address was at
`lumina.app`, a domain that was never registered (mail bounced); and the
privacy page still said data export was "planned but not available" months
after it shipped.

One gap the audit never listed, because it was an absence rather than a wrong
claim: **the app never asked for an App Store rating.** No `requestReview`
anywhere in the tree. A listing with no ratings converts worse than the same
listing with twenty, so for an app whose whole distribution story is search,
that is a launch defect. It now asks — once per version, after the daily
reading has been unveiled on three separate days, and structurally never from
an error state. See [`docs/aso/RATINGS.md`](docs/aso/RATINGS.md).

**The lesson to carry forward:** the audit fixed the claims in the places it
looked — the app name, the keywords, the marketing site. The same claims
survived in Help, the glossary, a preview, and a screenshot. Accuracy needs a
test, not a pass. There are now three: `ReleaseAccuracyTests`,
`scripts/aso_lint.py`, and the screenshot suite rendering real components
instead of lookalikes.

---

## Status — 2026-08-04, end of the remediation pass

**Every P0 and P1 in this document has been fixed in the repo, along with most of P2/P3.**
The unchecked boxes below are kept as the record of what was found; the fixes are in the
branch history, each commit naming the specific defect. What is left is not code:

| Left to do | Where |
|---|---|
| Everything in **Owner action items** near the end of this file | outside the repo |
| Localization (English-only at 1.0 — deliberately, see `ROADMAP.md` Phase 14) | deferred |
| Palm reading | deferred; absent from the binary *and* from all metadata |
| Cloud backup/restore, data export, contacts import, Human Design design-side chart | roadmap |
| Content depth (reading/prompt/quiz variety) | roadmap |

Two things worth carrying forward from doing this work:

1. **CI was measuring the wrong things, and that was the root cause of several P0s.** The
   backend crashed on boot under its production entrypoint while `tsc` and `vitest` both
   passed; the injected backend URL truncated at `//` and nothing checked; gitleaks had no
   rule for the key that actually leaked. Each is now gated by something that would have
   caught it: CI boots the real entrypoint and probes `/health`, `inject_env.sh`
   round-trip-verifies every value it writes, `.gitleaks.toml` has an explicit Anthropic
   rule, and `ios-testflight.yml` — which uploads to real testers — no longer skips lint
   and tests.
2. **Verify before fixing.** Three findings were retracted as false positives (see
   *Corrections*), and "fixing" the first would have shifted every chart in the app.

---

## P0 — Ship-stoppers (nothing else matters until these are done)

### Security

- [ ] **P0-1 · Revoke the committed Anthropic API key — now.**
  `backend/.env` is git-tracked (entered at commit `2e0a0af`, *"Update and rename .env.example
  to .env"* — the rename moved the real file out from under its own gitleaks exemption) and is
  on `main`. `.gitignore:64` lists it, but gitignore does not untrack an already-tracked file.
  → Revoke at console.anthropic.com, `git rm --cached backend/.env`, purge history
  (git-filter-repo/BFG), restore `backend/.env.example` with blank values.

- [ ] **P0-2 · The secret-scan gate cannot detect Anthropic keys.**
  `.github/workflows/ci.yml:96-103` pins gitleaks 8.18.4, whose default ruleset has no
  Anthropic rule; `generic-api-key` does not match the `sk-ant-api03-` shape. Reproduced:
  the scan reports "no leaks found", exit 0, with P0-1 sitting in plain text — while a
  planted AWS key is flagged instantly. The gate has been reassuring reviewers for a month.
  → Add to `.gitleaks.toml`: `regex = '''sk-ant-(api03|admin01)-[A-Za-z0-9_\-]{80,}'''`,
  drop the wholesale `.env.example` path allowlist, and add a second full-history pass
  (the current `--no-git` flag scans only the working tree).

### The app cannot actually work in a real build

- [ ] **P0-3 · The backend does not boot in production.** *(reproduced)*
  `backend/src/lib/interpret.ts:34-37` uses a TypeScript parameter property
  (`constructor(public readonly status: number, …)`). The production entrypoint
  (`Dockerfile:23`, `package.json:12`) is `node --experimental-strip-types`, which rejects it:
  `SyntaxError [ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX]`. Every Fly deploy crash-loops.
  CI is green because vitest transpiles via esbuild and `tsc --noEmit` doesn't care —
  **nothing in CI ever executes the real entrypoint.**
  → Assign the fields in the constructor body. Add a CI step that boots
  `node --experimental-strip-types src/server.ts` and curls `/health`.

- [ ] **P0-4 · The secrets pipeline silently truncates every URL it writes.** *(verified)*
  `scripts/inject_env.sh:47-49` names the hazard in its own comment and then does nothing:
  `printf '%s = %s\n'` writes the raw value into an `.xcconfig`, where `//` begins a comment.
  `SWISS_EPH_SERVICE_URL = https://lumina-ephemeris.fly.dev` parses as `https:`.
  `SUPABASE_URL` has the same defect. CI never catches it (simulator builds are *expected*
  to hit `.missingConfiguration`); it first manifests in the TestFlight/App Store build,
  where `BuildConfig.realValue("https:")` passes the non-empty guard and the app quietly
  fails every backend call.
  → Escape as `https:$()//host`, and assert the parsed value round-trips before archiving.

- [ ] **P0-5 · The release lane has no secrets guard.**
  `inject_env.sh:56` writes `KEY = ` for any unset var, and `ios-testflight.yml:53` never
  validates that `SWISS_EPH_SERVICE_URL` / `SWISS_EPH_API_SECRET` / `REVENUECAT_API_KEY_IOS` /
  `ONESIGNAL_APP_ID` are non-empty. With them blank the shipped app has no charts, no IAP,
  and no push — a guaranteed Guideline 2.1 rejection.
  → Fail-fast step after `Inject env`, before `xcodebuild archive`.

- [ ] **P0-6 · The backend has never been deployed, and Release has no fallback.**
  `fly.toml` + `Dockerfile` exist but there is **no deploy workflow** — `.github/workflows/`
  holds only `ci.yml` and `ios-testflight.yml`; deployment is three hand-typed `fly` commands.
  In Release, `BirthChartViewModel.swift:145-149` deliberately drops the debug sample-chart
  fallback, so an unreachable backend means Chart, Today, People, and Reflect all show errors.
  No failover, no cached-degraded mode, no status page, no alerting. `fly.toml:20-22` sets
  `min_machines_running = 0` with `auto_stop_machines = "suspend"`, so the first user of the
  day eats a cold start against the client's 10 s timeout.
  → Deploy, add a deploy workflow, set `min_machines_running = 1`, add an uptime check.

- [ ] **P0-7 · `lumina.app` does not exist — every share link is dead.**
  `ShareQRView.swift:139` mints `https://lumina.app/share/<payload>`; `project.yml:145-146`
  declares `applinks:lumina.app`; no AASA is served. Every QR code and shared link 404s in
  Safari and never opens the app, making `AcceptShareView` unreachable in practice. Also
  kills `feedback@` / `support@` / `privacy@lumina.app` (`HelpView.swift:192`,
  `docs/support.html`, `docs/privacy.html`).
  → Host the domain + AASA (re-verify the hard-coded `S3U8B8HH96.app.lumina.ios` against the
  real Team ID), or fall back to the already-registered `lumina://` scheme for v1.

- [ ] **P0-8 · Confirm the legal URLs actually resolve.**
  `LuminaLegalLinks.swift:14` → `https://wrexist.github.io/Lumina/privacy.html`.
  `docs/` is complete and genuinely deployable, but GitHub Pages requires a one-time manual
  toggle (`docs/WEBSITE.md`) that nothing in the repo proves has been done, and no `docs/CNAME`
  or Pages workflow exists. A dead Privacy Policy link **on a subscription paywall** is an
  automatic 3.1.2 rejection.
  → Load all three URLs in a browser and confirm 200 before pasting them into App Store Connect.

### Money — the subscription sells nothing

- [ ] **P0-9 · Nothing is gated behind the entitlement.**
  `PremiumStatus.isPremium` is read in exactly **one** place app-wide —
  `ReflectHubView.swift:140` — to hide a dismissible banner. `IAPManager.currentEntitlements()`
  is never called; `LuminaError.subscriptionRequired` is never thrown. All six benefits listed
  at `PaywallOfferView.swift:115-121` already work for free.
  → Gate the advertised features, or rewrite the paywall to describe what Plus really gives.

- [ ] **P0-10 · There is no way to subscribe after onboarding.**
  `PaywallOfferView` has one instantiation (`OnboardingFlowView.swift:44`) and
  `purchaseCurrentOffering()` one call site (`:148`), gated on a one-shot
  `hasSeenInitialOffer`. `SettingsView` offers only "Manage subscription" and "Restore".
  A user — or a reviewer — who taps "Continue free" can never find the IAP.
  → Persistent "Lumina Plus" row in Settings + make the Reflect banner tappable.

- [ ] **P0-11 · The paywall sells a feature that was never built.**
  `PaywallOfferView.swift:119` and `ReflectHubView.swift:145,157` promise journal
  "pattern detection"; only comments exist (`JournalPromptGenerator.swift:73`).

- [ ] **P0-12 · The "30% off" rescue offer charges full price.**
  `PaywallOfferView.swift:39,78,136` shows `$41.99` / "30% off", but `handleStartTrial`
  calls the same `purchaseCurrentOffering()`, which always buys `offering.annual` ($59.99)
  — `IAPManager.swift:86`. Advertised price ≠ charged price. Guideline 3.1.2 / 2.3.1.

- [ ] **P0-13 · A failed purchase is indistinguishable from success.**
  `OnboardingFlowView.swift:147-150`: `_ = try? await …` discards `.notConfigured`,
  `.noOfferingsAvailable`, and every StoreKit error. If RevenueCat isn't provisioned at
  review time, the primary CTA is a silent no-op and the user believes the trial started.

### Guaranteed App Review rejections

- [ ] **P0-14 · Account deletion never deletes the account.** *(Guideline 5.1.1(v))*
  `SupabaseAuthService.swift:95-100` unconditionally throws `.missingConfiguration`;
  `AuthManager.swift:184-192` swallows it; `SettingsView.swift:262-307` wipes only local
  stores while the dialog claims "permanently erases your Lumina account". The Sign in with
  Apple token is never revoked. `docs/privacy.html` repeats the false claim.

- [ ] **P0-15 · App name/subtitle/keywords sell Palm; the Palm tab is unreachable.**
  `docs/APP-STORE-LISTING.md:17,30,228` (name *"Lumina: Astrology & Palm"*, subtitle
  *"Real birth charts & palmistry"*, review note claiming the tab shows an in-progress state)
  vs `LuminaTab.swift:22` (`.palm` not in `visible`) and `AppRouter.swift:112` (palm deep
  links clamp to Today). `PalmHubView` has no reachable entry point. Guideline 2.3.1.
  → Ship as *"Lumina: Astrology & Charts"* until palm is real, and strip the Help articles
  (`HelpView.swift:58-66`), Settings row, and privacy-dashboard bullet that reference it.

- [ ] **P0-16 · Privacy manifest failures will bounce the upload (ITMS-91053).**
  (a) The `LuminaWidget` target ships **no** `PrivacyInfo.xcprivacy` (`project.yml:177-204`)
  yet compiles `WidgetSharedStore.swift:26-30`, which calls `UserDefaults`.
  (b) `PrivacyInfo.xcprivacy:79` declares only `CA92.1`, but `UserDefaults(suiteName:)`
  requires `1C8F.1`.
  (c) Precise birth coordinates are transmitted to the backend but no location data type
  is declared — also a disclosure gap, since coordinates + timestamp are re-identifying.

### Data loss

- [ ] **P0-17 · No SwiftData migration plan — the first schema change bricks the app.**
  `LuminaApp.swift:21` uses `.modelContainer(for: [JournalEntry.self, Friend.self])` — the
  convenience modifier, which **traps** when the store can't be opened. No `VersionedSchema`,
  no `SchemaMigrationPlan` anywhere. Both models carry `@Attribute(.unique) var id: UUID`,
  and adding/removing a unique constraint is *not* lightweight-migratable. Post-1.0 this
  kills the app on the launch screen and destroys every journal entry.
  `TASK.md:383` already says "no shipping without one".
  → Ship an explicit V1 `VersionedSchema` + `SchemaMigrationPlan` with an `onSetup:` fallback
  **before** the first App Store build — v1.0's schema is the baseline you can never change.

---

## P1 — Must fix before launch

### Crashes & stuck states

- [ ] **P1-1 · Delete-then-render on a live `@Model`.** `JournalEntryDetailView.swift:113-119`
  and `FriendDetailView.swift:273-277` both `delete` → `save` → `dismiss()`. `dismiss()` is
  async (~350 ms of pop animation) while `body` still reads `entry.prompt`/`entry.body`/
  `entry.wordCount` (and `friend.name`/`birthDate`/…) off the now-invalidated model.
  → Dismiss first, delete on the next runloop turn. (`PeopleHubView` already dodges this with
  a 4 s soft-delete; the detail screens bypass it.)
- [ ] **P1-2 · Account deletion erases models while the tab UI is still mounted.**
  `SettingsView.swift:262-307` — `eraseLocalData()` destroys every `Friend`/`JournalEntry`
  and keeps awaiting while `MainTabsView` is alive; the gear is reachable from a pushed
  `FriendDetailView`. Also swaps the root scene before `dismiss()`, which can strand a blank
  sheet. → `resetForSignOut()` + `dismiss()` first, then erase.
- [ ] **P1-3 · Today can wedge permanently on the loading skeleton.**
  `TodayViewModel.swift:85-93,135-140` — the cancellation branch `return`s without leaving
  `.loading`, and the re-entry guard short-circuits on `.loading`. The `.task` is structured,
  so it *is* cancelled when the view disappears. Repro: cold launch → switch tabs mid-fetch →
  Today shows skeletons forever with no retry button; `refresh()`, the day-rollover publisher,
  and the `scenePhase` handler all short-circuit too. Only a force-quit clears it.
  → Reset `state = .idle` in the cancellation branch.
- [ ] **P1-4 · Onboarding chart reveal dead-ends on "Not now".**
  `OnboardingScreens+Reveal.swift:98-100` — `handleCancel()` only clears the error, dropping
  the user back to an infinite spinner with Continue disabled (`chartReady` still false) and
  nothing to re-trigger `compute()`. Separately, in Release with a configured backend there is
  **no way for an offline user to finish onboarding at all**.
- [ ] **P1-5 · Release builds fake "Your chart is ready" when the backend is unreachable.**
  `OnboardingScreens+Reveal.swift:107-113,119-123` — the `.missingConfiguration` catch sleeps
  800 ms and sets `chartReady = true` with **no `#if DEBUG` guard**, unlike every other
  synthesised path in the codebase. The user completes onboarding, then lands on "App is
  mid-setup".

### Correctness

- [ ] **P1-6 · Birth-place resolution silently falls back to UTC.**
  `BirthPlaceSearch.swift:71`: `item.timeZone ?? TimeZone(identifier: "UTC") ?? .gmt`.
  `MKMapItem.timeZone` is not always populated — a Los Angeles birth then computes 8 hours
  off (wrong Ascendant, wrong houses, Moon possibly in the wrong sign) with no indication,
  and the bad zone is persisted into `BirthData` and every downstream share and comparison.
  For an app pitched as *"Finally, a real one"* this is the worst failure mode.
  → Treat nil as unresolved and surface the manual sheet (which already validates the zone).
  *(MapKit also returns the present-day zone, not the historical zone at the birth instant.)*
- [ ] **P1-7 · The headline compatibility score is a hash.**
  `FriendDetailView.swift:200-212` → `CompatibilityScorer.swift:78-80` — a Sun-sign
  element/modality heuristic plus a deliberate FNV-hash jitter of ±5, rendered as a 56 pt
  "72/100 · Harmonious" with no disclosure and cached to the model. Sun sign comes from a
  hardcoded date table (`:147-165`), not the ephemeris, so cusp births are misclassified.
  This is precisely what `README.md:132` accuses competitors of doing.
- [ ] **P1-8 · Human Design renders an empty bodygraph for most users.**
  `HumanDesignActivation.compute:32-47` derives gates from 10 natal bodies only — no Earth,
  no Nodes, **no design side** — against a 36-channel table, so most users see zero defined
  centers and read *"All open — receiving and amplifying everyone around you"*
  (`ChartHubView.swift:222`) as a result rather than missing data. The paywall sells
  "the bodygraph, **in full**" while `BodygraphView.swift:14-16` admits Type, Profile, and
  Authority are missing.
- [ ] **P1-9 · Today's transits are cached for the whole calendar day.**
  `ChartCache.swift:85-92,196-209` caches per-day but requests "now". The Moon moves ~13°/day,
  so a reading opened at 07:00 and re-read at 23:00 shows the morning's sky — and
  `DailyReading.closing(applying:)` still promises a contact will "sharpen over the next day
  or two" hours after it separated. → 1–2 h TTL, or exclude Moon aspects from the day entry.
- [ ] **P1-10 · Polar charts report a house system the caller didn't ask for.**
  `houses.ts:53-55` falls back to whole-sign above 66.5° latitude, but
  `astronomyEngineEphemeris.ts:127` still reports `houseSystem: "placidus"`. Verified at
  lat 66.6. A Tromsø user sees a Placidus toggle producing whole-sign cusps, unexplained.
  Related: `tropicalAngles` (`houses.ts:227-239`) has no high-latitude guard and returns a
  degenerate `ascendant: 180` at ±90°.
- [ ] **P1-11 · `/interpret` will 502 on `claude-sonnet-5`.**
  `interpret.ts:101-107` sends no `thinking` field and `config.ts:19` caps `max_tokens` at
  1024. Sonnet 5 runs adaptive thinking by default, and `max_tokens` bounds thinking + text
  together — so `content` often holds only a thinking block, `find(b => b.type === "text")`
  returns undefined, and the route throws `empty completion` → `ai_upstream_error`.
  → Send `thinking: { type: "disabled" }` and raise `ANTHROPIC_MAX_TOKENS` to ~2048.
  *(Also: `config.ts:18` defaults to `claude-sonnet-5` while README/DEV claim `claude-opus-4-6`.)*
- [ ] **P1-12 · The client's LLM timeout is shorter than the call takes.**
  `LuminaAIClient.swift:104` sets `timeoutInterval = 10` (copied from `EphemerisService`,
  where it's right) while the server allows 30 s. "Ask your chart" will time out on normal
  answers. → 45–60 s, or stream.

### Backend hardening

- [ ] **P1-13 · Rate limiting is effectively global.** `server.ts:17` builds Fastify without
  `trustProxy` while deployed behind Fly's proxy, so `request.ip` is the proxy address for
  every request — the entire user base shares one 120/min bucket and one user's burst 429s
  everyone. → `trustProxy: true` + key on `Fly-Client-IP`.
- [ ] **P1-14 · Unauthenticated requests consume the rate-limit budget.**
  `server.ts:38-46` registers the limiter as a root `onRequest` hook, before the
  plugin-scoped `requireSharedSecret`. Verified with `RATE_LIMIT_MAX=5`: five 401s, then a
  429. Combined with P1-13, anyone who knows the hostname can lock out all users.
- [ ] **P1-15 · The shared secret ships inside the IPA.** `project.yml:117` → `Info.plist`,
  read at `LuminaAIClient.swift:110`. `unzip Payload/Lumina.app/Info.plist` yields unlimited
  access to `/interpret` and your Anthropic key. The architecture is right in the important
  respect (the Anthropic key is genuinely *not* in the app), but the spending authority is.
  → Gate `/interpret` on the Supabase JWT the app already has, plus a per-user daily quota.
- [ ] **P1-16 · No cost ceiling on LLM spend.** No daily budget, no per-caller quota, no
  circuit breaker, no caching of identical `(kind, facts, question)`. → Daily token budget
  that fails closed to the deterministic grounded fallback.
- [ ] **P1-17 · No global error handler.** No `setErrorHandler` / `unhandledRejection` /
  `uncaughtException`. Zod failures return `{error, issues}` while Fastify defaults return
  `{statusCode, error, message}`; any unexpected throw leaks a raw JS error to the client.
- [ ] **P1-18 · No graceful shutdown.** No `SIGTERM`/`SIGINT` handling; Fly sends SIGTERM on
  every deploy and autostop, dropping in-flight `/forecast` and `/interpret` requests.
- [ ] **P1-19 · Two high-severity dependency CVEs.** `npm audit --omit=dev`: `fast-uri` (path
  traversal + host confusion) and `find-my-way` (HTTP/2 DDoS), both transitive through
  Fastify 5, both non-breaking. → `npm audit fix` + commit the lockfile.

### Blind spots that let all of the above through

- [ ] **P1-20 · The ephemeris math has no reference-value validation.**
  `backend/test/chart.test.ts:99-110` — the only correctness assertion on any planet is
  `sun.longitude > 60 && < 95`, a **35°-wide window**. No body is compared to a published
  ephemeris; the Moon has no reference assertion at all. `houses.test.ts:73-84` has the only
  reference values (Asc/MC) at ±2.5°/±3° tolerance, wide enough to hide a systematic error;
  the other 10 cusps are checked only for properties the construction guarantees.
  → Add a fixture birth with astro.com longitudes for all 10 bodies at ±0.1°, tighten house
  tolerances to ±0.5°, and add sign-boundary regressions across 1900–2025.
- [ ] **P1-21 · The "screenshot tests" catch no UI regression.**
  `ScreenshotTests.swift:243` and `TabScreenshotTests.swift:48` assert only
  `data.count > 1_000`. Worse, they render **re-composed stand-ins**, not the shipping views
  (`ScreenshotTests.swift:71`: "Reassembles the Today loaded layout") — so a regression
  inside `TodayHubView` is invisible even to a human reviewing the artifact. There is no UI
  test target at all (`project.yml:216-228`).
- [ ] **P1-22 · CI never archives.** `ci.yml:152-171` does only an unsigned simulator
  build+test with `CODE_SIGNING_ALLOWED=NO`, so entitlement/Info.plist/App-Group/extension
  regressions are invisible until someone hand-dispatches `ios-testflight` — exactly how the
  `usernotifications.channel` breakage (commit `2fec068`) reached the release lane.
  → Add a non-uploading `xcodebuild archive -destination generic/platform=iOS`.
- [ ] **P1-23 · CI skips all iOS tests when only the backend changes.** `ci.yml:38-49` — the
  `ios` paths filter excludes `backend/**`, so renaming a JSON field in a route never runs the
  iOS decode tests and a wire-format break merges green.
- [ ] **P1-24 · SPM dependencies are unpinned and `Package.resolved` is never committed.**
  All four packages use `from:`, and `.gitignore:20` excludes `Lumina.xcodeproj/`.
  (`.gitignore:49`'s `*.resolved  # KEEP — …` is a no-op — git doesn't honour inline `#`.)
  Combined with `SWIFT_TREAT_WARNINGS_AS_ERRORS: YES` and `xcode-version: latest-stable`,
  release builds are not reproducible and can hard-fail with zero code change — and
  third-party privacy-manifest/signature compliance can't be relied on.
- [ ] **P1-25 · No crash reporting or analytics of any kind.** No Sentry, no Crashlytics, no
  MetricKit across all 237 Swift files. `LuminaError.analyticsKey:85` computes a stable key
  for a system that was never built. If the app crashes after launch you find out from App
  Store reviews. → MetricKit is ~40 lines and needs no vendor account; do it before submitting.
- [ ] **P1-26 · Entitlements requiring unverified Developer-portal capabilities.**
  `project.yml:124,129,139,145` declare App Groups, push, Sign in with Apple, and Associated
  Domains. Commit `2fec068` already had to strip one entitlement for exactly this reason.
  → Register App Groups (on both app and widget IDs), Push, SIWA, and Associated Domains
  before the next dispatch; verify the exported IPA's `aps-environment` says `production`.
- [ ] **P1-27 · `NSPhotoLibraryAddUsageDescription` is missing** while four surfaces share
  images via `ShareLink` (`ChartShareButton.swift:14`, `DailyReadingShareButton.swift:15`,
  `CompatibilityShareButton.swift:21`, `ShareQRView.swift:84`). "Save Image" exercises the
  add-only Photos path, which throws an uncaught exception without the key — a crash on the
  app's primary viral loop.

### Accessibility & UX blockers

- [ ] **P1-28 · Onboarding is unfinishable under VoiceOver.** *(verified)*
  `LuminaTextField.swift:39` wraps the field in `.accessibilityElement(children: .combine)`,
  collapsing the `TextField` into a static merged element that strips the text-field trait
  and editing focus. This is the **only** text-input component in the app — it backs the
  onboarding name field, birth place, Add Friend, Edit Birth Info, feedback, and Ask-your-chart.
  → Drop `.combine`; put `.accessibilityLabel(title)` on the inner field.
- [ ] **P1-29 · `mutedGold` used as text/glyph colour on parchment in ~15 places (~2:1).**
  Its own token doc forbids exactly this (`LuminaColors.swift:10-13`) and
  `GoldInkContrastTests.swift:17-22` asserts it fails AA. Worst offenders are the hero
  elements: `BigThreeBand.swift:88` (36 pt Sun/Moon/Rising glyph) and `ChartWheelView.swift:91`
  (all 12 zodiac glyphs). → Swap to `goldInk` at every text callsite on parchment.
- [ ] **P1-30 · Hard aspects are invisible in the chart wheel.**
  `ChartWheelView.swift:157` draws squares and oppositions in `blush` on parchment (~1.2:1),
  and `AspectLegend.swift:84`'s matching swatch is a blank capsule. The tensions users most
  want to see don't render. → Use `LuminaColors.error`.
  *(Same bug in error copy: `EditBirthInfoView.swift:281` uses `blush` where
  `ManualBirthPlaceSheet.swift:33` correctly uses `error`.)*
- [ ] **P1-31 · Six of eight onboarding screens have no `ScrollView`.**
  `OnboardingFlowView.swift:35-36` fixes content between a top bar and a 56 pt button. At
  Accessibility XL on an iPhone SE the `.birthTime` step pushes the "I'm not sure" escape
  hatch off-screen — the documented unknown-birth-time path becomes unreachable.
  `docs/NAVIGATION.md` §17 requires no truncation at AX XL.
- [ ] **P1-32 · Place-resolution failure is swallowed with only a haptic.**
  `AddFriendView.swift:172-174` and `EditBirthInfoView.swift:204-206`:
  `catch { Haptics.failure.play() }`. Offline, the user taps a city, feels a buzz, and the
  field just doesn't fill — Save stays disabled with no explanation. (Onboarding does this
  correctly.)
- [ ] **P1-33 · Unmapped errors leak Foundation strings into user copy.**
  `LuminaError+Mapping.swift:44,113` fall through to `.unknown(underlyingMessage:)`, rendered
  verbatim at `LuminaError.swift:68`. `cannotFindHost`, `secureConnectionFailed`, and
  `badServerResponse` are all in the default branch, so *"A server with the specified hostname
  could not be found."* appears as the app's own body copy — violating `docs/NAVIGATION.md` §4.
- [ ] **P1-34 · Deep links arriving over the Settings sheet are consumed and lost.**
  `ChartHubView.swift:37-40` / `PeopleHubView.swift:96-98` clear `pendingPresentation`
  immediately, but their sheets sit *under* the Settings sheet, so nothing presents and
  re-tapping the link does nothing. → Clear only after presentation succeeds.

### Honesty fixes (in-app and published copy)

- [ ] **P1-35 · The in-app privacy dashboard states a falsehood.**
  `PrivacyDashboardView.swift:38,70-72` — *"nothing here leaves it"* / *"your data lives only
  on this device"*. In reality `EphemerisService` POSTs full `BirthData` (exact date, time,
  lat/long, place name) and `LuminaAIClient.interpret:97-116` forwards chart facts to Anthropic.
- [ ] **P1-36 · Published pages promise an export that doesn't exist.**
  `docs/privacy.html:89` and `docs/support.html` both say *"Open Settings → Privacy … to
  export a copy of your stored data"*; the app ships `LuminaBadge(title: "Export soon")`.
  A published policy asserting GDPR Art. 20 portability the product doesn't provide.
- [ ] **P1-37 · `docs/privacy.html:60,70` describes palm processing that doesn't happen**
  (*"analyzed entirely on your iPhone … and a custom on-device model"* — no model exists;
  `Core/PalmCV/Models/` holds only `.gitkeep` and there is no `import CoreML` anywhere).
  `docs/support.html` likewise describes palm in the present tense.
- [ ] **P1-38 · "Notify me when it ships" fakes its confirmation.**
  `PalmHubView.swift:82-83` calls `setTag`, which no-ops without OneSignal
  (`PushNotificationManager.swift:104`), then shows "You're on the list ✓" regardless.
- [ ] **P1-39 · The offline copy promises a cached reading that doesn't exist.**
  `LuminaError.swift:54` — *"Your last reading is saved on this device."* `ChartCache.swift:44-56`
  persists only the natal chart; transits/moon/forecast are in-memory and day-scoped.
- [ ] **P1-40 · Notification copy promises a daily push that was never built.**
  `NotificationSettingsView.swift:137`. Only local transit alerts and the reflect reminder
  exist; OneSignal is initialised but never sends anything.

---

## P2 — Completeness & quality (needed for a credible v1)

> **The checkboxes below are not a to-do list.** They are the audit's original
> findings, kept unticked as the record of what was found — the fixes are in
> the branch history, each commit naming its defect. Spot-checked again on
> 2026-08-06 across both sections: house-system persistence, the birth-date
> lower bound, widget publishing outside the Chart tab, the disabled-button
> haptic, Reduce Motion no longer suppressing all haptics, `ChartCache`
> in-flight de-duplication, transit-alert deep links, `/moon` and
> `/retrogrades` caching, and the auth-before-rate-limit ordering are all in
> place in the code today. Read `LAUNCH-STEPS.md` for what is actually
> outstanding; it is all account work, none of it code.

**Product gaps**
- [ ] No cloud backup/restore. Journal, friends, chart, and Moments live only in
  `UserDefaults` + local SwiftData; uninstall destroys everything, and Sign in with Apple
  changes nothing observable (`AuthManager.swift:114-124`). For a journaling product this is
  the single biggest missing expectation.
- [x] ~~No data export.~~ `LuminaDataExport` + Settings → Privacy → Export my data. Plain JSON through `.fileExporter`, reading the same store set the account eraser clears, so the two can't drift. States its own limits in the file.
- [ ] Content depth: the daily reading is 3 invitations × 10 planet domains × 2 closings
  (`DailyReading.swift:49-53,72-91`) and varies by nothing but which planet is contacted;
  journal prompts are 3 × 10 + 18 static; the "daily quiz" has exactly 4 generators
  (`ChartQuizEngine.swift:42-47`) and repeats forever after day one.
- [ ] Human Design needs a design-side chart (`/design` endpoint) plus Type, Profile, Authority.
- [ ] Onboarding collects `name` and `motivation`, gates progress on both, then discards them
  (`BirthData` has no name field; `OnboardingFlowView.swift:190` clears storage). Use them or
  delete the two steps.
- [ ] Widget stays blank for anyone who never opens Chart — `WidgetPublisher.publish` has one
  call site (`BirthChartViewModel.setReady:162`). Add a `.widgetURL` too (currently none).
- [ ] Decide Palm: restore the tab (it's a well-built, honest coming-soon screen) so the
  metadata and Help articles become true, or strip the module entirely.

**Correctness / robustness**
- [ ] House-system selection never persists (`BirthChartViewModel.swift:26` is view-model
  state only) — resets to Placidus every launch. Settings also shows a contradictory static
  "Placidus" row (`SettingsView.swift:146-152`) while Chart offers three systems.
- [ ] `Int(Double)` on network-supplied values with no finite guard — `ChartWheelView.swift:217`
  is the only one not bounded first. Not reachable today (the backend can't emit NaN/inf), but
  one backend regression from a hard crash. → One `guard longitude.isFinite` at the decode boundary.
- [ ] Birth-date picker has no lower bound (`OnboardingScreens.swift:141-149`);
  `astronomy-engine` throws outside ~1700–2200, surfacing as a generic error.
- [ ] `ChartCache` has no in-flight de-duplication and a lost-update window across its
  `await` (`ChartCache.swift:67-82`) — Today and Chart both fire `/chart` on cold launch.
- [ ] Blank sheet if the chart leaves `.ready` while a detail sheet is up
  (`ChartHubView.swift:45-52`). → Capture the chart into the sheet item.
- [ ] Untrusted QR payload builds a `DateComponents` with no range validation
  (`SharedBirthData.swift:103-107`, `AcceptShareView.swift:88-97`); also decode without a
  size cap. Produces a nonsense chart, not a crash — still worth bounding.
- [ ] Transit-alert notifications carry no deep link (`TransitNotificationScheduler.swift:27-30`),
  unlike the reflect reminder. Tapping "Saturn trines your Sun" opens the last-used tab.
- [ ] `.people(friendID:)` / `.reflect(entryID:)` deep links drop their payload
  (`AppRouter.swift:119-126`).
- [ ] Retrograde flags use a 1-hour probe in `/chart` and `/transits` but a proper ±6 h probe
  in `/retrogrades` — noisy near stations. Use ±6 h everywhere.
- [ ] `returns()` re-derives every ephemeris sample with no memoisation
  (`astronomyEngineEphemeris.ts:243`) — ~5580 samples for Saturn. Memoise and bail after the
  first crossing.
- [ ] No caching on `/moon` or `/retrogrades` despite both being global sky data with no
  birth input.
- [ ] `/health` is liveness-only (`server.ts:48`) — a machine that boots but can't compute
  still passes Fly's check.
- [ ] `Dockerfile:1` uses the floating `node:22-slim` tag and runs Node as PID 1 with no init.

**Test coverage**
- [ ] Zero tests for `LuminaAIClient` (the 503-degradation path, timeout, malformed JSON, and
  the `X-Lumina-Secret` contract are asserted nowhere).
- [ ] 7 of 9 backend endpoints have no client-side transport test (`EphemerisService.swift:236-345`).
- [ ] No tests for subscription gating (because there is no gating — see P0-9).
- [ ] No view-model failure-path tests (offline/timeout → does the retry state actually render?).
- [ ] No iOS test that the unknown-birth-time path degrades correctly — the state a large
  share of real users will be in.
- [ ] `ios-testflight.yml` runs no tests and doesn't depend on a green `ci`.

**Store & compliance**
- [ ] Six reachable "Coming soon"/"Soon" placeholder surfaces (`SettingsView.swift:191-195`,
  `NotificationSettingsView.swift:71-80`, `PrivacyDashboardView.swift:75`,
  `ChartHubView.swift:203`, `HelpView.swift:59,71`) — Guideline 2.1 names placeholder content
  explicitly. Prefer removing rows over labelling them.
- [ ] Free-text LLM path has no moderation, no report affordance, and no AI-generated
  disclosure (`ChartQAViewModel.swift:35-47`); the ASC age-rating questionnaire now asks
  about in-app AI chat. Prompt-injection surface is unmitigated (`interpret.ts:17-18` splices
  6000 chars verbatim) — wrap `facts` in a delimiter block.
- [ ] Entertainment disclaimer appears only in an About footnote (`SettingsView.swift:205-207`);
  put it on the daily reading and onboarding. *(The server prompt at `interpret.ts:55`
  correctly forbids deterministic/medical/legal/financial claims — content itself is clean.)*
- [ ] Remove the unused Lottie dependency (`project.yml:54-56,166`; zero `import Lottie`) —
  it's on Apple's signature-required SDK list, for no functionality.
- [ ] Remove the unused ElevenLabs key from the shipped Info.plist (`project.yml:101-102`;
  no Swift file reads it) — an extractable private key for a feature that doesn't exist.
- [ ] `Localizable.xcstrings` is a 73-byte empty catalog with zero `String(localized:)` call
  sites, and heavy `"…" + "…"` concatenation won't extract. ROADMAP promises EN+ES.
- [ ] Prepare the App Store privacy nutrition-label answers (nothing exists) and reconcile
  them with `PrivacyInfo.xcprivacy`.
- [ ] No open-source acknowledgements screen (RevenueCat, Supabase, OneSignal, Lottie).
- [ ] Screenshots exist for 6.9" only; verify at upload whether the 6.5" set is still required.

---

## P3 — Polish

- [ ] `LuminaButton.swift:47-54` fires a haptic on taps to *disabled* buttons (the gesture is
  layered outside the disabled subtree).
- [ ] `Haptics.swift:24` suppresses all haptics on Reduce **Motion** — a vestibular setting,
  not a haptic one — and ignores the in-app `reduceMotionOverride`.
- [ ] `LuminaStarfield` runs two stacked `TimelineView(.animation)` Canvases plus a 60 Hz
  `MotionManager` continuously behind the launch tab, recomputing 3 hashes per star per frame.
  Hoist the star array out of the draw loop and pause when off-screen.
- [ ] Journal calendar cells have no accessibility labels and no empty state
  (`JournalCalendarView.swift:135-157`); `ForEach` keyed on index rather than date.
- [ ] Notification toggles fire a 10 s network call with no in-flight indicator
  (`NotificationSettingsView.swift:141-192`).
- [ ] `SignInView` is a sheet-over-sheet with no close affordance (violates
  `docs/NAVIGATION.md` §3/§15).
- [ ] "Add birth info" CTAs land on the Settings root instead of the form
  (`TodayHubView.swift:134,390`, `ChartHubView.swift:105,250`).
- [ ] "Share my chart" shows "App is mid-setup" when the real problem is missing birth info
  (`ShareQRView.swift:131-133`).
- [ ] Token drift: widget re-declares brand colours as raw RGB
  (`LuminaWidget/CosmicWidget.swift:62-64` — will diverge from `LuminaColors`); 27 inline
  copies of the section-kicker style while `LuminaSectionLabel` sits unused (and all 27 are
  one opacity notch too light); `WhyWeAsk.swift:33` uses `.font(.caption)`; a few off-grid
  `spacing: 2`.
- [ ] Three components have zero call sites: `LuminaSectionLabel`, `LuminaDismissButton`,
  `GlossaryLink`. The glossary system `docs/NAVIGATION.md` §10 mandates doesn't exist in the
  app while bare jargon ships in body copy.
- [ ] Brand typography never shipped — `Resources/Fonts/` holds only `.gitkeep`;
  `LuminaTypography.swift:13-18` falls back to system fonts for every token, and
  `LuminaCard.swift:51-56` still uses `.thinMaterial` instead of the iOS 26 Liquid Glass API.
- [ ] `swiftformat` is `continue-on-error` and `.swiftlint.yml:6-8` doesn't include
  `LuminaWidget/` at all.
- [ ] Dead/incorrect config: `.gitignore:88`'s Core ML negation targets a nonexistent path;
  generated entitlements/plists are untracked but not ignored; the `resources:` block at
  `project.yml:64-72` is not valid XcodeGen and is silently ignored; the pre-build
  `inject_env.sh` phase can't affect the build it runs in (and forces
  `ENABLE_USER_SCRIPT_SANDBOXING: NO` project-wide for nothing).
- [ ] `DateComponents` DST-hole fallback silently rewrites the reminder time
  (`NotificationSettingsView.swift:247-256`).
- [ ] `ChartCache.encodeKey` returns `""` on failure — a colliding sentinel; `return nil` is safer.

---

## Documentation — false claims to correct

`README.md` and `DEV.md` are the two documents a new reader opens first, and roughly half of
their factual claims are wrong. The code comments, `LEARNINGS.md`, `TASK.md`'s backlog, and
`docs/APP-STORE-LISTING.md` are consistently honest by contrast.

- [ ] "Swiss Ephemeris Pro" (README:17, DEV.md:60,67, ROADMAP:15 "Real Swiss Eph math") —
  it's `astronomy-engine` (MIT). **Positions are accurate**; the branded claim is not.
- [ ] "RAG-grounded" / "pgvector RAG over a curated corpus" (README:18,22, DEV.md:68) —
  no embeddings, no vector store, no corpus. `interpret.ts:5-8` admits it.
- [ ] "ElevenLabs TTS" and "Supabase (auth, profiles, RAG vector store)" listed in the shipped
  Stack table — neither is implemented.
- [ ] "Real computer vision palm analysis" / "Core ML (custom U-Net)" (README:5,16) — no
  `import CoreML` anywhere; contradicts README:40, which correctly says palm is unshipped.
- [ ] `DEV.md:88-100` lists ~8 files that don't exist (`PalmCaptureSession.swift`,
  `LineSegmenter.swift`, `lumina_palm_v1.mlpackage`, `RAGRetriever.swift`,
  `ContentGenerator.swift`, …).
- [ ] README's "Project Structure" names four directories that don't exist and gets five
  feature-directory names wrong.
- [ ] All four "Documentation" links in README:108-113 are dead (`CLAUDE.md`,
  `docs/ARCHITECTURE.md`, `docs/PRODUCT_SPEC.md`, `docs/API_KEYS.md` — the last is cited as
  authoritative by `DEV.md:181` and `.env.example:8`).
- [ ] README:123-126 advertises four one-off IAPs that don't exist (`Entitlements.swift`
  defines exactly one case) and a free tier with "1 palm scan/month".
- [ ] README:83 tells you to clone `https://github.com/YOUR_USERNAME/lumina-ios.git`.
- [ ] README presents a shipped v1 while ROADMAP/DEV describe phase 1 of 16 with an App Store
  target at week 34. `TASK.md` is stale (latest entry 2026-07-02; HEAD is 2026-07-03 with
  seven unrecorded commits) and internally contradictory (`PrivacyDashboardView` is `[x]` at
  :290 and `[ ]` at :294). `DEV.md:13-14` names a branch two branches out of date.
- [ ] `backend/README.md:95-98` understates — it says transits/progressions/synastry/composite
  aren't there; all of them are.
- [ ] `backend/README.md:26` says `cp .env.example .env`, but the rename deleted the template.
- [ ] Delete `lumina-roadmap.html` (1,175 lines, the superseded 12-phase plan, linked from
  nothing).
- [ ] **Fix the stale frame comment at `astronomyEngineEphemeris.ts:100-107`** — see
  *Corrections* below. The comment is wrong and the code is right; someone "fixing" the code
  to match the comment would introduce a real bug.

---

## Owner action items (outside the repo)

> **Follow `LAUNCH-STEPS.md` instead of this table.** It's the same list, in
> dependency order, with the exact commands, field names and values — written to be
> worked through top to bottom. This table stays as the audit's summary.

| # | Item | Current state |
|---|---|---|
| 1 | **Revoke the leaked Anthropic key** | 🔴 Urgent — live on `main` |
| 2 | Deploy the backend to Fly.io | 🔴 Never deployed (and won't boot until P0-3) |
| 3 | `lumina.app` domain + AASA hosting | 🔴 Domain doesn't resolve |
| 4 | Confirm GitHub Pages is live (privacy/terms/support) | 🟡 Pages exist; toggle unverified |
| 5 | RevenueCat: products, offerings, entitlement, discounted annual | 🟡 SDK wired, dashboard unconfirmed |
| 6 | App ID capabilities: App Groups, Push, SIWA, Associated Domains | 🟡 Entitlements declared, registration unverified |
| 7 | ASC: IAP products, screenshots, description, keywords, age rating, export compliance | 🟡 Copy drafted in `docs/APP-STORE-LISTING.md` |
| 8 | Privacy nutrition-label answers | 🔴 Nothing prepared |
| 9 | OneSignal + Supabase project credentials | 🟡 Wired, inert |
| 10 | Legal review of fortune-telling framing | 🔴 Unowned |
| 11 | Real support mailbox | 🔴 All addresses on a nonexistent domain |
| 12 | Fly + Anthropic spend alarms | 🔴 None |

**Resolved since the docs were last updated:** Apple Developer signing. TestFlight run
`28671527126` (2026-07-03) archived, signed, exported, and **uploaded successfully** —
`TASK.md:58-59` still lists this as blocked. Font and Swiss Ephemeris licences are cleanly
worked around with zero legal exposure; don't buy either before launch.

---

## Corrections — findings raised by the audits and ruled out

Recording these so they don't get "fixed" into real bugs later.

1. **No J2000 / of-date reference-frame mismatch.** One audit reported that planet longitudes
   are J2000 while the Ascendant is of-date, causing wrong Sun signs for cusp births. I tested
   it: `Ecliptic(GeoVector(body, t, true))` returns the Sun at **exactly 0.0000°** at the March
   equinox for 1800, 1900, 1950, 1970, 1990, 2026, and 2050. The library returns true ecliptic
   **of date**; planets and angles share one frame. The *code comment* claiming J2000 with
   "< 0.5° drift" is what's wrong — delete it.
2. **`SettingsView` does receive the router.** A finding claimed account deletion crashes
   because `@Environment(AppRouter.self)` is read outside the injection scope.
   `MainTabsView.swift:22-24` applies `.environment(router)` *before* `.sheet`, so the sheet
   content inherits it correctly. (The *ordering* bug in P1-2 is real and separate.)
3. **The `Int(Double)` trap sites are not currently reachable** — `houses.ts` guards
   circumpolar geometry with a `Number.isFinite` check and routes |lat| ≥ 66.5° to whole-sign,
   so the backend cannot emit NaN/inf today. Kept in P2 as defence in depth, not as a live crash.

---

## What's genuinely good (don't regress it)

- Zero force-unwraps, force-casts, force-tries, or `fatalError` in the app — SwiftLint enforces
  all three as errors.
- `#if DEBUG` discipline: every sample-data fallback fails honestly in release
  (the one exception, `OnboardingScreens+Reveal.swift`, is P1-5).
- `BirthMoment.combine`/`pickerValues` round-trip correctly and anchor the birth day at noon in
  the birth zone — the DST/day-shift handling is genuinely well done, and paired correctly with
  the backend's `noonLocalAsUTC` convention.
- `ChartFacts.summary` sends only signs and aspect types to the LLM — never birth date, time,
  or coordinates.
- The deep-link parser correctly rejects `evil.lumina.app` and `xlumina.app`.
- Backend input validation is thorough: every route zod-parses with sane bounds and sets a
  `bodyLimit`; the process survived null/string/array/prototype-polluted/oversized/malformed
  bodies, bogus IANA zones, and injection strings. `secret.ts` uses `timingSafeEqual`.
  `config.ts` fails fast on a missing secret.
- The Placidus solver, ascendant/MC quadrant handling, negative-modulo normalisation, and
  midpoint arithmetic all check out; cusps stayed monotonic at every latitude tested.
- No ATS exceptions, no custom `URLSessionDelegate`, no TLS tampering anywhere; `force_https`
  on Fly. SIWA uses a fresh per-attempt SHA256 nonce. Keychain uses
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- Test suite is not padded: 351 iOS tests with 469 `XCTAssertEqual` against 11 `XCTAssertNotNil`
  and zero `XCTAssertNoThrow`. `BirthMomentTests`, `DeepLinkRoutingTests`, `HumanDesignTests`,
  and the backend's `security.test.ts`/`timezone.test.ts` are the work of someone who
  understands the failure modes.
- Loading and empty states are near-universal, and `LuminaSkeleton` correctly mirrors layout.
