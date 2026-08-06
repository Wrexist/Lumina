# Keyword research — how the 1.0 metadata was chosen

The fields themselves live in [`metadata/app-store.json`](../../metadata/app-store.json)
and are validated by `python3 scripts/aso_lint.py`. This file is the argument
behind them.

---

## 1. What is actually indexed

App Store search builds its index from three fields, and **only** three:

| Field | Limit | Visible to users | Notes |
|---|---|---|---|
| App Name | 30 | yes | Heaviest weight |
| Subtitle | 30 | yes | Second heaviest |
| Keywords | 100 | no | Same weight class as subtitle, invisible |

That is 160 characters per localization. The description is **not** indexed on
the App Store (it is on Google Play — the single most common ASO mistake made
by people carrying Android habits over). The description's job is conversion,
not discovery.

Four mechanics drive every decision below:

1. **Apple recombines tokens into phrases by itself.** `human` + `design` in
   the keyword field lets the app rank for "human design". Writing the phrase
   out costs a character for the space and buys nothing.
2. **Repeating a word across fields wastes the slot.** A word in the name is
   already indexed; spending keyword budget on it again buys zero new phrases.
   `scripts/aso_lint.py` fails the build on this, stems included.
3. **Plurals are stemmed.** `chart` covers `charts`. Never spend on both.
4. **One character over 100 and Apple ignores the entire keyword field** — not
   the overflow, the whole thing, silently. This is why the limit check is in
   CI rather than in a checklist.

