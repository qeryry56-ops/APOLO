import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(__dirname, '../..');
const targetSubdir = process.argv[2] || 'tests/unit';

const vitestBin = path.join(
  ROOT_DIR,
  'node_modules',
  '.bin',
  process.platform === 'win32' ? 'vitest.cmd' : 'vitest'
);

if (fs.existsSync(vitestBin)) {
  const res = spawnSync(vitestBin, ['run', targetSubdir], {
    cwd: ROOT_DIR,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  process.exit(res.status ?? 1);
}

const absTarget = path.resolve(ROOT_DIR, targetSubdir);
const testFiles = [];
function collectTests(dir) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) collectTests(full);
    else if (entry.name.endsWith('.test.mjs') || entry.name.endsWith('.test.js')) {
      testFiles.push(full);
    }
  }
}
collectTests(absTarget);

if (testFiles.length === 0) {
  console.error(`No test files found in ${absTarget}`);
  process.exit(1);
}

console.log(`Running ${targetSubdir} via Node.js v${process.versions.node} native test runner (vitest compatibility bridge)...`);
const res = spawnSync(process.execPath, ['--test', '--test-reporter=spec', ...testFiles], {
  cwd: ROOT_DIR,
  stdio: 'inherit',
});
process.exit(res.status ?? 1);
