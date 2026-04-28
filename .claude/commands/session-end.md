Run the end-of-session checklist for Lumina.

Steps to execute in order:

1. **Check for uncommitted work**
   ```bash
   git status
   git diff --stat
   ```

2. **Run lint** (zero warnings required)
   ```bash
   swiftlint lint --strict
   ```

3. **Check for secrets accidentally staged**
   ```bash
   git status --short | grep -E '\.(env|xcconfig|pem|key|p12|cer)'
   ```

4. **Update TASK.md** — mark completed tasks `[x]`, update in-progress `[~]`, add new blockers

5. **Update LEARNINGS.md** — append any new gotchas, decisions, or patterns with today's date `[2026-04]`

6. **Commit and push to feature branch** (NEVER main)
   ```bash
   git push -u origin claude/optimize-config-setup-xfpK1
   ```

Report the final git log of what was pushed.
