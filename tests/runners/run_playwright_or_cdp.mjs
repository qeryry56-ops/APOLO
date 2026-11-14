import fs from 'node:fs';
import net from 'node:net';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createApoloTestServer } from '../server/test_api_server.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(__dirname, '../..');

const playwrightBin = path.join(
  ROOT_DIR,
  'node_modules',
  '.bin',
  process.platform === 'win32' ? 'playwright.cmd' : 'playwright'
);

if (fs.existsSync(playwrightBin)) {
  const res = spawnSync(playwrightBin, ['test'], {
    cwd: ROOT_DIR,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  process.exit(res.status ?? 1);
}

function findBrowserExecutable() {
  const candidates =
    process.platform === 'win32'
      ? [
          'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
          'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
          'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
          'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
        ]
      : [
          '/usr/bin/google-chrome',
          '/usr/bin/chromium',
          '/usr/bin/chromium-browser',
        ];
  return candidates.find((p) => fs.existsSync(p));
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

class CdpClient {
  constructor(wsUrl) {
    this.ws = new WebSocket(wsUrl);
    this.nextId = 1;
    this.pending = new Map();
    this.listeners = new Map();
    this.ready = new Promise((resolve, reject) => {
      this.ws.addEventListener('open', () => resolve(), { once: true });
      this.ws.addEventListener('error', (err) => reject(err.error || new Error('CDP WebSocket error')), {
        once: true,
      });
    });
    this.ws.addEventListener('message', (event) => {
      const msg = JSON.parse(String(event.data));
      if (msg.id) {
        const entry = this.pending.get(msg.id);
        if (entry) {
          this.pending.delete(msg.id);
          if (msg.error) entry.reject(new Error(`CDP ${entry.method}: ${msg.error.message}`));
          else entry.resolve(msg.result || {});
        }
      } else if (msg.method) {
        const fns = this.listeners.get(msg.method) || [];
        for (const fn of fns) fn(msg.params || {}, msg.sessionId || null);
      }
    });
  }

  on(method, fn) {
    if (!this.listeners.has(method)) this.listeners.set(method, []);
    this.listeners.get(method).push(fn);
  }

  async send(method, params = {}, sessionId = null) {
    await this.ready;
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject, method });
      const payload = { id, method, params };
      if (sessionId) payload.sessionId = sessionId;
      this.ws.send(JSON.stringify(payload));
    });
  }

  async close() {
    try {
      this.ws.close();
    } catch (_) {}
  }
}

class BrowserPage {
  constructor(cdp, baseUrl) {
    this.cdp = cdp;
    this.baseUrl = baseUrl;
    this.pageErrors = [];
    this.sessionId = null;
  }

  pageSend(method, params = {}) {
    return this.cdp.send(method, params, this.sessionId);
  }

