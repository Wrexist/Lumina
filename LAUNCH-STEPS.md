# Lumina — What's left, step by step

Everything that could be fixed in code **is fixed**. What follows is the work that
can only happen outside this repository: accounts, dashboards, DNS, and App Store
Connect. It's written to be followed top to bottom in one sitting per section.

Nothing here needs a Mac except **Step 8** (screenshots) — and even that can be done
from a TestFlight build on a real iPhone.

Time estimate for the whole list: **one long day, plus 1–3 days of waiting on Apple
review.** The blocking path is Steps 1 → 2 → 5 → 7 → 9.

---

## Step 1 — Revoke the leaked Anthropic key ⚠️ do this first

An Anthropic API key was committed to this repository and is still in the git
history. Anyone who has ever cloned the repo has it. Rotating it costs five
minutes; not rotating it is an open credit line.

1. Go to <https://console.anthropic.com/settings/keys>.
2. Find the key, click **⋯ → Delete**. (Delete, not disable.)
3. Click **Create Key**, name it `lumina-backend-prod`, and copy it. This is the
   only time it's shown.
4. Keep the new key in your password manager. It goes into Fly in Step 2 — never
   into this repo, never into `.env.local`, never into the app.

> **Why the history still matters:** the key is scrubbed from the working tree and
> `gitleaks` now blocks new ones, but the old commit still contains it. Purging git
> history means force-pushing a rewritten `main`, which breaks every clone and every
> open branch. Rotating the key makes the historical copy worthless, which achieves
> the same thing for a fraction of the disruption. If you want it gone anyway, do it
> *after* launch with `git filter-repo`, on a quiet day.

---

## Step 2 — Deploy the backend

Nothing in the app works without this. Every chart, transit, reading and
compatibility result comes from this service. It has never been deployed.

```bash
# One-time: install and log in
curl -L https://fly.io/install.sh | sh
fly auth login

cd backend
fly launch --no-deploy     # accept everything from the existing fly.toml —
                           # app name `lumina-ephemeris`, region `arn`
                           # (Stockholm). Change the region only if most of
                           # your users are elsewhere.
```

Set the two secrets it needs:

```bash
# The key from Step 1.
fly secrets set ANTHROPIC_API_KEY="sk-ant-..."

# A shared secret the app sends on every request. Generate a fresh one:
fly secrets set LUMINA_API_SECRET="$(openssl rand -hex 32)"
```

**Write that second value down** — Step 3 puts the same string into GitHub.

```bash
fly deploy
fly status                 # should show one machine, started
curl https://lumina-ephemeris.fly.dev/health
# expect: {"status":"ok"}
```

If `/health` returns 503, the service booted but can't compute — check
`fly logs`. If it doesn't respond at all, the machine didn't start; `fly logs`
again.

Then set a spend alarm, because an unbounded LLM bill is the classic first-month
surprise:

- Fly: <https://fly.io/dashboard> → Billing → set a monthly budget alert.
  Expect a few dollars a month: `fly.toml` keeps one machine warm on purpose,
  because a cold start on the first request of the day surfaced as an error
  state on four tabs at once.
- Anthropic: <https://console.anthropic.com/settings/limits> → set a monthly spend
  limit. Start low (e.g. $50) and raise it when you see real traffic.

---

## Step 3 — Put the secrets into GitHub

The build injects these into the app at compile time. Without them the shipped app
has no backend, no purchases and no push.

Go to **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret name | Value |
|---|---|
| `SWISS_EPH_SERVICE_URL` | `https://lumina-ephemeris.fly.dev` — **https**, no trailing slash |
| `SWISS_EPH_API_SECRET` | the `LUMINA_API_SECRET` from Step 2, character for character |
| `REVENUECAT_API_KEY_IOS` | from Step 5 |
| `ONESIGNAL_APP_ID` | from Step 6, or leave unset — push degrades cleanly |
| `SUPABASE_URL` | optional — sign-in works without it |
| `SUPABASE_ANON_KEY` | optional |

**If you do configure Supabase**, also deploy the account-deletion function —
otherwise "Delete account" wipes the device but leaves the server account behind,
which is the exact thing Guideline 5.1.1(v) is about:

```bash
supabase functions deploy delete-account
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=... \
  APPLE_TEAM_ID=... APPLE_KEY_ID=... APPLE_CLIENT_ID=app.lumina.ios
supabase secrets set APPLE_PRIVATE_KEY="$(cat AuthKey_XXXX.p8)"   # revokes the Sign in with Apple token
```

Without Supabase the app treats deletion as local-only and says so — that's a
supported configuration, not a bug.

