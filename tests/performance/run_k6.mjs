import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createApoloTestServer } from '../server/test_api_server.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(__dirname, '../..');
const BIN_DIR = path.resolve(__dirname, '../bin');
const K6_LOCAL_BIN = path.join(BIN_DIR, process.platform === 'win32' ? 'k6.exe' : 'k6');
const K6_SCRIPT = path.join(__dirname, 'k6_load_test.js');
const SUMMARY_PATH = path.join(__dirname, 'k6_summary.json');

function findExistingK6() {
  const cmd = process.platform === 'win32' ? 'k6.exe' : 'k6';
  const probe = spawnSync(cmd, ['version'], { stdio: 'ignore' });
  if (probe.status === 0) return cmd;
  if (fs.existsSync(K6_LOCAL_BIN)) return K6_LOCAL_BIN;
  return null;
}

async function tryEnsureK6Binary() {
  const existing = findExistingK6();
  if (existing) return existing;
  if (process.platform !== 'win32') return null;

  fs.mkdirSync(BIN_DIR, { recursive: true });
  const zipPath = path.join(BIN_DIR, 'k6-v0.54.0-windows-amd64.zip');
  const url = 'https://github.com/grafana/k6/releases/download/v0.54.0/k6-v0.54.0-windows-amd64.zip';
  console.log(`Checking official k6 v0.54.0 download (${url}) with 6s timeout...`);

  try {
    const res = await fetch(url, { redirect: 'follow', signal: AbortSignal.timeout(6000) });
    if (!res.ok) return null;
    const buf = Buffer.from(await res.arrayBuffer());
    fs.writeFileSync(zipPath, buf);

    const extractDir = path.join(BIN_DIR, '_extract');
    if (fs.existsSync(extractDir)) fs.rmSync(extractDir, { recursive: true, force: true });
    execFileSync(
      'powershell',
      ['-NoProfile', '-Command', `Expand-Archive -Path '${zipPath}' -DestinationPath '${extractDir}' -Force`],
      { stdio: 'inherit' }
    );

    const extractedExe = path.join(extractDir, 'k6-v0.54.0-windows-amd64', 'k6.exe');
    if (!fs.existsSync(extractedExe)) return null;
    fs.copyFileSync(extractedExe, K6_LOCAL_BIN);
    fs.rmSync(extractDir, { recursive: true, force: true });
    fs.rmSync(zipPath, { force: true });
    console.log(`k6 ready at ${K6_LOCAL_BIN}`);
    return K6_LOCAL_BIN;
  } catch (err) {
    console.log(`k6 binary unavailable offline (${err.message}). Using built-in Node.js progressive VU load engine mirroring k6_load_test.js...`);
    try { fs.rmSync(zipPath, { force: true }); } catch (_) {}
    return null;
  }
}

function summarizeDurations(samples) {
  if (!samples.length) {
    return { count: 0, avg: 0, min: 0, med: 0, 'p(90)': 0, 'p(95)': 0, max: 0 };
  }
  const sorted = [...samples].sort((a, b) => a - b);
  const sum = sorted.reduce((acc, v) => acc + v, 0);
  const pct = (p) => sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))];
  return {
    count: sorted.length,
    avg: Number((sum / sorted.length).toFixed(2)),
    min: Number(sorted[0].toFixed(2)),
    med: Number(pct(50).toFixed(2)),
    'p(90)': Number(pct(90).toFixed(2)),
    'p(95)': Number(pct(95).toFixed(2)),
    max: Number(sorted[sorted.length - 1].toFixed(2)),
  };
}

async function timedRequest(url, init = {}) {
  const start = performance.now();
  try {
    const res = await fetch(url, init);
    const text = await res.text();
    const duration = performance.now() - start;
    return { ok: res.ok, status: res.status, duration, text };
  } catch (_) {
    return { ok: false, status: 0, duration: performance.now() - start, text: '' };
  }
}