  async init() {
    const { targetId } = await this.cdp.send('Target.createTarget', { url: 'about:blank' });
    const { sessionId } = await this.cdp.send('Target.attachToTarget', {
      targetId,
      flatten: true,
    });
    this.sessionId = sessionId;

    await this.pageSend('Page.enable');
    await this.pageSend('Runtime.enable');
    await this.pageSend('Fetch.enable', {
      patterns: [{ urlPattern: 'https://apolo.ma/api/v1/*' }, { urlPattern: '*' }],
    });

    this.cdp.on('Runtime.exceptionThrown', (params, sid) => {
      if (sid && sid !== this.sessionId) return;
      const text =
        params?.exceptionDetails?.exception?.description ||
        params?.exceptionDetails?.text ||
        'Unknown JS error';
      this.pageErrors.push(text);
    });

    this.cdp.on('Fetch.requestPaused', async (params, sid) => {
      if (sid && sid !== this.sessionId) return;
      const urlStr = params.request?.url || '';
      if (urlStr.startsWith('https://apolo.ma/api/v1/')) {
        try {
          const parsed = new URL(urlStr);
          const localUrl = `${this.baseUrl}${parsed.pathname}${parsed.search}`;
          const res = await fetch(localUrl, {
            method: params.request.method || 'GET',
            headers: params.request.headers || {},
            body: params.request.postData || undefined,
          });
          const buf = Buffer.from(await res.arrayBuffer());
          const headers = [];
          res.headers.forEach((value, name) => {
            headers.push({ name, value });
          });
          await this.pageSend('Fetch.fulfillRequest', {
            requestId: params.requestId,
            responseCode: res.status,
            responseHeaders: headers,
            body: buf.toString('base64'),
          });
        } catch (_) {
          await this.pageSend('Fetch.abortRequest', {
            requestId: params.requestId,
            errorReason: 'Failed',
          }).catch(() => {});
        }
        return;
      }

      // Abort external requests if offline so pages don't stall waiting for remote CDNs
      if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
        if (!urlStr.startsWith(this.baseUrl) && !urlStr.startsWith('http://127.0.0.1') && !urlStr.startsWith('http://localhost')) {
          await this.pageSend('Fetch.abortRequest', {
            requestId: params.requestId,
            errorReason: 'BlockedByClient',
          }).catch(() => {});
          return;
        }
      }

      await this.pageSend('Fetch.continueRequest', { requestId: params.requestId }).catch(() => {});
    });
  }

  async eval(fnOrExpr) {
    const expression =
      typeof fnOrExpr === 'function' ? `(${fnOrExpr.toString()})()` : String(fnOrExpr);
    const res = await this.pageSend('Runtime.evaluate', {
      expression,
      returnByValue: true,
      awaitPromise: true,
    });
    if (res.exceptionDetails) {
      throw new Error(
        res.exceptionDetails.exception?.description ||
          res.exceptionDetails.text ||
          'Runtime evaluation error'
      );
    }
    return res.result?.value;
  }

  async goto(routePath) {
    const targetUrl = routePath.startsWith('http') ? routePath : `${this.baseUrl}${routePath}`;
    await this.pageSend('Page.navigate', { url: targetUrl });
    const deadline = Date.now() + 15_000;
    while (Date.now() < deadline) {
      const ready = await this.eval(() => document.readyState).catch(() => '');
      const href = await this.eval(() => location.href).catch(() => '');
      if ((ready === 'interactive' || ready === 'complete') && href.startsWith('http')) {
        break;
      }
      await sleep(80);
    }
    await sleep(250);
  }

  async clearStorage() {
    await this.eval(() => {
      try {
        localStorage.clear();
        sessionStorage.clear();
      } catch (_) {}
    }).catch(() => {});
  }

  async reload() {
    await this.pageSend('Page.reload', { ignoreCache: true });
    await sleep(500);
  }

  async waitFor(selector, { visible = true, timeoutMs = 15_000 } = {}) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      const ok = await this.eval(
        `(() => {
          const el = document.querySelector(${JSON.stringify(selector)});
          if (!el) return false;
          if (!${JSON.stringify(visible)}) return true;
          const style = getComputedStyle(el);
          if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return false;
          return el.getClientRects().length > 0;
        })()`
      );
      if (ok) return;
      await sleep(80);
    }
    throw new Error(`Timed out waiting for selector (${visible ? 'visible' : 'attached'}): ${selector}`);
  }

  async waitHidden(selector, timeoutMs = 10_000) {
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      const hidden = await this.eval(
        `(() => {
          const el = document.querySelector(${JSON.stringify(selector)});
          if (!el) return true;
          const style = getComputedStyle(el);
          return style.display === 'none' || style.visibility === 'hidden' || el.getClientRects().length === 0;
        })()`
      );
      if (hidden) return;
      await sleep(80);
    }
    throw new Error(`Timed out waiting for selector to hide: ${selector}`);
  }

  async waitText(selector, expected, timeoutMs = 12_000) {
    const deadline = Date.now() + timeoutMs;
    let lastText = '';
    while (Date.now() < deadline) {
      lastText = await this.eval(
        `(() => {
          const el = document.querySelector(${JSON.stringify(selector)});
          return el ? (el.textContent || '') : '';
        })()`
      );
      if (lastText.includes(expected)) return lastText;
      await sleep(80);
    }
    throw new Error(`Expected "${selector}" to contain "${expected}", got "${lastText.trim()}"`);
  }

  async click(selector) {
    await this.waitFor(selector);
    await this.eval(
      `(() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        el.scrollIntoView({ block: 'center' });
        el.click();
      })()`
    );
  }

  async fill(selector, value) {
    await this.waitFor(selector);
    await this.eval(
      `(() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        el.focus();
        el.value = ${JSON.stringify(String(value))};
        el.dispatchEvent(new Event('input', { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
      })()`
    );
  }

  async selectOption(selector, value) {
    await this.waitFor(selector);
    await this.eval(
      `(() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        el.value = ${JSON.stringify(String(value))};
        el.dispatchEvent(new Event('change', { bubbles: true }));
      })()`
    );
  }

  async check(selector) {
    await this.waitFor(selector);
    await this.eval(
      `(() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        if (!el.checked) el.click();
      })()`
    );
  }

  async title() {
    return this.eval(() => document.title);
  }
}

function getFreePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.unref();
    srv.on('error', reject);
    srv.listen(0, '127.0.0.1', () => {
      const addr = srv.address();
      const port = typeof addr === 'object' ? addr.port : 19225;
      srv.close(() => resolve(port));
    });
  });
}

async function launchChrome(browserExe, userDataDir) {
  const debugPort = await getFreePort();
  const args = [
    '--headless=new',
    '--disable-gpu',
    '--no-first-run',
    '--no-default-browser-checking',
    `--remote-debugging-port=${debugPort}`,
    '--remote-allow-origins=*',
    `--user-data-dir=${userDataDir}`,
    '--window-size=1280,800',
    'about:blank',
  ];
  const proc = spawn(browserExe, args, { stdio: ['ignore', 'pipe', 'pipe'] });

  const wsUrl = await new Promise((resolve, reject) => {
    let stderr = '';
    const timer = setTimeout(() => {
      clearInterval(checkDevToolsPortFile);
      reject(new Error(`Timed out starting headless browser (${browserExe}): ${stderr}`));
    }, 15_000);

    const checkDevToolsPortFile = setInterval(() => {
      const portFile = path.join(userDataDir, 'DevToolsActivePort');
      if (fs.existsSync(portFile)) {
        const lines = fs.readFileSync(portFile, 'utf8').split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
        if (lines.length >= 2 && Number(lines[0]) > 0) {
          clearTimeout(timer);
          clearInterval(checkDevToolsPortFile);
          resolve(`ws://127.0.0.1:${lines[0]}${lines[1]}`);
        }
      }
    }, 100);

    proc.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
      const match = stderr.match(/DevTools listening on (ws:\/\/[^\s\r\n]+)/);
      if (match) {
        clearTimeout(timer);
        clearInterval(checkDevToolsPortFile);
        resolve(match[1]);
      }
    });

    proc.once('exit', (code) => {
      clearTimeout(timer);
      clearInterval(checkDevToolsPortFile);
      reject(new Error(`Browser exited early with code ${code}: ${stderr}`));
    });
  });

  return { proc, wsUrl };
}

