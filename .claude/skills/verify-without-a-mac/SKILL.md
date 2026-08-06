---
name: verify-without-a-mac
description: Verify a change to this repo when there is no Xcode, no simulator and no Swift toolchain — which is every Claude Code session on Linux. Use before claiming a Swift change works, before promising screenshots, and when CI is unavailable so nothing else can compile the app either.
---

# Verifying Lumina without a Mac

The iOS app cannot be built here. There is no Xcode, no simulator, and no
Swift toolchain — `swiftc`, `swiftlint` and `swiftformat` are all absent. CI's
`macos-15` job is the only thing that compiles this project.

That is a real limit, not a reason to guess. State it plainly rather than
implying a change is verified when it isn't.

## What can be verified here

| Area | Command | Catches |
|---|---|---|
| Backend | `cd backend && npx tsc --noEmit && npm test` | Everything — the backend runs natively |
| Everything scriptable | `bash scripts/local_checks.sh` | JSON/plist validity, metadata limits, backend |
| App Store metadata | `python3 scripts/aso_lint.py` | Field limits, keyword overlap, false claims, 404 URLs |
| Asset catalog | `python3 scripts/build_image_assets.py` | Regenerates and re-validates every imageset |
| Marketing site | `cd web-tests && npx playwright test` | Dead links, missing pages (needs the site live) |
| CI config | `python3 -c "import yaml;yaml.safe_load(open('.github/workflows/ci.yml'))"` | YAML that would fail to parse |

## What cannot, and what to do instead

**Swift compilation and SwiftLint.** Read the rules in `.swiftlint.yml`
directly — the opt-in list is long and several rules (`implicit_return`,
`sorted_imports`, `no_magic_spacing_numbers`, the custom colour rules) fail
builds on style. When unsure whether a rule fires, check SwiftLint's source
rather than guessing:
`https://raw.githubusercontent.com/realm/SwiftLint/main/Source/SwiftLintBuiltInRules/Rules/<Group>/<Rule>Rule.swift`.

**Screenshots and any visual check of SwiftUI.** Compose a mockup from the
real assets and the real tokens (`LuminaColors`, `LuminaSpacing`,
`LuminaRadii`) with Pillow, and label it a mockup every time it is shown.
Never present one as a screenshot.

**Anything runtime.** Write the test instead. `LuminaTests` runs on the CI
simulator, so a test is the only assertion about runtime behaviour that will
ever actually execute.

## Before saying a Swift change is done

1. Re-read the diff for API mistakes — wrong parameter labels, a type that
   doesn't exist, a property renamed. The compiler is not going to catch these
   for you here.
2. Check for name collisions: `grep -rn "struct <NewType>\|enum <NewType>" Lumina`.
3. Check the lint rules the change plausibly trips.
4. Add a test if the change has any runtime behaviour.
5. Say what is verified and what is not. "Pushed; CI's macOS job is the first
   thing that compiles it" is the honest sentence.

## When CI itself is not running

Check whether runs are even being created before assuming a green or red
result:

```
mcp__github__actions_list  method=list_workflow_runs  resource_id=ci.yml
  workflow_runs_filter={"branch": "<branch>"}
```

If the newest run predates the push, no run was created — that is an Actions
availability problem (repo Actions permissions, or an account-level
suspension), not a passing build. Report it as unverified.
