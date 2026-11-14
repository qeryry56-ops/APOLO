import fs from 'node:fs';
import { defineConfig } from '@playwright/test';

function detectLocalBrowserExecutable() {
  if (process.env.CI || process.platform !== 'win32') return undefined;
  const candidates = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  ];
  return candidates.find((p) => fs.existsSync(p));
}

const executablePath = detectLocalBrowserExecutable();

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  timeout: 45_000,
  reporter: [['list']],
  use: {
    baseURL: 'http://127.0.0.1:8787',
    headless: true,
    viewport: { width: 1280, height: 800 },
    screenshot: 'only-on-failure',
    launchOptions: executablePath ? { executablePath } : {},
  },
  webServer: {
    command: 'node tests/server/start_server.mjs',
    url: 'http://127.0.0.1:8787/api/v1/taxonomy',
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
    env: {
      APOLO_TEST_PORT: '8787',
      APOLO_TEST_HOST: '127.0.0.1',
    },
  },
});