Sources: [AppLaunchFlow keyword field guide 2026](https://www.applaunchflow.com/blog/app-store-keyword-field-guide-2026),
[AppScreenshotStudio indexed-field reference](https://appscreenshotstudio.com/tools/app-store-indexed-fields).

---

## 2. The strategic problem: a zero-install app cannot win head terms

Ranking is not metadata alone. Install velocity, tap-through rate and
retention feed the same algorithm, and in 2026 engagement signals weigh more
than they used to ([ASO World, 2026 ranking factors](https://asoworld.com/insight/app-store-ranking-in-2026-why-retention-and-engagement-now-matter-more-than-keywords/)).

"astrology" and "horoscope" are contested by apps with millions of installs
and paid Search Ads budgets — Co–Star, CHANI, Nebula, and the "Astrology &
Palmistry Coach" cluster. A brand-new app with no install history does not
outrank them by writing a better keyword field, and pretending otherwise is
how ASO advice wastes a launch.

So the 1.0 plan splits the 160 characters by *what each one can realistically win*:

- **Name + subtitle** carry the head/mid terms that convert once someone is
  already looking at the product page. They also have to read like a product,
  because they are the two lines a human sees in search results.
- **Keyword fields** carry mid and long-tail terms where a precise, honest app
  can actually place — and where the searcher's intent matches what Lumina
  uniquely does.

The head terms are still present (`astrology` in the name, `horoscope` and
`zodiac` in keywords), because you rank for them eventually and there is no
cost to being indexed. They are simply not what the launch bets on.

---

## 3. Where Lumina can actually win

The differentiators are real, checkable, and rare in this category:

| Differentiator | Search terms it earns | Why competition is thin |
|---|---|---|
| A real Swiss-Ephemeris backend | `ephemeris`, `degree`, `orb`, `cusp` | Most apps approximate; nobody markets on the word |
| Three house systems | `placidus`, `sidereal`, `houses` | Serious-practitioner vocabulary |
| Synastry **and** composite | `synastry`, `composite` | Most apps stop at a compatibility percentage |
| Transit forecast with exact dates | `transits`, `forecast`, `retrograde`, `saturn`+`return` | High intent, mid volume |
| Human Design bodygraph | `human`, `design` | A whole adjacent category, few astrology apps carry it |
| Real moon phase + ritual | `moon`, `phase`, `lunar`, `eclipse` | Big volume, and we have the actual feature |
| Private on-device journal | `journal`, `ritual`, `tracker` | Different intent cluster, cheap to own |

The pattern: **every keyword names something the binary does.** That is not
only an integrity position — Apple rejects metadata that describes features
the app lacks (Guideline 2.3.1), and this project has already been through
one full metadata rewrite because the name sold palm reading the app did not
have. `tarot` was dropped from the previous keyword draft for exactly this
reason: there is no tarot deck in Lumina.

---

## 4. The chosen fields

```
Name      Lumina: Birth Chart Astrology          (29/30)
Subtitle  Daily transits, moon, synastry         (30/30)
Keywords  horoscope,natal,zodiac,rising,human,design,forecast,retrograde,ephemeris,saturn,return,phase,sign   (97/100)
```

**Why "Birth Chart Astrology" in the name.** The name carries the most weight,
so it gets the highest-intent phrase in the category. "birth chart" is what
people type when they want *this* app rather than a daily-horoscope feed, and
it is the feature Lumina is best at. It also reads as a product name, not a
keyword dump — Apple rejects names that are obvious stuffing.

**Why the subtitle is three nouns.** `daily`, `transits`, `moon`, `synastry` —
four tokens, none repeated from the name, each combining with name and keyword
tokens into phrases people actually search: "daily horoscope", "moon phase",
"synastry chart", "transit forecast". A prettier tagline ("Your real sky,
every day") would index `real` and `sky` and throw away the other three slots.

**Phrases the three fields combine into**, none of which is written out
anywhere: birth chart astrology · daily horoscope · natal chart · rising sign ·
moon phase · synastry chart · human design chart · transit forecast · saturn
return · retrograde forecast · zodiac sign · astrology chart · birth chart
compatibility (via `composite`/`aspects` in the second field).

---

## 5. Three keyword fields, not one

The US storefront indexes secondary-locale metadata alongside `en-US`. Adding
`es-MX` (and, reportedly, `en-GB`) gives a second and third 100-character
keyword field that also apply to US search. The field is never shown to a
user, so filling it with English long-tail is not a deception — it is filling
space Apple has already decided to index. This is standard practice, not a
loophole ([Appfigures](https://appfigures.com/resources/guides/extend-keyword-list),
[AppTweak](https://www.apptweak.com/en/aso-blog/how-to-benefit-from-cross-localization-on-the-app-store),
[MobileAction](https://www.mobileaction.co/blog/app-store-cross-localization/)).

```
es-MX  aspects,houses,composite,placidus,sidereal,ascendant,venus,mars,mercury,ritual,journal,tracker   (94/100)
en-GB  star,lunar,eclipse,solar,planet,degree,orb,report,reading,guide,calendar,planner,insight,sky,cusp (97/100)
```

Total: **347 indexed characters, 40 distinct keywords** — versus 127 characters
if we had shipped one field.

Two caveats, stated plainly:

- `es-MX` cross-indexing into the US storefront is well documented. `en-GB`
  into the US is *reported* and worth taking (it costs nothing and it
  definitely serves the UK storefront), but do not build a plan on it.
- Adding a localization means Apple expects that localization's product page
  to make sense. The `es-MX` page inherits the en-US name, subtitle and
  description unless you fill them in; that is acceptable, but if you ever
  translate the page properly, the keyword field must be rewritten in Spanish
  for the actual Mexican market.

---

## 6. What this plan does *not* have: real volume numbers

Honest limitation, stated up front rather than buried: **no popularity data
was available when this was written.** Apple's popularity scores come from
Apple Search Ads (or a tool that resells them), which needs an account this
repo has no access to. Every ranking judgement above is reasoned from category
structure, competitor positioning and intent — not measured.

Before locking 1.0, spend twenty minutes closing that gap:

1. Create an Apple Search Ads account (free; no campaign has to run).
2. Open **Search Ads → Keywords → Search Match / keyword ideas** and read the
   popularity score, 5–100, for every term in the three fields above.
3. Replace any term scoring 5 that also has an obvious higher-volume synonym.
   Do **not** blanket-drop 5s: since 2026 Apple reports many genuine mid-volume
   terms as a flat 5, and a low-reported score often marks a high-converting
   niche term rather than a dead one
   ([Sonar](https://trysonar.app/blog/apple-search-popularity),
   [RespectASO](https://respectaso.com/blog/apple-search-ads-popularity-unreliable-aso-keyword-data/)).
4. Re-run `python3 scripts/aso_lint.py` — it will catch any overlap or overflow
   the edit introduces.

The scale is exponential: 60 is not "twice" 30, it is an order of magnitude.
Do not average these scores.

---

## 7. The loop after launch

Metadata is not a one-time exercise, and the keyword field can be changed only
with a new version — so plan the cadence:

| When | Do |
|---|---|
| Launch day | Baseline: record rank for all 40 terms |
| Weekly, first month | Watch which terms produce impressions in App Analytics → Sources → App Store Search |
| Every release | Swap the bottom five performers for new candidates; never rewrite the whole field at once, or you can't attribute the change |
| Any time | Promotional text is free to edit without review — use it for seasonal hooks ("Mercury retrograde starts Friday") |

Run paid Search Ads on the *exact* terms you want to rank for organically
before you commit them to the field: a week of ASA data tells you conversion
rate per term, which is the number that actually predicts organic performance.
That is the ASA→ASO loop ([Stormy](https://stormy.ai/blog/asa-to-aso-keyword-loop-strategy)).

### The bench

Release 2 shouldn't start from a blank page. `metadata/app-store.json` carries
a `keyword_bench`: ranked candidates that are *not* live, each naming the term
it would replace and why. The linter checks that none of them is already
indexed, that each swap target actually exists, and that none names an
unshipped feature — a wasted swap costs a whole release, because the keyword
field can only change with a new version.

Three of them are gated on the app, not on the data, and the note says so:
`chiron` and `nodes` only once the chart plots those points, `vedic` only if
the sidereal option genuinely satisfies that searcher. Shipping a keyword
ahead of its feature is the mistake this whole document exists to prevent.

There is also a `do_not_use` list — `tarot`, `palm`, `psychic`, `numerology`,
`free` — with the reason attached, so nobody re-adds one in six months when
the context has been forgotten. That is exactly how `tarot` got in.

---

## 8. Screenshot captions are a fourth, weaker index

In June 2025 Apple began extracting text from screenshots via OCR and using it
as a metadata signal. How strong it is remains contested — ConsultMyApp tested
64 screenshot-derived phrases across 8 apps and found only one that ranked
without another explanation.

Treat it as free upside, never as a substitute: write the captions with real
keywords in them (see [`SCREENSHOTS.md`](./SCREENSHOTS.md)), but keep every
term that matters in the three indexed fields.
