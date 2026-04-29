# LEARNINGS.md — Lumina Accumulated Knowledge

> Append at the end of every session. Never delete entries — mark outdated ones `[STALE]`.
> Format: date, category tag, and a clear action/lesson.

---

## 🛠️ Claude Code Setup

**[2026-04] .claude/settings.json permissions**
Pre-approved bash patterns in `.claude/settings.json` `permissions.allow` array dramatically reduce permission prompts during development. Use glob patterns: `"Bash(xcodebuild -scheme Lumina*)"` not broad `"Bash(*)"`. Secrets guard hook fires on `git commit` to catch accidentally staged `.env`/`.xcconfig` files.

**[2026-04] Custom slash commands**
`.claude/commands/*.md` files become `/command-name` slash commands in Claude Code. Each file's content is the prompt — include the bash commands inline so Claude executes them. Best for: repeated workflows (build, lint, test), scaffolding templates, session-end checklists.

**[2026-04] Stop hook for session end**
The `Stop` hook in `settings.json` echoes an end-of-session checklist to the terminal on every Claude stop event. Useful reinforcement since CLAUDE.md session protocol is easy to skip. Hook runs shell commands — not AI instructions.

---

## 🏗️ Architecture

**[2026-04] Swift 6 strict concurrency with `@Observable`**
All `@Observable` view models must be `@MainActor`. Using `@MainActor` at class level is cleaner than annotating every property. Pattern:
```swift
@MainActor
@Observable
final class BirthChartViewModel {
    var planets: [Planet] = []
    var isLoading = false
    // ...
}
```

**[2026-04] Actor isolation for service layer**
`EphemerisService`, `LuminaAIClient`, and `IAPManager` are actors. Calling them from `@MainActor` view models requires `await`. Don't try to call them synchronously — the compiler will error. Pattern:
```swift
Task {
    isLoading = true
    defer { isLoading = false }
    planets = await ephemerisService.chart(for: birthData)
}
```

**[2026-04] SwiftData vs Core Data**
SwiftData is the right choice for this project. `@Model` macro works seamlessly with `@Observable`. Don't mix SwiftData with Core Data. Use `ModelContainer` in `LuminaApp.swift` and inject via `.modelContainer()` modifier.

---

## 🔐 Security / Credentials

**[2026-04] Config.xcconfig secret injection pattern**
Never put API keys in `Info.plist` directly (visible in binary). Pattern:
1. `secrets/Config.xcconfig` (gitignored) holds `ANTHROPIC_API_KEY = sk-ant-...`
2. `Info.plist` reads `$(ANTHROPIC_API_KEY)`
3. `scripts/inject_env.sh` copies `.env.local` → `secrets/Config.xcconfig` pre-build
4. CI injects via `xcodebuild ... ANTHROPIC_API_KEY=${{ secrets.ANTHROPIC_API_KEY }}`

**[2026-04] Never commit `.env.local` or `secrets/`**
Both are in `.gitignore`. Run `git status` before every commit. If a key is accidentally committed, rotate it immediately — the git history is searchable.

---

## 💳 IAP / RevenueCat

**[2026-04] Apple Guideline 3.1.2(c) — Paywall rules (April 2026 active enforcement)**
Apple removed Cal AI from the App Store for displaying "$0.43/day" while billing weekly. Rules in force now:
- Cannot present a per-day price if billing is weekly
- Cannot display a second paywall in the same session after the user declines the first
- Cannot route users to a web billing funnel as an alternative to IAP
- **No weekly subscription tier** — monthly + annual only in Lumina

