# Screenshots for `fastlane deliver`

Leave this directory empty in git — the images are generated, and committing
them would rot the moment any surface changes.

Before uploading, drop the CI-rendered set here:

```sh
# GitHub → Actions → latest green `ci` run → Artifacts → app-store-screenshots
unzip ~/Downloads/app-store-screenshots.zip -d fastlane/screenshots/en-US/
```

`deliver` reads them from `fastlane/screenshots/<locale>/` and matches them to
device sizes by their pixel dimensions — 1320 × 2868 is the 6.9" slot, which
Apple scales down for every smaller iPhone. `AppStoreShotTests` asserts those
exact dimensions, so a file that lands here is already the right size.

Five of the six storyboard frames are generated (`01-today`,
`02-birth-chart`, `03-synastry`, `04-human-design`, `05-reflect`). The 3D moon
is SceneKit and needs a hand capture — see `docs/aso/SCREENSHOTS.md`.
