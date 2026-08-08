---
name: app-store-metadata
description: Write or revise App Store Connect metadata for this app — name, subtitle, keywords, description, promotional text, What's New, IAP names, screenshot captions, privacy labels, review notes. Use whenever the task touches ASO, keyword research, store copy, a rejection over metadata, or preparing a submission. Also use before changing any user-visible feature claim, since claims and metadata have to move together.
---

# App Store metadata for Lumina

The fields live in `metadata/app-store.json`. Everything else is derived.
Never hand-edit copy inside a markdown file — it drifts and nothing checks it.

```sh
python3 scripts/aso_lint.py           # validate (also runs in CI)
python3 scripts/aso_lint.py --print   # paste-ready blocks + character counts
```

Read `docs/aso/KEYWORD-RESEARCH.md` before proposing keyword changes; it holds
the reasoning the current field is built on, and repeating a settled argument
wastes the reviewer's time.

## The five rules that matter

**1. Only three fields are indexed.** App Name (30), Subtitle (30), Keywords
(100) — per localization. The description is *not* indexed on the App Store,
unlike Google Play. Copy written to rank in the description is wasted; write
it to convert.

**2. Never repeat a token.** Apple indexes each word once and stems plurals,
so `chart` in the name means `charts` in the keyword field buys nothing. The
linter fails on this, including across the three keyword localizations.

**3. Apple builds phrases itself.** Ship `human` and `design` as separate
tokens, not `human design` — the space costs a character and the phrase forms
anyway. Same for `saturn`+`return`, `rising`+`sign`, `moon`+`phase`.

**4. One character over 100 voids the entire keyword field.** Not truncated —
ignored, silently, with no error anywhere in App Store Connect.

**5. A keyword is a claim.** Metadata naming a feature the binary lacks is a
Guideline 2.3.1 rejection. This project has already been through one full
metadata rewrite for exactly that (the name sold palm reading the app didn't
have), and a second cleanup that removed `tarot`. The linter enforces a
forbidden-term list from the JSON; the description may name such a feature
*only* in a sentence that denies it.

## When asked to improve rankings

Do these in order, and say which step the answer came from:

1. **Check what the app actually does first.** Grep the feature before adding
   its keyword. A term for an unbuilt feature is worse than no term.
2. **Spend the name on the highest-intent phrase**, not the brand alone.
3. **Fill all three keyword fields.** The US storefront indexes `es-MX` (well
   documented) and reportedly `en-GB` alongside `en-US`. The field is never
   shown to a user, so English long-tail belongs there.
4. **Do not invent search volume.** Popularity scores come from Apple Search
   Ads, 5–100, exponential. If no data is available, say so explicitly and
   reason from intent and competitive structure instead — never present a
   guessed number as a measurement.
5. **Change five keywords per release, not thirty.** A wholesale rewrite makes
   the result unattributable.

## When asked for screenshots

`docs/aso/SCREENSHOTS.md` has the storyboard. Captions carry keywords because
Apple OCRs them (June 2025 change), but that signal is contested and weak —
never move a term out of the indexed fields to a caption.

Screenshots require a Mac with a simulator; this repo's CI runs on macOS but
capture is manual. Don't promise generated screenshots from a Linux session —
mockups are fine when labelled as mockups, and passing one off as a screenshot
is not.

## Privacy labels

`docs/aso/PRIVACY-LABELS.md`. They must match `Lumina/Resources/PrivacyInfo.xcprivacy`
exactly; Apple compares them. Change both or neither.

## Definition of done

- `python3 scripts/aso_lint.py` passes with zero failures
- Every new term names something a user can actually reach in the build
- The rationale for any changed field is added to `docs/aso/KEYWORD-RESEARCH.md`,
  so the next session doesn't re-litigate it