**[2026-04] RevenueCat initialization**
Init in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`, NOT in `LuminaApp.init()`. SwiftUI previews call `init()` in the simulator and will crash if RevenueCat isn't configured yet.

**[2026-04] Entitlement checking pattern**
Don't call `Purchases.shared.getCustomerInfo()` on every view appear — it's a network call. Cache in `IAPManager` actor and observe `Purchases.shared.delegate`:
```swift
actor IAPManager: PurchasesDelegate {
    private(set) var isPremium = false
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        isPremium = customerInfo.entitlements["premium"]?.isActive == true
    }
}
```

---

## 🔮 Ephemeris / Chart Math

**[2026-04] Swiss Ephemeris Pro license**
The AGPL license forces open-sourcing if you call the lib over a network. Buy the Pro license (CHF 1,550 one-time unlimited). Self-host a small Node.js service using `sweph` npm package (`timotejroiko/sweph`). Never use a third-party astrology API that could rate-limit or change pricing.

**[2026-04] Default house system: Placidus**
Co-Star defaults to Porphyry — this is repeatedly cited in 1-star reviews from astrologers. Lumina defaults to Placidus (professional standard) with Whole Sign and Sidereal as options. The Swiss Eph service must respect the `houseSystem` parameter from the client.

**[2026-04] Birth time unknown — graceful handling**
When user selects "I don't know my birth time", use noon (12:00) and hide house cusps + Ascendant/MC/IC/DC from the chart wheel (they're meaningless without accurate time). Show a gentle informational badge: "House positions require an accurate birth time." Do NOT block the user or shame them — Co-Star does this and it's a common complaint.

**[2026-04] Never ask Claude to calculate chart math**
Claude will confidently hallucinate planetary positions. All chart data MUST come from the Swiss Eph service as structured JSON. Claude only handles interpretation of the data it's given.

---

## 🤚 Palm CV

**[2026-04] VNDetectHumanHandPoseRequest on iOS 17+**
The Vision framework's hand pose detection gives 21 landmarks (wrist + 4 fingers × 4 joints + thumb × 4). For palm line segmentation we need a separate Core ML model (U-Net) — Vision only gives landmark points, not continuous lines.

**[2026-04] Privacy: photo never leaves the device**
Only the feature vector (line lengths, curvature metrics, branch counts — ~50 floats) is sent to the server. The palm photo stays on-device and is cleared from memory after extraction. This is a privacy policy commitment and a marketing differentiator. Reinforce it in the "How this works" modal.

**[2026-04] Lighting guidance is critical**
The Vision hand pose detector fails frequently in low light or when the palm fills less than 40% of the frame. Add real-time lighting assessment via AVCaptureSession luminance metadata and show a "brighter lighting needed" overlay. Without this the UX is frustrating.

---

## 🤖 Claude / AI

**[2026-04] Model: claude-opus-4-6**
This is the model to use for content generation. Parameters: `max_tokens: 800` for daily readings, `max_tokens: 1200` for compatibility reports, `max_tokens: 400` for palm line narrations. Temperature `0.7` for readings, `0.4` for palm (needs consistency).

**[2026-04] RAG corpus setup**
Embed chunks from: Liz Greene's *Relating*, Steven Forrest's *The Inner Sky*, Robert Hand's *Planets in Transit*, Sue Tompkins' *Aspects in Astrology*. Chunk size: ~500 tokens with 50-token overlap. Embed with `text-embedding-3-small`. Store in Supabase `pgvector`. Retrieve top-3 chunks keyed by the user's active transits. Inject as `<context>` block in the system prompt before the structured chart JSON.

**[2026-04] Prompt versioning**
Store all system prompts as `.txt` files in `Core/AI/Prompts/`. Version them in git. Never hardcode prompt text in Swift. Load via `Bundle.main.url(forResource:withExtension:)`. This lets prompts be improved without Xcode rebuilds during development.

**[2026-04] Cost estimation**
Daily reading: ~800 input tokens + ~400 output tokens = ~$0.0064/user/day on claude-opus-4-6. At 10,000 MAU with 70% daily active: $44.80/day = ~$1,344/month. At $9.99/month × 10K subscribers = $99,900/month revenue. AI cost is <1.4% of revenue. Comfortable.

---

## 🎨 Design / SwiftUI

**[2026-04] iOS 26 Liquid Glass**
Use `.glassBackgroundEffect()` modifier (iOS 26+) for modal sheets, overlays, and cards on the chart wheel. Don't fake it with `.ultraThinMaterial` — it looks dated on iOS 26 devices.

**[2026-04] Custom font registration**
Add font files to the Xcode project target, list them in `Info.plist` under `UIAppFonts` key, then reference them via `Font.custom("PPEditorialNew-Regular", size: 28)`. Always wrap in `LuminaTypography` extension — don't scatter font names across views.

**[2026-04] Chart wheel drawing**
Use `Canvas` + `GraphicsContext` for the chart wheel — SwiftUI shapes at this complexity (12 houses, 10 planets, aspect lines) are expensive with individual views. Canvas renders in a single pass. Animate with `TimelineView` for the reveal animation.

**[2026-04] Gyroscope parallax**
`CoreMotion` `CMMotionManager` for the background star field parallax. Create in a `MotionManager` `@Observable` class, publish `roll` and `pitch`, apply as `.offset()` to the background layer with a multiplier of ~8pt. Must call `motionManager.stopDeviceMotionUpdates()` in `onDisappear` — otherwise it drains battery.

---

## 🔔 Notifications

**[2026-04] OneSignal initialization**
Add OneSignal app ID in `AppDelegate`, not in a feature module. Call `OneSignal.initialize()` before requesting notification permission. Defer the permission prompt to AFTER the paywall — this keeps notification opt-in rate ~70% vs ~40% if asked on first launch.

**[2026-04] Push notification opt-in timing**
The prompt should appear on the "Your daily reading is ready" screen after the user has seen one full reading. Contextual prompts ("Get tomorrow's reading delivered to you — allow notifications?") convert better than cold permission prompts.

---

## 🚀 Distribution

**[2026-04] Xcode Cloud**
Set up Xcode Cloud for CI/CD rather than pure GitHub Actions for iOS builds — it handles signing, provisioning, and TestFlight upload natively. Use GitHub Actions only for linting and type-checking (fast, cheap, parallel). Xcode Cloud for full archive + distribute (slower, Apple-managed).

**[2026-04] App Store metadata**
Category: **Health & Fitness** (not Entertainment) — better algorithmic visibility and lower competition than the Lifestyle category. Secondary category: Entertainment. Keywords to target: "birth chart", "astrology app", "palm reading", "daily horoscope", "human design", "birth chart compatibility". Co-Star's ASO leaves "human design" and "palm reading" as under-competed terms.

---

## 🧱 Bootstrap

**[2026-04-29] XcodeGen for project generation**
The repo defines its `.xcodeproj` via `project.yml` (XcodeGen) instead of committing the project file. Rationale: text-defined, reviewable in PR, no merge conflicts on `pbxproj`, reproducible from CI. User runs `brew install xcodegen && xcodegen generate` once on macOS; CI runs the same command. `Lumina.xcodeproj` is **not committed** — convention only; `.gitignore` does not yet have an explicit `Lumina.xcodeproj/` line, so be careful not to `git add` it.

**[2026-04-29] Secrets via project.xcconfig + secrets/Config.xcconfig**
`.gitignore` whitelists exactly one xcconfig (`!project.xcconfig`) and ignores everything else under `secrets/` plus all other `*.xcconfig`. Pattern:
- `project.xcconfig` (committed) — does only `#include? "secrets/Config.xcconfig"`.
- `secrets/Config.xcconfig` (gitignored) — generated by `scripts/inject_env.sh` from `.env.local` (or env vars in CI). Lists `KEY = value` for each secret.
- `project.yml` references `project.xcconfig` as the base config for both Debug and Release.
- `Info.plist` reads each via `$(KEY)` substitution, and Swift reads the resolved values via `Bundle.main.infoDictionary["LuminaAnthropicAPIKey"]` etc.
The pre-build script in `project.yml` re-runs `inject_env.sh` on every Xcode build, so updating `.env.local` doesn't require a regenerate.

