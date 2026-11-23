import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import net from 'node:net';
import test from 'node:test';

import { StatefulChatServer, MAX_GROUP_MEMBERS } from '../src/chat_server.mjs';
import { PushNotificationService } from '../src/push_notification_service.mjs';
import { encodeFrame, OPCODE, WsFrameDecoder } from '../src/ws_frame.mjs';

/**
 * Minimal RFC 6455 test client (zero external dependencies).
 */
async function connectWsClient(wsUrl) {
  const url = new URL(wsUrl);
  const key = crypto.randomBytes(16).toString('base64');

  const socket = net.createConnection({
    host: url.hostname,
    port: Number(url.port),
  });

  const decoder = new WsFrameDecoder();
  const queue = [];
  const waiters = [];

  const pushMsg = (obj) => {
    if (waiters.length > 0) {
      waiters.shift()(obj);
    } else {
      queue.push(obj);
    }
  };

  let upgraded = false;
  let handshakeBuf = Buffer.alloc(0);

  await new Promise((resolve, reject) => {
    socket.once('error', reject);
    socket.once('connect', () => {
      socket.write(
        [
          `GET ${url.pathname || '/ws'} HTTP/1.1`,
          `Host: ${url.host}`,
          'Upgrade: websocket',
          'Connection: Upgrade',
          `Sec-WebSocket-Key: ${key}`,
          'Sec-WebSocket-Version: 13',
          '\r\n',
        ].join('\r\n'),
      );
    });

    socket.on('data', (chunk) => {
      if (!upgraded) {
        handshakeBuf = Buffer.concat([handshakeBuf, chunk]);
        const sep = handshakeBuf.indexOf('\r\n\r\n');
        if (sep === -1) return;
        const head = handshakeBuf.subarray(0, sep).toString('utf8');
        assert.match(head, /101 Switching Protocols/);
        upgraded = true;
        const remainder = handshakeBuf.subarray(sep + 4);
        resolve();
        if (remainder.length > 0) {
          for (const frame of decoder.push(remainder)) {
            if (frame.opcode === OPCODE.TEXT) {
              pushMsg(JSON.parse(frame.payload.toString('utf8')));
            }
          }
        }
        return;
      }

      for (const frame of decoder.push(chunk)) {
        if (frame.opcode === OPCODE.TEXT) {
          pushMsg(JSON.parse(frame.payload.toString('utf8')));
        }
      }
    });
  });

  return {
    send(obj) {
      socket.write(encodeFrame(JSON.stringify(obj), { opcode: OPCODE.TEXT, masked: true }));
    },
    nextEvent(predicate = null, timeoutMs = 2500) {
      return new Promise((resolve, reject) => {
        const checkQueue = () => {
          for (let i = 0; i < queue.length; i++) {
            if (!predicate || predicate(queue[i])) {
              return queue.splice(i, 1)[0];
            }
          }
          return null;
        };

        const found = checkQueue();
        if (found) return resolve(found);

        const timer = setTimeout(() => {
          reject(new Error('Timed out waiting for WebSocket event'));
        }, timeoutMs);

        const onMsg = (msg) => {
          if (!predicate || predicate(msg)) {
            clearTimeout(timer);
            resolve(msg);
          } else {
            queue.push(msg);
            waiters.push(onMsg);
          }
        };
        waiters.push(onMsg);
      });
    },
    close() {
      return new Promise((resolve) => {
        socket.once('close', resolve);
        try {
          socket.write(encodeFrame(Buffer.alloc(0), { opcode: OPCODE.CLOSE, masked: true }));
        } catch (_) {}
        socket.end();
      });
    },
  };
}

