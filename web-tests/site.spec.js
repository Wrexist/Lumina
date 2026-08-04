// Playwright checks for the three pages Apple actually loads: the marketing
// page, the Privacy Policy URL and the Support URL. A 404 or a dead link on
// the latter two is a submission rejection, so these are launch-blocking.
const { test, expect } = require('@playwright/test');

const PAGES = [
  { path: '/index.html', name: 'index' },
  { path: '/privacy.html', name: 'privacy' },
  { path: '/support.html', name: 'support' },
];

for (const page_ of PAGES) {
  test.describe(page_.name, () => {
    test('loads with no console errors or failed requests', async ({ page }) => {
      const consoleErrors = [];
      const failedRequests = [];
      page.on('console', (m) => m.type() === 'error' && consoleErrors.push(m.text()));
      page.on('pageerror', (e) => consoleErrors.push(String(e)));
      page.on('requestfailed', (r) => failedRequests.push(`${r.url()} — ${r.failure()?.errorText}`));

      const response = await page.goto(page_.path, { waitUntil: 'networkidle' });
      expect(response.status(), 'HTTP status').toBe(200);
      expect(consoleErrors, 'console errors').toEqual([]);
      expect(failedRequests, 'failed subresource requests').toEqual([]);
    });

    test('has a title, one h1, and no empty headings', async ({ page }) => {
      await page.goto(page_.path);
      expect((await page.title()).trim().length, 'non-empty <title>').toBeGreaterThan(0);
      await expect(page.locator('h1')).toHaveCount(1);
      const headings = await page.locator('h1, h2, h3').allTextContents();
      expect(headings.filter((h) => !h.trim()), 'empty headings').toEqual([]);
    });

    test('every internal link resolves', async ({ page, request, baseURL }) => {
      await page.goto(page_.path);
      const hrefs = await page.locator('a[href]').evaluateAll((els) =>
        els.map((e) => e.getAttribute('href')).filter((h) => h && !h.startsWith('#'))
      );
      const broken = [];
      for (const href of new Set(hrefs)) {
        if (href.startsWith('mailto:') || href.startsWith('tel:')) continue;
        if (/^https?:\/\//.test(href)) continue; // external — checked separately
        const res = await request.get(new URL(href, baseURL + page_.path).toString());
        if (!res.ok()) broken.push(`${href} → ${res.status()}`);
      }
      expect(broken, 'broken internal links').toEqual([]);
    });

    test('no horizontal scroll at 390px (iPhone width)', async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 });
      await page.goto(page_.path);
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth
      );
      expect(overflow, 'horizontal overflow in px').toBeLessThanOrEqual(1);
    });

    test('body text meets the 13pt charter floor', async ({ page }) => {
      await page.goto(page_.path);
      const tooSmall = await page.evaluate(() => {
        const out = [];
        for (const el of document.querySelectorAll('p, li, td')) {
          if (!el.textContent.trim()) continue;
          const size = parseFloat(getComputedStyle(el).fontSize);
          if (size < 13) out.push(`${el.tagName}: ${size}px — ${el.textContent.trim().slice(0, 40)}`);
        }
        return out;
      });
      expect(tooSmall, 'text below 13px').toEqual([]);
    });
  });
}

// The two claims Apple checks the pages *for*, not just that they render.
test('privacy page names a contact route and a deletion path', async ({ page }) => {
  await page.goto('/privacy.html');
  const text = (await page.locator('body').innerText()).toLowerCase();
  expect(text, 'a contact address').toMatch(/@|contact/);
  expect(text, 'account deletion').toMatch(/delet/);
});

test('support page offers a way to reach a human', async ({ page }) => {
  await page.goto('/support.html');
  const mailto = await page.locator('a[href^="mailto:"]').count();
  const text = (await page.locator('body').innerText()).toLowerCase();
  expect(mailto > 0 || /@/.test(text), 'a reachable contact').toBeTruthy();
});
