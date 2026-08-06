# App Store listing — moved

This file used to hold the listing copy. It has been replaced by a pack that
keeps the fields in one machine-checked place instead of in prose:

- **[`docs/aso/`](./aso/)** — the metadata pack, keyword research, screenshot
  storyboard and privacy answers
- **[`metadata/app-store.json`](../metadata/app-store.json)** — the source of
  truth for every text field
- `python3 scripts/aso_lint.py` — validates limits, keyword overlap and
  accuracy claims; runs in CI

Three things changed substantively in the move, not just the filing:

1. **`tarot` was removed from the keyword field.** Lumina ships no tarot
   deck. Keywords are indexed metadata and fall under the same accuracy rule
   (Guideline 2.3.1) that forced the name and subtitle to drop palm reading —
   the linter now fails the build on either.
2. **The name leads with the phrase that converts.** `Lumina: Birth Chart
   Astrology` puts the category's highest-intent term where Apple weighs it
   most, instead of the vaguer "Astrology & Charts".
3. **Three keyword fields instead of one.** The US storefront indexes
   secondary-locale metadata, so `es-MX` and `en-GB` carry English long-tail:
   347 indexed characters and 40 distinct keywords, up from 127 and 13.
