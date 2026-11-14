import { createApoloTestServer } from './test_api_server.mjs';

const port = Number(process.env.PORT || 8787);
const host = process.env.HOST || '127.0.0.1';
const dbPath = process.env.TEST_DB_PATH || ':memory:';

const app = createApoloTestServer({ dbPath });
const info = await app.start(port, host);
console.log(`APOLO_TEST_SERVER_READY ${info.baseUrl}`);

process.on('SIGINT', async () => {
  await app.stop();
  process.exit(0);
});
process.on('SIGTERM', async () => {
  await app.stop();
  process.exit(0);
});