async function runProgressiveNodeBenchmark(baseUrl) {
  const stages = [
    { name: 'Stage 1 (10 VUs / 5s)', targetVus: 10, durationMs: 5000 },
    { name: 'Stage 2 (30 VUs / 8s)', targetVus: 30, durationMs: 8000 },
    { name: 'Stage 3 (60 VUs / 8s)', targetVus: 60, durationMs: 8000 },
    { name: 'Stage 4 (100 VUs / 8s)', targetVus: 100, durationMs: 8000 },
    { name: 'Stage 5 (Cooldown 5 VUs / 3s)', targetVus: 5, durationMs: 3000 },
  ];

  const allDurations = [];
  const endpointBuckets = {
    apolo_webapp_ms: [],
    apolo_app_shell_ms: [],
    apolo_home_ms: [],
    apolo_taxonomy_ms: [],
    apolo_ads_list_ms: [],
    apolo_ad_detail_ms: [],
    apolo_login_ms: [],
    apolo_create_ad_ms: [],
  };
  let totalReqs = 0;
  let failedReqs = 0;
  let iterCounter = 0;
  const stageReports = [];

  for (const stage of stages) {
    const stageDurations = [];
    let stageReqs = 0;
    let stageFails = 0;
    const stageEnd = Date.now() + stage.durationMs;

    const vuWorkers = Array.from({ length: stage.targetVus }, (_, vuIdx) =>
      (async () => {
        while (Date.now() < stageEnd) {
          const iter = ++iterCounter;

          const rWeb = await timedRequest(`${baseUrl}/`);
          allDurations.push(rWeb.duration);
          stageDurations.push(rWeb.duration);
          endpointBuckets.apolo_webapp_ms.push(rWeb.duration);
          totalReqs++; stageReqs++;
          if (rWeb.status !== 200) { failedReqs++; stageFails++; }

          const rApp = await timedRequest(`${baseUrl}/app`);
          allDurations.push(rApp.duration);
          stageDurations.push(rApp.duration);
          endpointBuckets.apolo_app_shell_ms.push(rApp.duration);
          totalReqs++; stageReqs++;
          if (rApp.status !== 200) { failedReqs++; stageFails++; }

          const rHome = await timedRequest(`${baseUrl}/api/v1/home`);
          allDurations.push(rHome.duration);
          stageDurations.push(rHome.duration);
          endpointBuckets.apolo_home_ms.push(rHome.duration);
          totalReqs++; stageReqs++;
          if (rHome.status !== 200) { failedReqs++; stageFails++; }

          const rTax = await timedRequest(`${baseUrl}/api/v1/taxonomy`);
          allDurations.push(rTax.duration);
          stageDurations.push(rTax.duration);
          endpointBuckets.apolo_taxonomy_ms.push(rTax.duration);
          totalReqs++; stageReqs++;
          if (rTax.status !== 200) { failedReqs++; stageFails++; }

          const rAds = await timedRequest(`${baseUrl}/api/v1/ads?category_id=1&city_id=1`);
          allDurations.push(rAds.duration);
          stageDurations.push(rAds.duration);
          endpointBuckets.apolo_ads_list_ms.push(rAds.duration);
          totalReqs++; stageReqs++;
          if (rAds.status !== 200) { failedReqs++; stageFails++; }

          const rDetail = await timedRequest(`${baseUrl}/api/v1/ads/1`);
          allDurations.push(rDetail.duration);
          stageDurations.push(rDetail.duration);
          endpointBuckets.apolo_ad_detail_ms.push(rDetail.duration);
          totalReqs++; stageReqs++;
          if (rDetail.status !== 200) { failedReqs++; stageFails++; }

          const rLogin = await timedRequest(`${baseUrl}/api/v1/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ login: 'seller@apolo.ma', password: 'Password123!' }),
          });
          allDurations.push(rLogin.duration);
          stageDurations.push(rLogin.duration);
          endpointBuckets.apolo_login_ms.push(rLogin.duration);
          totalReqs++; stageReqs++;
          if (rLogin.status !== 200) { failedReqs++; stageFails++; }

          let token = null;
          try {
            token = JSON.parse(rLogin.text)?.token;
          } catch (_) {}
          if (token) {
            const rCreate = await timedRequest(`${baseUrl}/api/v1/ads`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token}`,
              },
              body: JSON.stringify({
                title: `إعلان ضغط #${vuIdx + 1}-${iter}`,
                description: 'اختبار ضغط الأداء تحت حمل متزايد',
                price: 2500,
                category_id: 3,
                city_id: 1,
                phone_call: '0612345678',
              }),
            });
            allDurations.push(rCreate.duration);
            stageDurations.push(rCreate.duration);
            endpointBuckets.apolo_create_ad_ms.push(rCreate.duration);
            totalReqs++; stageReqs++;
            if (rCreate.status !== 201) { failedReqs++; stageFails++; }
          }

          await new Promise((r) => setTimeout(r, 200));
        }
      })()
    );

    await Promise.all(vuWorkers);
    const stats = summarizeDurations(stageDurations);
    const failRate = stageReqs ? Number((stageFails / stageReqs).toFixed(4)) : 0;
    const rps = Number((stageReqs / (stage.durationMs / 1000)).toFixed(1));
    stageReports.push({
      stage: stage.name,
      vus: stage.targetVus,
      requests: stageReqs,
      failed: stageFails,
      fail_rate: failRate,
      rps,
      latency_ms: stats,
    });
    console.log(
      `${stage.name}: reqs=${stageReqs}, rps=${rps}/s, fail=${(failRate * 100).toFixed(2)}%, avg=${stats.avg}ms, p90=${stats['p(90)']}ms, p95=${stats['p(95)']}ms, max=${stats.max}ms`
    );
  }

  const overall = summarizeDurations(allDurations);
  const overallFailRate = totalReqs ? Number((failedReqs / totalReqs).toFixed(5)) : 0;

  const summary = {
    engine: 'node-v24-load-mirror (k6 unavailable offline)',
    k6_script: 'tests/performance/k6_load_test.js',
    thresholds: {
      http_req_failed_rate_lt_0_01: overallFailRate < 0.01,
      http_req_duration_p95_lt_500ms: overall['p(95)'] < 500,
    },
    metrics: {
      http_reqs: { count: totalReqs, values: { count: totalReqs } },
      http_req_failed: { rate: overallFailRate, count: failedReqs, values: { rate: overallFailRate } },
      http_req_duration: { values: overall },
      ...Object.fromEntries(
        Object.entries(endpointBuckets).map(([k, arr]) => [k, { values: summarizeDurations(arr) }])
      ),
    },
    stages_breakdown: stageReports,
  };

  fs.writeFileSync(SUMMARY_PATH, JSON.stringify(summary, null, 2));
  const passed =
    summary.thresholds.http_req_failed_rate_lt_0_01 &&
    summary.thresholds.http_req_duration_p95_lt_500ms;
  return passed ? 0 : 1;
}

