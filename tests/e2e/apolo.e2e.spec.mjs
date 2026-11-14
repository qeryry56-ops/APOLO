import { test, expect } from '@playwright/test';

test.describe.configure({ mode: 'serial' });

test.beforeEach(async ({ request }) => {
  const res = await request.post('/api/v1/test/reset');
  expect(res.ok()).toBe(true);
});

test('1. Flutter Web production bundle (/) boots & intercepts prod API to isolated server', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (err) => pageErrors.push(err.message));

  // Redirect any production API call made by Flutter Web build to the local isolated test server
  await page.route('https://apolo.ma/api/v1/**', async (route) => {
    const url = new URL(route.request().url());
    const target = `http://127.0.0.1:8787${url.pathname}${url.search}`;
    const response = await route.fetch({ url: target });
    await route.fulfill({ response });
  });

  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await expect(page).toHaveTitle(/Apolo\.ma/i);
  await expect(page.locator('#apolo-splash')).toBeAttached();

  // Wait for Flutter Web engine (CanvasKit / flutter-view) to initialize or settle
  await page.waitForSelector('flutter-view, flt-glass-pane, #apolo-splash', { timeout: 25_000 });
  expect(pageErrors).toEqual([]);
});

test('2. Real browser registration + OTP (123456) + Onboarding + session persistence on /app', async ({ page }) => {
  await page.goto('/app');
  await expect(page.locator('[data-testid="ads-list"]')).toContainText('Mercedes C220 AMG 2022');

  await page.click('[data-testid="open-register-btn"]');
  await page.fill('[data-testid="reg-name"]', 'أمين بناني');
  await page.fill('[data-testid="reg-email"]', 'amine@apolo.ma');
  await page.fill('[data-testid="reg-phone"]', '0611223344');
  await page.fill('[data-testid="reg-password"]', 'Password123!');
  await page.fill('[data-testid="reg-confirmation"]', 'Password123!');
  await page.click('[data-testid="reg-submit"]');

  await expect(page.locator('[data-testid="otp-view"]')).toBeVisible();
  await expect(page.locator('[data-testid="otp-masked-email"]')).toContainText('amine@apolo.ma');

  await page.fill('[data-testid="otp-code"]', '123456');
  await page.click('[data-testid="otp-verify-btn"]');

  await expect(page.locator('[data-testid="onboarding-view"]')).toBeVisible();
  await page.selectOption('[data-testid="onboard-type"]', 'pro');
  await page.selectOption('[data-testid="onboard-city"]', '2');
  await page.check('[data-testid="onboard-cat-1"]');
  await page.click('[data-testid="onboard-submit"]');

  await expect(page.locator('[data-testid="user-greeting"]')).toBeVisible();
  await expect(page.locator('[data-testid="user-greeting"]')).toContainText('أمين بناني');

  // Verify session persists across full page reload
  await page.reload();
  await expect(page.locator('[data-testid="user-greeting"]')).toContainText('أمين بناني');
});

test('3. Login with Moroccan phone & error handling for invalid password', async ({ page }) => {
  await page.goto('/app');
  await page.click('[data-testid="open-login-btn"]');

  // Wrong password shows error box
  await page.fill('[data-testid="login-identifier"]', 'seller@apolo.ma');
  await page.fill('[data-testid="login-password"]', 'WrongPass123');
  await page.click('[data-testid="login-submit"]');
  await expect(page.locator('[data-testid="auth-error"]')).toBeVisible();

  // Valid Moroccan phone number succeeds
  await page.fill('[data-testid="login-identifier"]', '0600000001');
  await page.fill('[data-testid="login-password"]', 'Password123!');
  await page.click('[data-testid="login-submit"]');

  await expect(page.locator('[data-testid="auth-modal"]')).toBeHidden();
  await expect(page.locator('[data-testid="user-greeting"]')).toBeVisible();
});