> The name says "Swiss Eph" for historical reasons. It's the Node service you just
> deployed; the ephemeris is `astronomy-engine`. Don't rename it — the app, the
> injection script and both workflows all agree on this name.

The release workflow refuses to build if the first four are empty, and asserts the
URL is `https`, so a mistake here fails loudly instead of shipping a dead app.

---

## Step 4 — Turn on GitHub Pages

Your Support URL and Privacy Policy URL must resolve, or App Review rejects the
submission outright. The pages are already written and committed.

1. **Settings → Pages**.
2. Source: **Deploy from a branch**. Branch: `main`, folder: **`/docs`**. Save.
3. Wait ~2 minutes, then open all three in a browser:
   - <https://wrexist.github.io/Lumina/>
   - <https://wrexist.github.io/Lumina/privacy.html>
   - <https://wrexist.github.io/Lumina/support.html>

All three must load. If they 404, the folder setting is wrong — it must be `/docs`,
not `/root`.

---

## Step 5 — RevenueCat: make the subscription real

The app's paywall reads live prices from RevenueCat. Until this is configured it
shows "Subscription pricing isn't available right now" and sells nothing.

**In App Store Connect first** (My Apps → Lumina → Subscriptions):

1. Create a subscription group named **Lumina Premium**.
2. Add two auto-renewable subscriptions in that group:

   | Reference name | Product ID | Duration |
   |---|---|---|
   | `Lumina Premium Monthly` | `lumina_plus_monthly` | 1 month |
   | `Lumina Premium Annual` | `lumina_plus_annual` | 1 year |

3. Set prices, add a display name and a review description for each (copy is in
   `docs/APP-STORE-LISTING.md`), and upload a review screenshot for each.
4. **No weekly tier.** Apple is actively rejecting weekly subscriptions in this
   category.