async function main() {
  const browserExe = findBrowserExecutable();
  if (!browserExe) {
    throw new Error('Playwright is not installed and no Chrome/Edge browser was found.');
  }

  console.log(`Running Apolo.ma E2E browser suite in real headless Chrome (${browserExe}) via CDP...`);
  const srv = createApoloTestServer({ dbPath: ':memory:' });
  const { baseUrl } = await srv.start(0, '127.0.0.1');
  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'apolo-cdp-'));

  let proc;
  let cdp;
  let failed = 0;

  try {
    const launched = await launchChrome(browserExe, userDataDir);
    proc = launched.proc;
    cdp = new CdpClient(launched.wsUrl);
    const page = new BrowserPage(cdp, baseUrl);
    await page.init();

    const tests = [
      {
        name: '1. Flutter Web production bundle (/) boots & intercepts prod API to isolated server',
        async fn() {
          page.pageErrors = [];
          await page.goto('/');
          const title = await page.title();
          assert.match(title, /Apolo\.ma/i);
          await page.waitFor('flutter-view, flt-glass-pane, #apolo-splash', {
            visible: false,
            timeoutMs: 15_000,
          });
          assert.deepEqual(page.pageErrors, [], `Unexpected page errors: ${page.pageErrors.join('; ')}`);
        },
      },
      {
        name: '2. Real browser registration + OTP (123456) + Onboarding + session persistence on /app',
        async fn() {
          await page.goto('/app');
          await page.clearStorage();
          await page.reload();
          await page.waitText('[data-testid="ads-list"]', 'Mercedes C220 AMG 2022');

          await page.click('[data-testid="open-register-btn"]');
          await page.fill('[data-testid="reg-name"]', 'أمين بناني');
          await page.fill('[data-testid="reg-email"]', 'amine@apolo.ma');
          await page.fill('[data-testid="reg-phone"]', '0611223344');
          await page.fill('[data-testid="reg-password"]', 'Password123!');
          await page.fill('[data-testid="reg-confirmation"]', 'Password123!');
          await page.click('[data-testid="reg-submit"]');

          await page.waitFor('[data-testid="otp-view"]');
          await page.waitText('[data-testid="otp-masked-email"]', 'amine@apolo.ma');
          await page.fill('[data-testid="otp-code"]', '123456');
          await page.click('[data-testid="otp-verify-btn"]');

          await page.waitFor('[data-testid="onboarding-view"]');
          await page.selectOption('[data-testid="onboard-type"]', 'pro');
          await page.selectOption('[data-testid="onboard-city"]', '2');
          await page.check('[data-testid="onboard-cat-1"]');
          await page.click('[data-testid="onboard-submit"]');

          await page.waitFor('[data-testid="user-greeting"]');
          await page.waitText('[data-testid="user-greeting"]', 'أمين بناني');

          await page.reload();
          await page.waitText('[data-testid="user-greeting"]', 'أمين بناني');
        },
      },
      {
        name: '3. Login with Moroccan phone & error handling for invalid password',
        async fn() {
          await page.goto('/app');
          await page.clearStorage();
          await page.reload();
          await page.click('[data-testid="open-login-btn"]');

          await page.fill('[data-testid="login-identifier"]', 'seller@apolo.ma');
          await page.fill('[data-testid="login-password"]', 'WrongPass123');
          await page.click('[data-testid="login-submit"]');
          await page.waitFor('[data-testid="auth-error"]');

          await page.fill('[data-testid="login-identifier"]', '0600000001');
          await page.fill('[data-testid="login-password"]', 'Password123!');
          await page.click('[data-testid="login-submit"]');
          await page.waitHidden('[data-testid="auth-modal"]');
          await page.waitFor('[data-testid="user-greeting"]');
        },
      },
      {
        name: '4. End-to-end marketplace journey: search -> favorite -> post ad -> VIP Boost checkout -> chat',
        async fn() {
          await page.goto('/app');
          await page.clearStorage();
          await page.reload();

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
          await page.waitText('[data-testid="user-greeting"]', 'نادية المنصوري');

          await page.fill('[data-testid="search-query"]', 'Mercedes');
          await page.selectOption('[data-testid="filter-category"]', '1');
          await page.click('[data-testid="search-btn"]');
          await page.waitFor('[data-testid="ad-card-1"]');

          await page.fill('[data-testid="search-query"]', '');
          await page.selectOption('[data-testid="filter-category"]', '');
          await page.click('[data-testid="search-btn"]');

          await page.click('[data-testid="fav-btn-1"]');
          await page.waitText('[data-testid="favorites-count"]', '1');

          await page.click('[data-testid="open-post-btn"]');
          await page.fill('[data-testid="post-title"]', 'Samsung Galaxy S24 Ultra');
          await page.fill('[data-testid="post-desc"]', 'هاتف جديد بالكرتونة');
          await page.fill('[data-testid="post-price"]', '-50');
          await page.selectOption('[data-testid="post-category"]', '3');
          await page.selectOption('[data-testid="post-city"]', '1');
          await page.click('[data-testid="post-submit"]');
          await page.waitFor('[data-testid="post-error"]');

          await page.fill('[data-testid="post-price"]', '11500');
          await page.click('[data-testid="post-submit"]');
          await page.waitText('[data-testid="ads-list"]', 'Samsung Galaxy S24 Ultra');

          await page.click('[data-testid="boost-btn-5"]');
          await page.waitFor('[data-testid="boost-modal"]');
          await page.check('[data-testid="boost-plan-vip_7d"]');
          await page.click('[data-testid="boost-confirm-btn"]');
          await page.waitHidden('[data-testid="boost-modal"]');
          await page.waitFor('[data-testid="vip-badge-5"]');

          await page.click('[data-testid="chat-btn-1"]');
          await page.waitFor('[data-testid="chat-modal"]');
          await page.fill('[data-testid="chat-input"]', 'السلام عليكم، واش ممكن الثمن النهائي؟');
          await page.click('[data-testid="chat-send-btn"]');
          await page.waitText('[data-testid="chat-messages"]', 'السلام عليكم، واش ممكن الثمن النهائي؟');
          await page.click('[data-testid="close-chat-btn"]');
        },
      },
      {
        name: '5. Logout clears session & Google Play privacy / delete-account compliance pages work',
        async fn() {
          await page.goto('/app');
          await page.clearStorage();
          await page.reload();
          await page.click('[data-testid="open-login-btn"]');
          await page.fill('[data-testid="login-identifier"]', 'seller@apolo.ma');
          await page.fill('[data-testid="login-password"]', 'Password123!');
          await page.click('[data-testid="login-submit"]');
          await page.waitFor('[data-testid="user-greeting"]');

          await page.click('[data-testid="logout-btn"]');
          await page.waitFor('[data-testid="open-login-btn"]');
          await page.waitHidden('[data-testid="user-greeting"]');

          await page.goto('/privacy.html');
          await page.waitText('h1', 'سياسة الخصوصية');
          await page.waitFor('a[href="/delete-account.html"]');

          await page.goto('/delete-account.html');
          await page.fill('#ident', 'seller@apolo.ma');
          await page.selectOption('#dtype', 'full');
          await page.click('#delForm button[type="submit"]');
          await page.waitFor('#msg');
        },
      },
    ];

    let passed = 0;
    for (const tc of tests) {
      const resetRes = await fetch(`${baseUrl}/api/v1/test/reset`, { method: 'POST' });
      assert.strictEqual(resetRes.status, 200);
      const t0 = Date.now();
      try {
        await tc.fn();
        passed++;
        console.log(`PASS  ${tc.name} (${Date.now() - t0}ms)`);
      } catch (err) {
        failed++;
        console.error(`FAIL  ${tc.name} (${Date.now() - t0}ms)\n      ${err?.stack || err}`);
      }
    }

    console.log(`\nE2E Browser Summary: ${passed} passed, ${failed} failed out of ${tests.length} tests.`);
    if (failed > 0) process.exitCode = 1;
  } finally {
    if (cdp) await cdp.close();
    if (proc) {
      try {
        proc.kill('SIGTERM');
      } catch (_) {}
    }
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
    } catch (_) {}
    await srv.stop();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
