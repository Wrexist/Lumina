# Ratings — the ask, and why it's this narrow

Star rating is one of the two things a searcher can see without scrolling
(the other is the icon). A listing with no ratings converts worse than the
same listing with twenty, and the App Store's own ranking treats rating volume
and average as signals. So the app has to ask.

It also has to ask *well*, because the same prompt shown at the wrong moment
is how apps collect one-star reviews from people who were about to leave.

---

## What ships

One ask, from one place: `RequestsReviewOnReveal.swift`, applied in
`TodayHubView`.

| Gate | Value | Where |
|---|---|---|
| Distinct days of use before the first ask | 3 | `ReviewPrompt.requiredEngagedDays` |
| Asks per marketing version | 1 | `ReviewPrompt.markAsked()` |
| Delay after the trigger | 2s | `RequestsReviewOnReveal.swift` |
| Reachable from an error state | never | see below |

A "day of use" is a day the daily reading was actually unveiled — a deliberate
tap on a screen that loaded. Five visits in one evening is one day, not five
(`testRepeatVisitsInOneDayCountOnce`).

Apple's own throttle sits underneath ours: at most three system prompts per
user per year, and none at all if the user has turned them off in Settings.
Ours is the stricter of the two, deliberately.

## Why it can't fire on an error

`TodayHubView.readingSection` — the only thing that can produce a reveal — is
rendered for `.ready` **and** `!transitsUnavailable` only. Loading, missing
birth data, a failed fetch and the transits-unavailable card never render the
veil, so there is no tap to trigger on. The gate isn't a check that could be
forgotten; the trigger is structurally unreachable from every failure path.

That matters more than the three-day rule. A person whose reading just failed
to load is the single worst audience for "enjoying the app?", and it's the
mistake that produces most one-star reviews in this category.

## Why once per version, not once per install

Someone who ignored the prompt on 1.0 is a fair person to ask again after six
months of new work. Keyed on `CFBundleShortVersionString`, not the build
number, so a TestFlight train doesn't burn the ask.

`markAsked()` runs *before* `requestReview()`, not after: the API reports
nothing back — not whether it drew anything, not whether the user had prompts
switched off — so that call site is the only place the slot can be burned.
Marking after would re-trigger on every unveil forever.

## After launch

- **Never chase a rating with a custom pre-prompt** ("do you like Lumina?
  → yes → show the real one"). Apple allows it and plenty of apps do it; it
  inflates the average by filtering, and it costs you the honest signal about
  what's wrong. This app doesn't have one.
- **Respond to reviews in App Store Connect.** Replies are public, and a
  reply flips a fair number of one-stars once the issue is fixed. It's the
  cheapest rating work there is.
- **Watch the first twenty.** They set the average for months. If they cluster
  on one complaint, that complaint is the 1.1 release.
- Ratings reset per-version only if you ask them to. Don't — a reset throws
  away the volume the ranking cares about.

## Where account deletion touches this

`SettingsView.eraseEverything()` calls `ReviewPrompt.shared.clear()`. Without
it, a fresh account on the same device could be asked on its first day,
carrying the previous account's engagement. Covered by `testClearErasesTheRecord`.