**Then in RevenueCat** (<https://app.revenuecat.com>):

5. Create a project → add an **App Store** app → paste your bundle ID
   `app.lumina.ios` and upload the App Store Connect shared secret.
6. **Entitlements** → create one with the identifier **`lumina_plus`**. This string
   must match exactly — it's what the app checks.
7. **Products** → import both products from App Store Connect. Attach both to the
   `lumina_plus` entitlement.
8. **Offerings** → create an offering and **mark it Current**. Add both products
   as packages: the monthly one as `$rc_monthly`, the annual as `$rc_annual`.
   Those two package identifiers are what the app looks up — the *product* IDs
   in step 2 can be anything you like, but these cannot.
9. **API keys** → copy the **public** iOS key (starts `appl_`) into the
   `REVENUECAT_API_KEY_IOS` GitHub secret from Step 3.

**Verify before moving on:** the offering must be the **Current** one and show
both packages, and the entitlement must show both products. The app reads
`offerings.current` and asks it for `$rc_monthly` and `$rc_annual` — a
non-current offering means the paywall shows no prices at all, and a missing
package means that plan silently disappears from the picker.

---

## Step 6 — Register the App ID capabilities

The entitlements are already declared in the project. Apple has to be told the App
ID is allowed to use them, or the signed build fails to install.

At <https://developer.apple.com/account/resources/identifiers> → `app.lumina.ios` →
Edit, tick:

- **App Groups** — then create/select `group.app.lumina.ios` (the widget reads your
  chart through it; without this the home-screen widget stays blank)
- **Push Notifications**
- **Sign In with Apple**
- **Associated Domains** — only if you do Step 10

Save. Signing is automatic in the release workflow, so there's nothing else to do.

---

## Step 7 — Ship a build to TestFlight

```
GitHub → Actions → "ios-testflight" → Run workflow
```

It lints, runs the full test suite, archives a signed build, and uploads. Leave the
build-number field empty unless you're re-uploading.

Three secrets must already exist for this to work (from the earlier TestFlight
setup — see `docs/TESTFLIGHT.md`): `APP_STORE_CONNECT_KEY_ID`,
`APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`.

When it lands (~10 min in ASC), **install it on a real iPhone and check these five
things** — they're the ones a simulator can't tell you:

1. Onboarding completes and your chart appears with real degrees.
2. Today shows a reading, the moon phase, and today's transits.
3. Settings → Lumina Plus → the paywall shows **real prices in your currency**.
4. Buy the monthly plan with a sandbox account. Human Design and Compatibility
   unlock. Then Settings → Restore purchases and confirm it still says Active.
5. Add the widget to your home screen. It shows your Sun, Moon and Rising —
   it's a Plus feature, so do this *after* step 4, not before.

If step 3 shows "Subscription pricing isn't available", go back to Step 5 — the
offering isn't published.

---

## Step 8 — Screenshots

Required: 6.9" (iPhone 16 Pro Max). Take them from the TestFlight build with your
own chart in it — real data photographs better than sample data.

Six shots, in this order (captions and rationale in `docs/APP-STORE-LISTING.md`):

1. Birth chart wheel
2. Ask your chart
3. Today / daily reading
4. Cosmic Signature (Big Three)
5. Compatibility result
6. A tagline card (no device frame)

**Do not include a palm-reading screenshot.** Palm reading isn't in this build, and
a screenshot of a feature that doesn't exist is a Guideline 2.3.1 rejection.

---

## Step 9 — App Store Connect listing

Everything you need to paste is in **[`docs/aso/`](./docs/aso/)** — name, subtitle,
three keyword fields, description, release notes, categories, age rating, IAP
names, review notes, and the screenshot storyboard. The text itself lives in
`metadata/app-store.json`, so run:

```bash
python3 scripts/aso_lint.py --print   # every field with its character count
```

Nothing there is guesswork about limits: `scripts/aso_lint.py` validates each
field, fails on a keyword field that would be silently voided for being one
character over 100, and fails on any term naming a feature this build doesn't
have. It runs in CI too.

Work through **`docs/aso/METADATA-PACK.md` §10** — it's the submission
checklist, ordered so nothing waits on something later in the list.

Two things that need your own decision, not a paste:

- **Support URL** — must be a mailbox you actually read. The pages currently point
  at `@lumina.app`, a domain that doesn't exist. Either do Step 10, or change
  `docs/support.html` and `docs/privacy.html` to a real address (a Gmail is fine)
  before submitting. **An unmonitored support address is a rejection.**
- **Export compliance** — the app uses only standard HTTPS. Answer "Yes" to using
  encryption, then "Yes" to the exemption for standard encryption.

The privacy questionnaire is no longer a judgement call: every answer, and the
line of code that justifies it, is in
**[`docs/aso/PRIVACY-LABELS.md`](./docs/aso/PRIVACY-LABELS.md)**, derived from
`PrivacyInfo.xcprivacy` so the two can't contradict each other. Don't answer
"no data collected" — it's the single most common cause of a post-approval
metadata rejection.

---

## Step 10 — The domain (optional, do it later)

`lumina.app` doesn't exist. Nothing breaks without it: universal links fall back to
the `lumina://` scheme, and the GitHub Pages URLs work fine for Apple.

If you want it:

1. Register `lumina.app`.
2. Host `web/apple-app-site-association` at
   `https://lumina.app/.well-known/apple-app-site-association`, served as
   `application/json` with **no** `.json` extension.
3. Point a `CNAME` at GitHub Pages and set the custom domain in Settings → Pages.
4. Update the three URLs in App Store Connect and the addresses in
   `docs/privacy.html` / `docs/support.html`.

---

## Step 11 — Two things to fix in the repo settings

Small, but they're public and they're wrong:

- **Repository description** (top-right of the GitHub repo page → ⚙︎) currently
  reads *"iOS astrology and palm reading app… Vision framework palm CV, Swiss
  Ephemeris"*. None of that is in the binary. Suggested replacement:

  > iOS astrology app. SwiftUI 5, iOS 26, real ephemeris math from a self-hosted
  > service, RevenueCat subscriptions.

- **Legal review.** Fortune-telling framing is regulated in some jurisdictions and
  nobody has looked at this. The in-app disclaimer now appears on the daily reading,
  the onboarding reveal and the Q&A screen, which is the standard mitigation — but
  a lawyer's half-hour is cheap next to a takedown.

---

## Step 12 — Submit

1. ASC → Lumina → **Add for Review**.
2. Attach the build from Step 7.
3. Paste the App Review notes from `docs/APP-STORE-LISTING.md`. They tell the
   reviewer exactly how to reach the paywall and the delete-account flow, which is
   the difference between a one-day review and a week of back-and-forth.
4. Submit.

Typical review is 24–48 hours. If it's rejected, the message names the guideline —
`docs/APP-STORE-LISTING.md` covers 2.1, 2.3.1, 3.1.1, 3.1.2 and 5.1.1(v), which are
the five this category actually gets hit with.

---

## After launch — the first week

- Watch `fly logs` and the Anthropic console for the first few days. Traffic
  patterns after a launch look nothing like your testing.
- Crash reports arrive via MetricKit, on-device, up to 24 hours late. They appear
  in the unified log under subsystem `app.lumina.ios`, category `Diagnostics`. To
  collect them centrally instead, set `LuminaDiagnosticsEndpoint` in
  `Info.plist` to a URL that accepts a JSON POST.
- Answer every support email within a day. Early reviews are disproportionately
  weighted, and a fast reply frequently turns a 2-star into a 5-star.
