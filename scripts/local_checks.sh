#!/usr/bin/env bash
# Fast local approximation of the CI gates that don't need macOS.
#
# There is no local Xcode toolchain on this project (see DEV.md "No-Mac
# workflow"), so a full `swiftlint`/`xcodebuild` run only happens in CI. That
# makes a trivial style violation cost a full round trip. These checks catch
# the ones that are pure text analysis, in about a second.
#
# Usage: bash scripts/local_checks.sh
set -uo pipefail
cd "$(dirname "$0")/.."

FAILED=0
note() { printf '  %s\n' "$1"; }

echo "== Swift line length (.swiftlint.yml line_length: 240) =="
LONG="$(awk 'length > 240 {print FILENAME":"FNR" — "length" chars"}' \
  $(find Lumina LuminaWidget LuminaTests -name '*.swift') 2>/dev/null)"
if [ -n "$LONG" ]; then
  echo "$LONG"; FAILED=1
else
  note "ok"
fi

echo "== Swift file/type body length (type_body_length: 250) =="
# Approximation: count non-blank, non-comment lines between a top-level
# type declaration and its closing brace at column 0.
BIG="$(python3 - <<'PY'
import pathlib, re, sys
limit = 250
for path in list(pathlib.Path("Lumina").rglob("*.swift")) + list(pathlib.Path("LuminaWidget").rglob("*.swift")):
    lines = path.read_text().splitlines()
    start = None
    for i, line in enumerate(lines):
        if re.match(r'^(?:public |private |internal |final )*(?:struct|class|enum|actor) \w+', line):
            start = i
        elif line == "}" and start is not None:
            body = lines[start + 1:i]
            count = sum(
                1 for b in body
                if b.strip() and not b.strip().startswith(("//", "///", "*", "/*"))
            )
            if count > limit:
                print(f"{path}:{start + 1} — type body ~{count} lines (limit {limit})")
            start = None
PY
)"
if [ -n "$BIG" ]; then echo "$BIG"; FAILED=1; else note "ok"; fi

echo "== YAML syntax =="
for f in .github/workflows/*.yml project.yml; do
  if ! python3 -c "import yaml,sys; yaml.safe_load(open('$f'))" 2>/dev/null; then
    echo "  INVALID: $f"; FAILED=1
  fi
done
[ "$FAILED" -eq 0 ] && note "ok"

echo "== Property lists =="
for f in Lumina/Resources/PrivacyInfo.xcprivacy LuminaWidget/PrivacyInfo.xcprivacy ios/ExportOptions.plist; do
  [ -f "$f" ] || continue
  if ! python3 -c "import plistlib; plistlib.load(open('$f','rb'))" 2>/dev/null; then
    echo "  INVALID: $f"; FAILED=1
  fi
done
note "checked"

echo "== Backend =="
if [ -d backend/node_modules ]; then
  (cd backend && npx tsc --noEmit) || FAILED=1
  (cd backend && npm test --silent >/dev/null 2>&1) || { echo "  backend tests FAILED"; FAILED=1; }
  note "typecheck + tests done"
else
  note "skipped (no node_modules)"
fi

if [ "$FAILED" -ne 0 ]; then
  echo
  echo "FAILED — fix the above before pushing."
  exit 1
fi
echo
echo "All local checks passed."
