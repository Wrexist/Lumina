# App privacy labels — the answers, and where each one comes from

App Store Connect → App Privacy. Every answer below is derived from what the
code actually does, and must stay consistent with
[`Lumina/Resources/PrivacyInfo.xcprivacy`](../../Lumina/Resources/PrivacyInfo.xcprivacy)
— Apple compares the two, and a label that contradicts the manifest is a
rejection. When you change one, change both.

**Tracking: No.** Lumina does not track. `NSPrivacyTracking` is `false`,
`NSPrivacyTrackingDomains` is empty, there is no ATT prompt and no ad SDK. Do
not answer "yes" to the tracking question for analytics — tracking has a
specific meaning (linking to third-party data for ads or data brokerage) and
none of it applies here.

## Data collected

| Category | Type | Linked to identity | Purpose | Why — in the code |
|---|---|---|---|---|
| Location | Precise Location | Yes | App Functionality | Birth-place coordinates are POSTed to the ephemeris backend to compute houses (`EphemerisService`). It is a historical birth coordinate, not device location — but coordinates plus a timestamp are re-identifying, so it is declared. |
| Sensitive Info | Sensitive Info | Yes | App Functionality | Birth date and exact birth time. |
| Contact Info | Name | Yes | App Functionality | The name entered at onboarding, and friends' names — stored on device; the account name reaches Supabase at sign-in. |
| Contact Info | Email Address | Yes | App Functionality | Sign in with Apple / Supabase auth. |
| Purchases | Purchase History | Yes | App Functionality | RevenueCat subscription state. |
| Identifiers | Device ID | No | App Functionality | OneSignal push token. |
| Diagnostics | Other Diagnostic Data | No | App Functionality | `CrashReporter`, only when a diagnostics endpoint is configured. |

## Data explicitly *not* collected

Answer "no" for all of these, and be able to defend it:

- **User Content** — journal entries never leave the device (`JournalEntry` is
  local SwiftData, no sync target).
- **Usage Data / Product Interaction** — no analytics SDK is linked.
- **Search History, Browsing History, Contacts, Photos, Audio, Health,
  Financial Info** — none of these are read. There is no camera or photo
  access in 1.0 (the palm feature that would have needed it is not built), and
  the only Photos entitlement is add-only, used when the user chooses to save
  a share card.

## The two answers reviewers push back on

**"Why Precise Location if you never ask for location permission?"** Because
the user types a birth city and the app resolves it to coordinates that are
transmitted. There is no `CLLocationManager` prompt anywhere in the app.
Declaring it is the conservative reading of Apple's definition, and
under-declaring is the failure mode that gets a binary pulled.

**"Is this data linked to the user?"** Yes for birth data, because a signed-in
account carries it. It is not used for tracking, not shared with data brokers,
and the backend stores none of it — `/chart`, `/transits` and `/synastry` are
stateless. The privacy dashboard in Settings says the same thing to users, and
the marketing site's privacy page repeats it.

## Data retention and deletion

- In-app account deletion: Settings → Account → Delete account, which calls
  the `delete-account` Supabase Edge Function. Required by Guideline 5.1.1(v),
  and the reviewer will look for it.
- Data export: Settings → Privacy → Export my data writes a full JSON of
  everything the app holds (`DataExport`).
- Nothing to retain server-side: the chart service is stateless, so "delete"
  really is delete.