**[2026-04-29] SwiftLint custom-rule exclusions**
`no_hex_color_literals`, `no_hardcoded_font_names`, and `no_magic_spacing_numbers` originally fired on the very files they exist to enforce (the design-token sources). Added `excluded:` regexes for `Design/Tokens/Lumina{Colors,Typography,Spacing}.swift` so the rules apply everywhere except their definitions. Don't drop hex literals into any other file — there's no other escape hatch.

**[2026-04-29] LuminaSpacing token names**
Initially used `s/m/l` but `identifier_name` errors on single-character names (excluded list is `id, x, y, z, i, j` only). Renamed to `xs/sm/md/lg/xl/xxl`.

**[2026-04-29] Active branch is `claude/initial-app-setup-hQvKZ`**
CLAUDE.md previously listed `claude/optimize-config-setup-xfpK1` (now merged into main). All bootstrap work lives on `claude/initial-app-setup-hQvKZ`.

**[2026-04-29] CI runs on macos-15 with latest-stable Xcode**
GitHub Actions workflow at `.github/workflows/ci.yml` runs xcodegen → swiftlint → swiftformat (non-blocking) → xcodebuild build → xcodebuild test against the `iPhone 16 Pro` simulator. Uses `maxim-lobanov/setup-xcode@v1` with `xcode-version: latest-stable` so the workflow doesn't break when Xcode point releases ship; and `xcbeautify --renderer github-actions` for native log folding. Originally pinned Xcode 17 path on macos-14 — fragile against runner image churn.

