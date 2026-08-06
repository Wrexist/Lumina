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

## Reading CI from here

```
mcp__github__actions_list  method=list_workflow_runs  resource_id=ci.yml
  workflow_runs_filter={"branch": "<branch>"}         # note: the filter object,
                                                       # not a top-level `branch`
mcp__github__actions_list  method=list_workflow_jobs  resource_id=<run id>
mcp__github__get_job_logs  job_id=<id> return_content=true tail_lines=400
```

`tail_lines=400` is the number that reliably contains the Swift compile
errors; 80 shows only the tail of the warnings. Results routinely exceed the
tool's token cap and get written to a file — parse that with `python3`, don't
try to Read it.

**A missing run does not mean Actions is broken.** Runs on this repo have
appeared 20–30 minutes after the push, measured as the gap between the local
commit timestamp and the run's `created_at`. Some of that gap is clock skew —
GitHub's clock has read several minutes *ahead* of this container's — so treat
it as "expect a wait of tens of minutes", not as a calibrated number.

Checking five minutes later and concluding "Actions is blocked" is a mistake
this project has already made once, in writing, to the user. Before reporting
an outage: check whether pushes to *other* branches are producing runs, and
check `list_workflows` for a `disabled_*` state. Both were green while the
runs were merely queued.

**`workflow_dispatch` is not available to the agent** — the GitHub App token
lacks `actions: write` and returns 403. Only a human can re-run a workflow
from the Actions tab.

**Screenshots come back through the log.** The iOS job base64-encodes every
PNG in `LuminaTests/__Screenshots__` and `__AppStoreShots__` between
`===SHOT_BEGIN <name>===` / `===SHOT_END===` markers, because the artifact
storage host is blocked by this sandbox's egress rules. Strip the per-line
timestamp prefix, `base64.b64decode`, check the PNG magic bytes.

## Verification hazards in this workflow

`ci.yml` groups concurrency by **commit SHA**, deliberately. It used to group
by branch, which produced two failure modes worth recognising if the grouping
is ever changed back:

1. A burst of commits leaves only the last verified — and if that run is
   itself superseded, nothing is.
2. A commit that touches only `docs/` or `metadata/` cancels an in-flight iOS
   run, and its replacement skips the iOS job because no iOS path changed. The
   branch ends up with no iOS verification while every check reads green.

So: after a series of pushes, confirm a run actually *completed* for the head
commit. `conclusion: "cancelled"` is not a pass, and neither is a green run
whose iOS job never ran.
