Run a full Lumina build against the iPhone 16 Pro simulator and report errors.

```bash
xcodebuild \
  -scheme Lumina \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -skipPackagePluginValidation \
  build 2>&1 | xcpretty
```

If xcpretty is not installed, run the raw xcodebuild command without piping.
Report: build succeeded / failed, and list any errors or warnings.