test('ByteByteGo Chat System: Service Discovery, 1-on-1, Idempotency, Group <=100, Multi-Device Sync, Presence, Push', async () => {
  const pushDeliveries = [];
  const pushService = new PushNotificationService({
    transport: async (payload) => {
      pushDeliveries.push(payload);
    },
  });
  pushService.registerToken({
    userId: 202,
    deviceId: 'ios-202',
    platform: 'ios',
    provider: 'apns',
    token: 'apns-token-202',
  });

  const server = new StatefulChatServer({
    nodeId: 'chat-ma-1',
    region: 'ma-casablanca',
    pushService,
    heartbeatIntervalMs: 5000,
    presenceTimeoutMs: 30000,
  });

  await server.start(0);

  try {
    // 1. Stateless Service Discovery over HTTP
    const discRes = await fetch(`${server.httpBaseUrl}/api/v1/chat/service-discovery`);
    assert.equal(discRes.status, 200);
    const discJson = await discRes.json();
    assert.equal(discJson.status, 'ok');
    assert.equal(discJson.data.max_group_members, 100);
    assert.equal(discJson.data.chat_server_ws_url, server.wsUrl);

    // 2. Connect User 101 (Device A) and subscribe to User 202 presence
    const client101 = await connectWsClient(discJson.data.chat_server_ws_url);
    client101.send({ event: 'auth', user_id: 101, user_name: 'Amine', device_id: 'web-101' });
    const auth101 = await client101.nextEvent((e) => e.event === 'auth_ok');
    assert.equal(auth101.user_id, 101);

    client101.send({ event: 'presence_subscribe', user_ids: [202] });
    const snap = await client101.nextEvent((e) => e.event === 'presence_snapshot');
    assert.equal(snap.data['202'].status, 'offline');

    // 3. Send message while User 202 is OFFLINE -> triggers Third-Party Push Notification
    const channelId = 'dm:101:202:5501';
    client101.send({
      event: 'send_message',
      channel_id: channelId,
      recipient_id: 202,
      client_message_id: 'cmsg-001',
      type: 'text',
      body: 'السلام عليكم، واش Tissot watch black باقي متوفرة بـ DH 110.00؟',
      ad_context: { ad_id: 5501, ad_title: 'Tissot watch black', ad_price: 'DH 110.00' },
    });
    const ack1 = await client101.nextEvent((e) => e.event === 'message_ack');
    assert.equal(ack1.client_message_id, 'cmsg-001');
    assert.equal(ack1.deduplicated, false);
    assert.ok(BigInt(ack1.message_id) > 0n);

    // Retry exact same client_message_id -> idempotent deduplication (zero duplicates)
    client101.send({
      event: 'send_message',
      channel_id: channelId,
      recipient_id: 202,
      client_message_id: 'cmsg-001',
      type: 'text',
      body: 'السلام عليكم، واش Tissot watch black باقي متوفرة بـ DH 110.00؟',
    });
    const ackDup = await client101.nextEvent((e) => e.event === 'message_ack');
    assert.equal(ackDup.deduplicated, true);
    assert.equal(ackDup.message_id, ack1.message_id);

    // Push notification was delivered once for offline recipient 202
    assert.equal(pushDeliveries.length, 1);
    assert.equal(pushDeliveries[0].user_id, 202);
    assert.match(pushDeliveries[0].notification.title, /Tissot watch black/);

    // 4. User 202 comes ONLINE on Device 1 -> Presence Server publishes online update to User 101
    const client202Dev1 = await connectWsClient(discJson.data.chat_server_ws_url);
    client202Dev1.send({ event: 'auth', user_id: 202, user_name: 'Seller', device_id: 'ios-202' });
    await client202Dev1.nextEvent((e) => e.event === 'auth_ok');

    const onlineUpdate = await client101.nextEvent(
      (e) => e.event === 'presence_update' && e.data.user_id === 202,
    );
    assert.equal(onlineUpdate.data.status, 'online');

    // 5. Offline Sync (`cur_max_message_id`): User 202 Device 1 catches up missed message
    client202Dev1.send({ event: 'sync_request', channel_id: channelId, after_message_id: '0' });
    const sync1 = await client202Dev1.nextEvent((e) => e.event === 'sync_response');
    assert.equal(sync1.messages.length, 1);
    assert.equal(sync1.messages[0].message_id, ack1.message_id);

    // 6. Multi-Device Fanout: User 202 connects Device 2; User 101 sends a Voice Note
    const client202Dev2 = await connectWsClient(discJson.data.chat_server_ws_url);
    client202Dev2.send({ event: 'auth', user_id: 202, user_name: 'Seller', device_id: 'web-202' });
    await client202Dev2.nextEvent((e) => e.event === 'auth_ok');

    client101.send({
      event: 'send_message',
      channel_id: channelId,
      recipient_id: 202,
      client_message_id: 'cmsg-voice-002',
      type: 'audio',
      body: 'رسالة صوتية',
      metadata: { audio_duration: '0:07', audio_mime: 'audio/webm' },
    });

    const [ackVoice, dev1Msg, dev2Msg] = await Promise.all([
      client101.nextEvent((e) => e.event === 'message_ack' && e.client_message_id === 'cmsg-voice-002'),
      client202Dev1.nextEvent((e) => e.event === 'message'),
      client202Dev2.nextEvent((e) => e.event === 'message'),
    ]);
    assert.ok(BigInt(ackVoice.message_id) > BigInt(ack1.message_id));
    assert.equal(dev1Msg.data.type, 'audio');
    assert.equal(dev2Msg.data.message_id, dev1Msg.data.message_id);
    // No extra push notification since User 202 has active foreground devices
    assert.equal(pushDeliveries.length, 1);

    // 7. Small Group Chat limit (<= 100 members)
    const hundredMembers = Array.from({ length: MAX_GROUP_MEMBERS }, (_, i) => i + 1);
    client101.send({
      event: 'create_group',
      channel_id: 'grp:watch-club',
      name: 'Watch Collectors',
      member_ids: hundredMembers.slice(0, 99), // + sender (101) = 100
    });
    const grpOk = await client101.nextEvent((e) => e.event === 'group_created');
    assert.equal(grpOk.member_count, 100);

    const tooManyMembers = Array.from({ length: 105 }, (_, i) => i + 1);
    client101.send({
      event: 'create_group',
      channel_id: 'grp:too-large',
      name: 'Too Large',
      member_ids: tooManyMembers,
    });
    const grpErr = await client101.nextEvent((e) => e.event === 'error');
    assert.equal(grpErr.code, 'group_limit_exceeded');

    // 8. Multi-device presence disconnect: closing Device 1 keeps 202 online; closing Device 2 marks offline
    await client202Dev1.close();
    assert.equal(server.presenceServer.getStatus(202).status, 'online');

    await client202Dev2.close();
    const offlineUpdate = await client101.nextEvent(
      (e) => e.event === 'presence_update' && e.data.user_id === 202 && e.data.status === 'offline',
    );
    assert.equal(offlineUpdate.data.status, 'offline');

    // 9. Heartbeat timeout sweep marks silent users offline deterministically
    server.presenceServer.heartbeat(101, 'web-101');
    assert.equal(server.presenceServer.getStatus(101).status, 'online');
    server.presenceServer.sweepExpired(Date.now() + 31000);
    assert.equal(server.presenceServer.getStatus(101).status, 'offline');

    await client101.close();
  } finally {
    await server.stop();
  }
});
