Run the full Lumina test suite against the iPhone 16 Pro simulator.

```bash
xcodebuild test \
  -scheme LuminaTests \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  2>&1 | xcpretty
```

Report:
- Total tests run / passed / failed
- Any failing test names and assertion messages
- Any crashes or timeouts

If tests don't exist yet (bootstrap phase), confirm with: `find . -name "*Tests.swift" -not -path "*/.git/*"`
