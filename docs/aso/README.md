# App Store metadata & ASO

Everything needed to fill in App Store Connect, plus the reasoning behind it
and a linter that keeps it correct.

| File | What it's for |
|---|---|
| [`METADATA-PACK.md`](./METADATA-PACK.md) | Every ASC field in submission order, plus the checklist |
| [`KEYWORD-RESEARCH.md`](./KEYWORD-RESEARCH.md) | Why these keywords, what Apple indexes, and the loop after launch |
| [`SCREENSHOTS.md`](./SCREENSHOTS.md) | The six screenshots, their captions, sizes, and the preview script |
| [`PRIVACY-LABELS.md`](./PRIVACY-LABELS.md) | Privacy answers, each traced to the code that justifies it |
| [`../../metadata/app-store.json`](../../metadata/app-store.json) | **Source of truth** for every text field |
| [`../../scripts/aso_lint.py`](../../scripts/aso_lint.py) | Validates limits, keyword overlap and accuracy claims |

## The three commands

```sh
python3 scripts/aso_lint.py              # validate — also runs in CI and local_checks.sh
python3 scripts/aso_lint.py --print      # paste-ready blocks with character counts
python3 scripts/aso_lint.py --fastlane   # regenerate fastlane/metadata/ for `deliver`
```

`fastlane/metadata/` is committed and generated — never hand-edit it. Fifteen
paste operations into App Store Connect is fifteen chances to paste the wrong
field with no way to diff what was uploaded; `fastlane deliver` reads that tree
instead, from the same source of truth this linter checks.

## The rules this encodes

1. **Edit the JSON, never a doc.** The markdown explains; the JSON ships.
2. **A keyword is a claim.** No field may name a feature the binary doesn't
   have — that rule already cost this project one full metadata rewrite, and
   the linter now fails on `palm`, `tarot`, `psychic`, `numerology`.
   The description may name one *only* to deny it.
3. **Never repeat a token across name, subtitle and keyword fields.** Apple
   indexes each once; a repeat is a wasted slot, and the linter fails on it,
   stems included.
4. **One character over 100 kills the whole keyword field**, silently. Hence
   CI rather than a checklist item.
5. **Popularity numbers must come from Apple Search Ads.** Nothing here
   invents a search volume — see KEYWORD-RESEARCH.md §6 for the twenty-minute
   procedure that closes that gap before you lock 1.0.

## What is deliberately not here

App Store *screenshots* (the images) and the app preview video — those need a
Mac with a simulator. The storyboard and captions are specified so producing
them is mechanical.