test('4. End-to-end marketplace journey: search -> favorite -> post ad -> VIP Boost checkout -> chat', async ({ page }) => {
  await page.goto('/app');

  // Register buyer so buyer can interact with seeded seller ads & post own ad
  await page.click('[data-testid="open-register-btn"]');
  await page.fill('[data-testid="reg-name"]', 'نادية المنصوري');
  await page.fill('[data-testid="reg-email"]', 'nadia@apolo.ma');
  await page.fill('[data-testid="reg-phone"]', '0677889900');
  await page.fill('[data-testid="reg-password"]', 'Password123!');
  await page.fill('[data-testid="reg-confirmation"]', 'Password123!');
  await page.click('[data-testid="reg-submit"]');

  await page.fill('[data-testid="otp-code"]', '123456');
  await page.click('[data-testid="otp-verify-btn"]');
  await page.check('[data-testid="onboard-cat-1"]');
  await page.click('[data-testid="onboard-submit"]');
  await expect(page.locator('[data-testid="user-greeting"]')).toContainText('نادية المنصوري');

  // Search & filter
  await page.fill('[data-testid="search-query"]', 'Mercedes');
  await page.selectOption('[data-testid="filter-category"]', '1');
  await page.click('[data-testid="search-btn"]');
  await expect(page.locator('[data-testid="ad-card-1"]')).toBeVisible();

  // Reset search
  await page.fill('[data-testid="search-query"]', '');
  await page.selectOption('[data-testid="filter-category"]', '');
  await page.click('[data-testid="search-btn"]');

  // Toggle favorite on ad 1
  await page.click('[data-testid="fav-btn-1"]');
  await expect(page.locator('[data-testid="favorites-count"]')).toHaveText('1');

  // Negative price validation then valid ad creation
  await page.click('[data-testid="open-post-btn"]');
  await page.fill('[data-testid="post-title"]', 'Samsung Galaxy S24 Ultra');
  await page.fill('[data-testid="post-desc"]', 'هاتف جديد بالكرتونة');
  await page.fill('[data-testid="post-price"]', '-50');
  await page.selectOption('[data-testid="post-category"]', '3');
  await page.selectOption('[data-testid="post-city"]', '1');
  await page.click('[data-testid="post-submit"]');
  await expect(page.locator('[data-testid="post-error"]')).toBeVisible();

  await page.fill('[data-testid="post-price"]', '11500');
  await page.click('[data-testid="post-submit"]');
  await expect(page.locator('[data-testid="ads-list"]')).toContainText('Samsung Galaxy S24 Ultra');

  // VIP Boost checkout on newly created ad (id 5 after 4 seeded ads)
  await page.click('[data-testid="boost-btn-5"]');
  await expect(page.locator('[data-testid="boost-modal"]')).toBeVisible();
  await page.check('[data-testid="boost-plan-vip_7d"]');
  await page.click('[data-testid="boost-confirm-btn"]');
  await expect(page.locator('[data-testid="boost-modal"]')).toBeHidden();
  await expect(page.locator('[data-testid="vip-badge-5"]')).toBeVisible();

  // In-app chat with seller of ad 1
  await page.click('[data-testid="chat-btn-1"]');
  await expect(page.locator('[data-testid="chat-modal"]')).toBeVisible();
  await page.fill('[data-testid="chat-input"]', 'السلام عليكم، واش ممكن الثمن النهائي؟');
  await page.click('[data-testid="chat-send-btn"]');
  await expect(page.locator('[data-testid="chat-messages"]')).toContainText('السلام عليكم، واش ممكن الثمن النهائي؟');
  await page.click('[data-testid="close-chat-btn"]');
});

test('5. Logout clears session & Google Play privacy / delete-account compliance pages work', async ({ page }) => {
  await page.goto('/app');
  await page.click('[data-testid="open-login-btn"]');
  await page.fill('[data-testid="login-identifier"]', 'seller@apolo.ma');
  await page.fill('[data-testid="login-password"]', 'Password123!');
  await page.click('[data-testid="login-submit"]');
  await expect(page.locator('[data-testid="user-greeting"]')).toBeVisible();

  // Logout
  await page.click('[data-testid="logout-btn"]');
  await expect(page.locator('[data-testid="open-login-btn"]')).toBeVisible();
  await expect(page.locator('[data-testid="user-greeting"]')).toBeHidden();

  // Privacy page + link to delete account
  await page.goto('/privacy.html');
  await expect(page.locator('h1')).toContainText('سياسة الخصوصية');
  await expect(page.locator('a[href="/delete-account.html"]')).toBeVisible();

  // Delete account submission
  await page.goto('/delete-account.html');
  await page.fill('#ident', 'seller@apolo.ma');
  await page.selectOption('#dtype', 'full');
  await page.click('#delForm button[type="submit"]');
  await expect(page.locator('#msg')).toBeVisible();
});
