import { StatefulChatServer } from './chat_server.mjs';

const port = Number(process.env.CHAT_WS_PORT || 8081);
const host = process.env.CHAT_WS_HOST || '0.0.0.0';
const nodeId = process.env.CHAT_NODE_ID || 'chat-eu-west-1';
const region = process.env.CHAT_REGION || 'ma-casablanca';

const server = new StatefulChatServer({
  nodeId,
  region,
  heartbeatIntervalMs: Number(process.env.CHAT_HEARTBEAT_INTERVAL_MS || 10000),
  presenceTimeoutMs: Number(process.env.CHAT_PRESENCE_TIMEOUT_MS || 30000),
});

server.start(port, host).then(() => {
  console.log(
    `[Apolo StatefulChatServer] node=${nodeId} region=${region} listening on ws://${host}:${port}/ws (discovery: http://${host}:${port}/api/v1/chat/service-discovery)`,
  );
});
