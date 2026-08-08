# Apple Search Ads — the seed plan

Organic ranking for a new app is downstream of installs and conversion, so the
fastest way to move the organic needle is to buy the first installs on terms
you intend to own. This is the structure to start with, and — more importantly
— the decision rules for what to do with what it tells you.

Nothing here invents a bid or a CPT. Those are auction-dependent and market-
specific, and a made-up number is worse than none.

---

## Why bother, when 1.0 has no budget for scale

Two reasons that are not "growth":

1. **Search Ads is the only source of Apple's own keyword data.** Popularity
   scores (5–100) and per-keyword conversion rate come from the ads console.
   Without it, every keyword decision in [`KEYWORD-RESEARCH.md`](./KEYWORD-RESEARCH.md)
   stays reasoned rather than measured.
2. **Conversion rate per term predicts organic performance.** A term that
   converts well in paid will convert well organically; a term with volume and
   no conversion is a trap you'd otherwise take months to notice. Buy a week of
   that signal before committing keywords you can only change with a new
   version.

A small daily cap is enough for both. This is instrumentation that happens to
also sell.

---

## Four campaigns, in this order

Apple's structure is Campaign → Ad Group → Keywords. Keep them separate so one
campaign's data never contaminates another's.

### 1. Brand — `Lumina · Brand · Exact`

Keywords: `lumina`, `lumina astrology`, `lumina app`, `lumina birth chart`.
Match: **exact**.

Cheapest installs you will ever buy, and the reason to run it isn't traffic —
it's defence. Competitors can bid on your brand name, and the first result for
someone who already typed your name should be you. Also the control group: if
brand converts at 60% and a discovery term converts at 8%, you've learned what
"good" looks like in your own category rather than an industry average.

### 2. Discovery — `Lumina · Discovery · Broad`

Keywords: none. Search Match **on**, broad match on a handful of seeds.

Apple decides what to show you against. Its job is to surface search terms you
never thought of; harvest them weekly into the campaigns below and add
negatives for anything irrelevant. Expect noise — that's the point of running
it separately from the terms you're measuring.

### 3. Category — `Lumina · Category · Exact`

The terms from the live keyword fields, one ad group per intent cluster so the
data is legible:

| Ad group | Keywords |
|---|---|
| Chart | `birth chart`, `natal chart`, `astrology chart`, `birth chart calculator` |
| Daily | `daily horoscope`, `horoscope`, `transits`, `astrology app` |
| Relationship | `synastry`, `compatibility`, `composite chart`, `couple compatibility` |
| Adjacent | `human design`, `human design chart`, `moon phase`, `saturn return` |

Match: **exact**, so each term's number is its own. Broad match here would
blur exactly the signal you're paying for.

### 4. Competitor — `Lumina · Competitor · Exact` *(optional, later)*

`co-star`, `the pattern`, `chani`, `time passages`, `nebula astrology`.

Legal and normal, and Apple allows it. Two honest caveats: brand-intent
searchers convert poorly for a rival, and this is the campaign most likely to
lose money for a 1.0. Run it last, on a small cap, and only after the other
three have baselines to compare against.

---

## What to do with the numbers

Read these weekly. The decisions matter more than the dashboards.

| Signal | What it means | Do |
|---|---|---|
| High impressions, low taps | Your icon/name/subtitle isn't winning the result | Change the **subtitle**, not the keyword |
| High taps, low installs | The product page isn't converting | Change **screenshots 1–3**; they carry the argument |
| Good conversion, low volume | A term worth owning organically | Promote it into the keyword field next release |
| Volume, no conversion | A trap | Add as a negative; keep it out of the keyword field |
| Popularity 5 but converting | Niche, high-intent — Apple under-reports these since 2026 | Keep it |

The last row is the one people get wrong. A flat 5 is not proof a term is
dead; Apple stopped reporting granularly below a much higher threshold, and
some of the best-converting terms in a niche category read as 5.

---

## Feeding it back

The loop this closes:

1. Run exact-match on the terms already in the keyword fields.
2. After ~2 weeks, rank them by **conversion rate**, not volume or CPT.
3. Bottom performers become swap candidates; the
   [`keyword_bench`](../../metadata/app-store.json) supplies replacements, and
   `python3 scripts/aso_lint.py` checks the swap before it ships.
4. Change about five keywords per release. A wholesale rewrite makes the next
   release's numbers unattributable — you won't know which change did what.

Keyword fields can only be edited with a new version, so each cycle costs a
release. Promotional text can be edited any time without review; use it for
anything time-bound (a retrograde, an eclipse) rather than burning a version.

---

## Before spending anything

- Set a **daily cap** and a campaign end date on day one. An uncapped Search
  Ads campaign is the same class of surprise as an uncapped LLM bill, and
  `LAUNCH-STEPS.md` Step 2 already says that about Anthropic and Fly.
- Make sure the product page is finished first. Paying for traffic to a page
  with placeholder screenshots buys expensive proof that the page is bad.
- Check `/health` on the backend is live. Ads driving installs into an app
  whose every screen errors is worse than no ads — those users leave a review.
