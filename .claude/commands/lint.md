Run SwiftLint in strict mode across the Lumina source tree and report all violations.

```bash
swiftlint lint --strict
```

Zero warnings is the policy. If violations are found:
1. List each violation with file, line, and rule name
2. Fix all auto-correctable violations with `swiftlint --fix`
3. Manually fix remaining violations
4. Re-run to confirm clean output before committing