**[2026-04-29] No-Mac dev — CI is the only build/test loop**
Developer has no local macOS, so every Swift change rides CI to be verified. Implications:
- Don't put aggressive build-fail flags (warnings-as-errors, upcoming features) on the project base — scope them to the `Lumina` target so SPM dependency builds aren't tripped by their own emitted warnings.
- The `/build`, `/test`, `/lint`, `/chart` slash commands document what CI runs; they aren't usable locally.
- `swiftformat --lint` is `continue-on-error: true` until a baseline format pass is committed; currently I have no way to run swiftformat locally so it would otherwise gate every PR.
- Distribution to a real device requires GitHub Actions → fastlane → TestFlight (no Xcode Cloud — its setup wizard practically requires a Mac). Tracked as a milestone in TASK.md once an Apple Developer account + signing artifacts exist.

---

## 🔮 Ephemeris backend

**[2026-04-29] astronomy-engine, not swisseph, for v0**
The backend uses `astronomy-engine` (pure JS, MIT) instead of `swisseph` (C++ Node binding). Reasons: zero native build tools required (Linux dev box has no `python3`/`make`/`g++`); Swiss Ephemeris Pro `.se1` files are licensed (CHF 1,550, blocked in TASK.md). Drift between `astronomy-engine`'s J2000 ecliptic and tropical-of-date is < 0.5° for births in the last 30 years — within astrological tolerance. The `EphemerisService` interface is the only seam callers depend on; swap is a one-line change once licensed.

**[2026-04-29] astronomy-engine API quirk: EclipticLongitude is heliocentric**
`EclipticLongitude(Body.Sun, time)` throws "Cannot calculate heliocentric longitude of the Sun" because the function returns heliocentric, not geocentric, longitude. For the geocentric ecliptic position used by astrology, the right call is `Ecliptic(GeoVector(body, time, true)).elon` for ALL bodies including Sun and Moon. The retrograde flag is computed by sampling longitude one hour earlier and signing the delta.

**[2026-04-29] iOS ↔ backend JSON contract has two quirks**
- The backend writes `calculatedAt` via `new Date().toISOString()` which always includes fractional seconds (`...12.600Z`). Swift's default `JSONDecoder.DateDecodingStrategy.iso8601` rejects fractional seconds. Fix: a custom strategy that tries `[.withInternetDateTime, .withFractionalSeconds]` first, then plain `withInternetDateTime`. Lives in `EphemerisService.swift` as `chartDecoder`.
- The zod schema declares `birthTime` as `.nullable()`, which requires the key to be present. Swift's default `Encodable` for `Date?` *omits* the key when nil. The fix is twofold: the iOS `BirthData` overrides `encode(to:)` to always emit `birthTime` (as JSON `null` when nil), AND the zod schema adds `.optional()` so omitted-key payloads from the CLI / future clients still validate.

**[2026-04-29] Drop tsx, use Node 22 `--experimental-strip-types`**
Originally used `tsx` for dev/CLI. tsx loads astronomy-engine's CJS entry, where named imports (`import { Body }`) silently fail because the CJS module's static analysis can't detect named exports. Vitest happens to load the ESM entry so its test pass — divergent runtime behavior between tools. Fix: drop `tsx`, run `.ts` files directly with `node --experimental-strip-types` (Node 22.6+). Required:
- `tsconfig.json`: `"allowImportingTsExtensions": true`, `"noEmit": true`, `"rewriteRelativeImportExtensions": true`
- All relative imports use `.ts` extension explicitly (not `.js`)
- npm scripts use `node --watch --env-file-if-exists=.env --experimental-strip-types src/server.ts`
This eliminates one dev dep, removes a class of CJS/ESM resolution bugs, and matches where Node TS support is heading (Node 23+ enables strip-types by default).
