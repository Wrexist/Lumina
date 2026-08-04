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

echo "== Swift file length (file_length: 400) =="
# SwiftLint counts every line in the file, comments and blanks included.
FILELEN="$(python3 - <<'PY'
import pathlib
limit = 400
for root in ("Lumina", "LuminaWidget", "LuminaTests"):
    for path in pathlib.Path(root).rglob("*.swift"):
        count = len(path.read_text().splitlines())
        if count > limit:
            print(f"{path}:{count} — file length {count} (limit {limit})")
PY
)"
if [ -n "$FILELEN" ]; then echo "$FILELEN"; FAILED=1; else note "ok"; fi

echo "== Swift function body length (function_body_length: 40) =="
# Approximation: find a `func`/`init` signature, walk forward to the line that
# opens its body (signatures often wrap across several lines), then count the
# non-comment, non-blank lines to the closing brace at the same indent.
FUNCLEN="$(python3 - <<'PY'
import pathlib, re
limit = 40
sig = re.compile(r'^(\s*)(?:@\w+\s+)*(?:public |private |fileprivate |internal |static |final |nonisolated |override |convenience |required )*(?:func \w+|init[?!]?\s*\()')
for root in ("Lumina", "LuminaWidget", "LuminaTests"):
    for path in pathlib.Path(root).rglob("*.swift"):
        lines = path.read_text().splitlines()
        for i, line in enumerate(lines):
            m = sig.match(line)
            if not m:
                continue
            indent = m.group(1)
            # Walk to the line that opens the body: a wrapped signature ends on
            # a `) -> Type {` line several lines down. Give up quickly so a
            # protocol requirement (no body) isn't mistaken for one.
            opening = None
            for k in range(i, min(i + 12, len(lines))):
                if lines[k].rstrip().endswith("{"):
                    opening = k
                    break
                if lines[k].rstrip().endswith(("}", ";")):
                    break
            if opening is None:
                continue
            close = indent + "}"
            for j in range(opening + 1, len(lines)):
                if lines[j] == close:
                    body = lines[opening + 1:j]
                    count = sum(
                        1 for b in body
                        if b.strip() and not b.strip().startswith(("//", "///", "*", "/*"))
                    )
                    if count > limit:
                        print(f"{path}:{i + 1} — function body ~{count} lines (limit {limit})")
                    break
PY
)"
if [ -n "$FUNCLEN" ]; then echo "$FUNCLEN"; FAILED=1; else note "ok"; fi

echo "== Swift: String(decoding:as:) (optional_data_string_conversion) =="
DATASTR="$(grep -rn 'String(decoding:' --include='*.swift' Lumina LuminaWidget LuminaTests 2>/dev/null || true)"
if [ -n "$DATASTR" ]; then
  echo "$DATASTR"
  note "use String(bytes:encoding:) instead"
  FAILED=1
else
  note "ok"
fi

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
