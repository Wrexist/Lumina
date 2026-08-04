// Playwright checks for the pages in `docs/`, which GitHub Pages serves as the
// Marketing, Privacy Policy and Support URLs in App Store Connect. A 404 or a
// dead link on the latter two is a submission rejection, so these are
// launch-blocking rather than cosmetic.
//
//   cd web-tests && npm install && npx playwright test
//
// Browser resolution, in order:
//   1. `PLAYWRIGHT_CHROMIUM_PATH` — an explicit binary. Needed when the host
//      pre-installs Chromium at a build number this @playwright/test version
//      doesn't expect, which is the common case in CI images and sandboxes.
//   2. Playwright's own download (`npx playwright install chromium`).
const path = require("path");

const chromium = process.env.PLAYWRIGHT_CHROMIUM_PATH;

module.exports = {
  testDir: __dirname,
  timeout: 30000,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:8099",
    ...(chromium ? { launchOptions: { executablePath: chromium } } : {}),
  },
  webServer: {
    command: `python3 -m http.server 8099 --directory ${path.join(__dirname, "..", "docs")}`,
    url: "http://127.0.0.1:8099/index.html",
    reuseExistingServer: true,
    timeout: 20000,
  },
};