async function main() {
  const k6Bin = await tryEnsureK6Binary();
  const srv = createApoloTestServer({ dbPath: ':memory:' });
  const port = Number(process.env.APOLO_PERF_PORT || 0);
  const started = await srv.start(port, '127.0.0.1');
  console.log(`Isolated Apolo test server listening on ${started.baseUrl} for load testing...`);

  try {
    let statusCode = 0;
    if (k6Bin) {
      const result = spawnSync(k6Bin, ['run', `--summary-export=${SUMMARY_PATH}`, K6_SCRIPT], {
        cwd: ROOT_DIR,
        env: { ...process.env, APOLO_BASE_URL: started.baseUrl },
        stdio: 'inherit',
      });
      statusCode = result.status ?? 1;
    } else {
      statusCode = await runProgressiveNodeBenchmark(started.baseUrl);
    }

    if (fs.existsSync(SUMMARY_PATH)) {
      const summary = JSON.parse(fs.readFileSync(SUMMARY_PATH, 'utf8'));
      const m = summary.metrics || {};
      const dur = m.http_req_duration?.values || m.http_req_duration || {};
      const failed = m.http_req_failed?.values || m.http_req_failed || {};
      console.log('\n=== Performance Summary ===');
      console.log(`Engine: ${summary.engine || 'k6'}`);
      console.log(`Total HTTP requests: ${m.http_reqs?.count ?? m.http_reqs?.values?.count ?? 'n/a'}`);
      console.log(`Failure rate: ${failed.rate ?? failed.value ?? 'n/a'}`);
      console.log(
        `avg=${dur.avg?.toFixed?.(2)}ms | p(90)=${dur['p(90)']?.toFixed?.(2)}ms | p(95)=${dur['p(95)']?.toFixed?.(2)}ms | max=${dur.max?.toFixed?.(2)}ms`
      );
    }

    if (statusCode !== 0) {
      process.exitCode = statusCode;
    }
  } finally {
    await srv.stop();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
