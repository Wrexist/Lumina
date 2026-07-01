# Lumina — Virality & Engagement Plan (2026-06-06)

How Lumina grows and retains **without** betraying the premium, anti-fleeceware
brand. The category's biggest growth levers are all premium-compatible — beauty,
being seen, real timing, and social — which is exactly why CHANI/Co-Star spread
and the tacky apps churn.

## The five dopamine loops astrology audiences actually want

1. **"It called me out" (recognition).** Hyper-specific, personal insight. The hit
   is "this is SO me." Lumina's edge: it's *real* (grounded in the chart), so the
   specificity is honest, not a Barnum-statement.
2. **Identity to broadcast (self-expression).** "Scorpio rising" is a personality
   flag people *share*. Beautiful, screenshot-perfect cards are the #1 viral engine
   in this category — it's how CHANI/Co-Star spread for free.
3. **"How compatible are we?" (social).** Inherently viral — you send it to the
   person. Relationships are the top engagement multiplier; the friend graph is a
   network effect.
4. **Curiosity gaps + daily novelty.** A genuine new thing each open ("your rare
   placement", "the transit no one warns you about") — a reason to return that
   isn't a streak.
5. **Anticipation / timing.** "Your Saturn return is in 47 days." Countdown dopamine
   — and timing is literally what astrology is.

## Brand guardrails (keep)

- **No streaks, confetti, badge bursts, or achievement spam** (CLAUDE.md). They
  cheapen the premium signal and are the fleeceware tell.
- **No anxiety-bait.** Notifications stay kind and useful (already shipped).
- **No faked anything.** Every shareable claim is real chart data.

## Build list (viral-first, all unblocked)

Priority order — each ships as its own CI-verified commit:

1. ✅ **Cosmic Profile + shareable Story cards** — dominant element + modality +
   Big-3 as a gorgeous portrait share card, plus an in-app "your cosmic signature"
   surface. Identity + virality in one. (`CosmicSignature`, `CosmicProfileCard`.)
2. ✅ **Shareable compatibility result** — a share card from a friend ("we're 84% —
   here's why") + an invite loop, so the result travels to the other person.
3. ⏳ **"Your next big moment" countdown** — reuses `/forecast` + `/returns`; an
   anticipation card ("Saturn return in 47 days", "Venus meets your Sun in 9 days").
4. ✅ **Daily-reading share card** — one-tap share of today's reading, Story-shaped.
5. ⏳ **Moon-ritual check-ins** — new-moon intention / full-moon release prompts on
   the real lunar phase (already have `/moon`). A genuine recurring ritual, not a
   streak.
6. ⏳ **"Cosmic weather" week-ahead** — a weekly view of what's coming (reuses
   `/forecast`), for anticipation + a weekly return reason.

## What to deliberately NOT do

- Streak counters, daily-login rewards, confetti, XP/levels — off-brand and the
  Apple-scrutinized fleeceware aesthetic.
- Doom-posting notifications for engagement.
- Fake "premium" gates on real chart facts (the honest core stays free).
