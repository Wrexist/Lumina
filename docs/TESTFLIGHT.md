# TestFlight & App Store — Setup Guide

How to ship Lumina to TestFlight (and then the App Store) from CI, with **no
Mac required**. The build runs on GitHub Actions (`macos-15`) via the
`ios-testflight` workflow. This is the *signed device* path — separate from
`ci.yml`, which only does an unsigned **simulator** build for verification and
whose artifact **cannot** be uploaded to TestFlight.

---

## TL;DR

1. Do the one-time Apple-side setup (below).
2. Add the GitHub secrets (below).
3. Actions tab → **ios-testflight** → **Run workflow**.
4. Wait ~15 min → build appears in App Store Connect → TestFlight.

---

## 1. One-time Apple-side setup (you must do this — CI can't provision Apple accounts)

1. **Apple Developer Program** — membership active ($99/yr). Required for any
   TestFlight distribution.
2. **App record in App Store Connect** — My Apps → **+** → New App:
   - Platform: iOS
   - Name: `Lumina` (see `docs/APP-STORE-LISTING.md` — must be globally unique;
     have a fallback ready, e.g. `Lumina: Astrology`)
   - Primary language: English (U.S.)
   - Bundle ID: `app.lumina.ios` (register it in the Developer portal first if
     it isn't in the dropdown)
   - SKU: `lumina-ios-001` (any unique string)
3. **App IDs + capabilities** (Developer portal → Identifiers) — for signed
   builds the widget's App Group must exist:
   - `app.lumina.ios` — enable **App Groups**
   - `app.lumina.ios.widget` — enable **App Groups**
   - App Group: register `group.app.lumina.ios` and assign it to both App IDs.
   - (`-allowProvisioningUpdates` will generate the distribution profiles
     automatically; it can usually enable the capabilities too, but registering
     the App Group up front avoids the one failure mode automatic signing can't
     always resolve.)
4. **App Store Connect API key** — Users and Access → Integrations →
   **App Store Connect API** → generate a key with the **App Manager** role
   (Admin also works). This gives you:
   - **Key ID** (e.g. `ABC123XYZ9`)
   - **Issuer ID** (a UUID, shown at the top of the page)
   - the **`.p8` private key file** — downloadable **once**. Save it somewhere
     safe; you can't re-download it.

Confirm the **Team ID** at Developer portal → Membership. It's hard-coded as
`S3U8B8HH96` in the workflow + `ios/ExportOptions.plist`; if yours differs,
update both.

---

## 2. GitHub secrets

Repo → **Settings → Secrets and variables → Actions → New repository secret**.

### Signing / upload (the only 3 TestFlight strictly needs)

| Secret | Value |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | the Key ID from step 4 |
| `APP_STORE_CONNECT_ISSUER_ID` | the Issuer ID from step 4 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | the `.p8`, base64-encoded (see below) |

Encode the `.p8` (any of these works — the workflow normalises the input):

```bash
# macOS
base64 -i AuthKey_ABC123XYZ9.p8 | pbcopy
# Linux
base64 -w0 AuthKey_ABC123XYZ9.p8
```

Paste the result as `APP_STORE_CONNECT_API_KEY_BASE64`.

### App-runtime keys (so the shipped binary has working services)

Same set `ci.yml` already uses (add them here too — Actions secrets aren't
shared between workflows unless defined at the repo level, which these are):

`ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_ID`, `REVENUECAT_API_KEY_IOS`,
`ONESIGNAL_APP_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SWISS_EPH_SERVICE_URL`, `SWISS_EPH_API_SECRET`.

> `ANTHROPIC_API_KEY` is deliberately **not** here — per the architecture, LLM
> calls are server-side and the key never ships in the IPA.

---

## 3. Run it

Actions → **ios-testflight** → **Run workflow** (branch `main`). Optionally set
`build_number` (must be higher than the last upload); otherwise it defaults to
the run number. The workflow:

1. `inject_env.sh` → `xcodegen generate`
2. installs the ASC API key
3. `xcodebuild archive` (device, automatic cloud signing)
4. `xcodebuild -exportArchive` → exports the `.ipa` (also saved as a run
   artifact) **and** uploads it to App Store Connect in the same call, via
   `destination: upload` in `ExportOptions.plist`

Processing on Apple's side takes 5–15 min, after which the build shows under
**TestFlight**. Add it to a tester group (internal testers need no review;
external groups need a short Beta App Review).

> **Not appearing at all, with no confirmation email?** Don't trust a green
> CI run alone — check **App Store Connect → (your app) → TestFlight** tab
> directly. If it's genuinely empty (not even a "Processing" placeholder),
> the most common cause is the App Store Connect API key's **role**: it must
> be **App Manager or Admin** under **Users and Access → Integrations → App
> Store Connect API**. A lower-privilege key (e.g. plain "Developer") can
> still authenticate cloud signing/provisioning — which is why the archive
> step succeeds — but Apple's backend can silently drop the actual TestFlight
> delivery without ever surfacing an error to CI and without emailing anyone.
> We previously uploaded via a separate `xcrun altool --upload-app` call
> after export, which has a known history of reporting local "UPLOAD
> SUCCEEDED" while the delivery never lands in App Store Connect; the
> `destination: upload` approach above is Apple's more reliable, currently
> recommended path.

---

## Versioning

- **Marketing version** (`0.1.0`) and **build number** (`1`) live once in
  `project.yml` (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`) and feed both
  the app and the widget, so their versions can never drift (a mismatch is an
  ASC rejection).
- Each upload needs a **unique, increasing build number** for a given marketing
  version. The workflow handles this via the run number / the `build_number`
  input. Bump `MARKETING_VERSION` in `project.yml` for a new user-facing
  version (e.g. `0.2.0`).

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No profiles for 'app.lumina.ios.widget' were found` | Register the App Group on both App IDs (step 3); re-run. |
| `Bundle version must be higher than the previously uploaded version` | Set a higher `build_number` input, or just re-run (run number increments). |
| `Authentication credentials are missing or invalid` | Re-check the 3 ASC secrets; re-encode the `.p8`. |
| `Invalid entitlements` / App Groups | Ensure `group.app.lumina.ios` is registered and assigned to both App IDs. |
| `Entitlement <key> not found and could not be included in profile` | The archive step validates every key in `Lumina.entitlements` against the real provisioning profile — unlike CI's unsigned simulator build, which skips this check entirely. Remove the offending key from `project.yml`'s `entitlements.properties` (it's not a real/registered entitlement) or register the matching capability on the `app.lumina.ios` App ID first. See `docs/CAPABILITIES-PLAN.md` for the `com.apple.developer.usernotifications.channel` precedent. |
| Upload rejects encryption compliance | Already handled — `ITSAppUsesNonExemptEncryption` is `false` in the Info.plist. |
