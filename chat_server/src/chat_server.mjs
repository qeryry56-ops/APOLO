import http from 'node:http';
import { computeAcceptKey, encodeFrame, OPCODE, WsFrameDecoder } from './ws_frame.mjs';
import { KvMessageStore } from './kv_message_store.mjs';
import { PresenceServer } from './presence_server.mjs';
import { PushNotificationService } from './push_notification_service.mjs';

export const MAX_GROUP_MEMBERS = 100;

/**
 * Stateful WebSocket Chat Server + Stateless Service Discovery HTTP endpoint
 * strictly following ByteByteGo "Design a Chat System":
 *
 * - Persistent WebSocket connections for bidirectional real-time messaging
 * - 1-on-1 direct chat & small group chat (strictly <= 100 members)
 * - Multi-device fanout (broadcasts to all connected devices of sender & recipients)
 * - Per-device `cur_max_message_id` offline sync (`sync_request`)
 * - `client_message_id` idempotency (zero duplicate messages)
 * - Dedicated PresenceServer integration (heartbeats, online/offline fanout)
 * - Third-party PushNotificationService integration for offline/backgrounded recipients
 */
export class StatefulChatServer {
  constructor({
    nodeId = 'chat-node-1',
    region = 'ma-casablanca',
    kvStore = null,
    presenceServer = null,
    pushService = null,
    heartbeatIntervalMs = 10000,
    presenceTimeoutMs = 30000,
  } = {}) {
    this.nodeId = nodeId;
    this.region = region;
    this.heartbeatIntervalMs = heartbeatIntervalMs;
    this.kvStore = kvStore ?? new KvMessageStore();
    this.presenceServer =
      presenceServer ??
      new PresenceServer({
        timeoutMs: presenceTimeoutMs,
        sweepIntervalMs: Math.min(5000, Math.max(200, Math.floor(presenceTimeoutMs / 3))),
      });
    this.pushService = pushService ?? new PushNotificationService();

    /** @type {Map<string, { channelId: string, type: 'direct'|'group', name: string, members: Set<number>, adContext?: object }>} */
    this.channels = new Map();
    /** @type {Map<number, Set<object>>} userId -> active socket session objects */
    this.sessionsByUser = new Map();
    /** @type {Set<object>} */
    this.allSessions = new Set();

    this.httpServer = null;
    this.port = 0;
  }

  get wsUrl() {
    return `ws://127.0.0.1:${this.port}/ws`;
  }

  get httpBaseUrl() {
    return `http://127.0.0.1:${this.port}`;
  }

  async start(port = 0, host = '127.0.0.1') {
    this.presenceServer.start();

    this.httpServer = http.createServer((req, res) => this._handleHttp(req, res));
    this.httpServer.on('upgrade', (req, socket) => this._handleUpgrade(req, socket));

    await new Promise((resolve, reject) => {
      this.httpServer.once('error', reject);
      this.httpServer.listen(port, host, () => {
        const addr = this.httpServer.address();
        this.port = typeof addr === 'object' && addr ? addr.port : port;
        resolve();
      });
    });

    return this;
  }

  async stop() {
    this.presenceServer.stop();
    for (const session of Array.from(this.allSessions)) {
      try {
        session.socket.destroy();
      } catch (_) {}
    }
    this.allSessions.clear();
    this.sessionsByUser.clear();

    if (this.httpServer) {
      await new Promise((resolve) => this.httpServer.close(() => resolve()));
      this.httpServer = null;
    }
  }

  /**
   * Ensure a 1-on-1 or small group (<= 100 members) channel exists.
   */
  upsertChannel({ channelId, type = 'direct', name = '', memberIds = [], adContext = null }) {
    const chId = String(channelId);
    const uniqueMembers = Array.from(
      new Set(memberIds.map((id) => Number(id)).filter((id) => Number.isFinite(id) && id > 0)),
    );

    if (type === 'group' && uniqueMembers.length > MAX_GROUP_MEMBERS) {
      throw new Error(`Group chat cannot exceed ${MAX_GROUP_MEMBERS} members.`);
    }

    let channel = this.channels.get(chId);
    if (!channel) {
      channel = {
        channelId: chId,
        type: type === 'group' ? 'group' : 'direct',
        name: String(name || ''),
        members: new Set(uniqueMembers),
        adContext: adContext ?? null,
      };
      this.channels.set(chId, channel);
    } else {
      for (const uid of uniqueMembers) {
        if (channel.type === 'group' && !channel.members.has(uid) && channel.members.size >= MAX_GROUP_MEMBERS) {
          throw new Error(`Group chat cannot exceed ${MAX_GROUP_MEMBERS} members.`);
        }
        channel.members.add(uid);
      }
      if (adContext) channel.adContext = adContext;
      if (name) channel.name = String(name);
    }
    return channel;
  }

  _handleHttp(req, res) {
    const url = new URL(req.url || '/', `http://${req.headers.host || '127.0.0.1'}`);

    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }

    if (url.pathname === '/health') {
      res.writeHead(200);
      res.end(
        JSON.stringify({
          status: 'ok',
          node_id: this.nodeId,
          region: this.region,
          active_connections: this.allSessions.size,
          max_group_members: MAX_GROUP_MEMBERS,
        }),
      );
      return;
    }

    // Stateless Service Discovery endpoint (mirrors Laravel GET /api/v1/chat/service-discovery)
    if (url.pathname === '/api/v1/chat/service-discovery' && req.method === 'GET') {
      res.writeHead(200);
      res.end(
        JSON.stringify({
          status: 'ok',
          data: {
            node_id: this.nodeId,
            region: this.region,
            chat_server_ws_url: this.wsUrl,
            presence_server_ws_url: this.wsUrl,
            fallback_nodes: [],
            heartbeat_interval_ms: this.heartbeatIntervalMs,
            presence_timeout_seconds: Math.round(this.presenceServer.timeoutMs / 1000),
            max_group_members: MAX_GROUP_MEMBERS,
          },
        }),
      );
      return;
    }

    res.writeHead(404);
    res.end(JSON.stringify({ status: 'error', message: 'Not found' }));
  }

  _handleUpgrade(req, socket) {
    const key = req.headers['sec-websocket-key'];
    if (!key) {
      socket.write('HTTP/1.1 400 Bad Request\r\n\r\n');
      socket.destroy();
      return;
    }

    const accept = computeAcceptKey(key);
    socket.write(
      [
        'HTTP/1.1 101 Switching Protocols',
        'Upgrade: websocket',
        'Connection: Upgrade',
        `Sec-WebSocket-Accept: ${accept}`,
        '\r\n',
      ].join('\r\n'),
    );

    const session = {
      socket,
      userId: 0,
      userName: '',
      deviceId: '',
      backgrounded: false,
      unsubscribers: [],
      send: (obj) => {
        if (socket.destroyed) return;
        try {
          socket.write(encodeFrame(JSON.stringify(obj), { opcode: OPCODE.TEXT, masked: false }));
        } catch (_) {}
      },
    };

    const decoder = new WsFrameDecoder();
    this.allSessions.add(session);

    socket.on('data', (chunk) => {
      const frames = decoder.push(chunk);
      for (const frame of frames) {
        if (frame.opcode === OPCODE.CLOSE) {
          socket.end();
          return;
        }
        if (frame.opcode === OPCODE.PING) {
          socket.write(encodeFrame(frame.payload, { opcode: OPCODE.PONG, masked: false }));
          continue;
        }
        if (frame.opcode === OPCODE.TEXT) {
          let packet;
          try {
            packet = JSON.parse(frame.payload.toString('utf8'));
          } catch (_) {
            session.send({ event: 'error', code: 'invalid_json', message: 'Invalid JSON frame' });
            continue;
          }
          this._handlePacket(session, packet).catch((err) => {
            session.send({
              event: 'error',
              code: 'server_error',
              message: err?.message || 'Internal error',
            });
          });
        }
      }
    });

    const cleanup = () => {
      if (!this.allSessions.has(session)) return;
      this.allSessions.delete(session);
      for (const unsub of session.unsubscribers) {
        try {
          unsub();
        } catch (_) {}
      }
      session.unsubscribers = [];

      if (session.userId > 0) {
        const userSet = this.sessionsByUser.get(session.userId);
        if (userSet) {
          userSet.delete(session);
          if (userSet.size === 0) {
            this.sessionsByUser.delete(session.userId);
          }
        }
        this.presenceServer.markDisconnected(session.userId, session.deviceId);
      }
    };

    socket.on('end', () => {
      try {
        socket.end();
      } catch (_) {}
      cleanup();
    });
    socket.on('close', cleanup);
    socket.on('error', cleanup);
  }

  async _handlePacket(session, packet) {
    const event = String(packet?.event || '').trim();

    if (event === 'auth') {
      const userId = Number(packet.user_id);
      const deviceId = String(packet.device_id || `dev-${Date.now()}`).trim();
      if (!userId || userId <= 0) {
        session.send({ event: 'error', code: 'invalid_auth', message: 'Valid user_id is required.' });
        return;
      }

      session.userId = userId;
      session.userName = String(packet.user_name || `User ${userId}`);
      session.deviceId = deviceId;
      session.backgrounded = packet.backgrounded === true;

      if (!this.sessionsByUser.has(userId)) {
        this.sessionsByUser.set(userId, new Set());
      }
      this.sessionsByUser.get(userId).add(session);

      const presence = this.presenceServer.markConnected(userId, deviceId);
      session.send({
        event: 'auth_ok',
        node_id: this.nodeId,
        user_id: userId,
        device_id: deviceId,
        heartbeat_interval_ms: this.heartbeatIntervalMs,
        max_group_members: MAX_GROUP_MEMBERS,
        presence,
      });
      return;
    }

    if (session.userId <= 0) {
      session.send({ event: 'error', code: 'unauthenticated', message: 'Send auth event first.' });
      return;
    }

    if (event === 'heartbeat') {
      if (typeof packet.backgrounded === 'boolean') {
        session.backgrounded = packet.backgrounded;
      }
      const presence = this.presenceServer.heartbeat(session.userId, session.deviceId);
      session.send({ event: 'heartbeat_ack', server_time: new Date().toISOString(), presence });
      return;
    }

    if (event === 'presence_subscribe') {
      const userIds = Array.isArray(packet.user_ids)
        ? packet.user_ids.map((id) => Number(id)).filter((id) => id > 0).slice(0, 100)
        : [];
      const snapshots = {};
      for (const targetUid of userIds) {
        snapshots[String(targetUid)] = this.presenceServer.getStatus(targetUid);
        const unsub = this.presenceServer.subscribe(targetUid, (statusPayload) => {
          session.send({ event: 'presence_update', data: statusPayload });
        });
        session.unsubscribers.push(unsub);
      }
      session.send({ event: 'presence_snapshot', data: snapshots });
      return;
    }

    if (event === 'create_group') {
      const channelId = String(packet.channel_id || `grp:${Date.now()}`);
      const memberIds = Array.isArray(packet.member_ids)
        ? [...packet.member_ids, session.userId]
        : [session.userId];
      try {
        const channel = this.upsertChannel({
          channelId,
          type: 'group',
          name: String(packet.name || 'Group Chat'),
          memberIds,
          adContext: packet.ad_context ?? null,
        });
        session.send({
          event: 'group_created',
          channel_id: channel.channelId,
          name: channel.name,
          member_count: channel.members.size,
          max_members: MAX_GROUP_MEMBERS,
        });
      } catch (err) {
        session.send({ event: 'error', code: 'group_limit_exceeded', message: err.message });
      }
      return;
    }

    if (event === 'send_message') {
      const channelId = String(packet.channel_id || '').trim();
      if (!channelId) {
        session.send({ event: 'error', code: 'missing_channel', message: 'channel_id is required.' });
        return;
      }

      const recipientIds = Array.isArray(packet.recipient_ids)
        ? packet.recipient_ids.map((id) => Number(id)).filter((id) => id > 0)
        : packet.recipient_id
          ? [Number(packet.recipient_id)]
          : [];

      let channel = this.channels.get(channelId);
      if (!channel) {
        const type = packet.channel_type === 'group' || recipientIds.length > 1 ? 'group' : 'direct';
        try {
          channel = this.upsertChannel({
            channelId,
            type,
            name: String(packet.channel_name || ''),
            memberIds: [session.userId, ...recipientIds],
            adContext: packet.ad_context ?? null,
          });
        } catch (err) {
          session.send({ event: 'error', code: 'group_limit_exceeded', message: err.message });
          return;
        }
      }

      if (!channel.members.has(session.userId)) {
        session.send({ event: 'error', code: 'forbidden', message: 'Not a member of this channel.' });
        return;
      }

      const clientMessageId = String(packet.client_message_id || `${session.deviceId}-${Date.now()}`);
      const stored = this.kvStore.putMessage({
        channelId,
        senderId: session.userId,
        senderName: session.userName,
        clientMessageId,
        type: String(packet.type || 'text'),
        body: String(packet.body || ''),
        metadata: packet.metadata && typeof packet.metadata === 'object' ? packet.metadata : {},
      });

      const msg = stored.message;

      // Update sender device sync cursor
      this.kvStore.updateDeviceCursor(session.userId, session.deviceId, channelId, msg.message_id);

      // Always ACK the sending device with canonical Snowflake message_id
      session.send({
        event: 'message_ack',
        channel_id: channelId,
        client_message_id: msg.client_message_id,
        message_id: msg.message_id,
        deduplicated: stored.deduplicated,
        created_at: msg.created_at,
      });

      if (stored.deduplicated) {
        return;
      }

      // Fanout to all channel members across all their connected devices (1-on-1 & group <= 100)
      for (const memberId of channel.members) {
        const memberSessions = this.sessionsByUser.get(memberId);
        let hasForegroundDevice = false;

        if (memberSessions && memberSessions.size > 0) {
          for (const targetSession of memberSessions) {
            if (targetSession === session) continue; // Sender's originating device already got message_ack
            if (!targetSession.backgrounded) {
              hasForegroundDevice = true;
            }
            targetSession.send({
              event: 'message',
              data: msg,
            });
            this.kvStore.updateDeviceCursor(memberId, targetSession.deviceId, channelId, msg.message_id);
          }
        }

        // Trigger third-party push notification for offline or backgrounded recipients
        if (memberId !== session.userId && !hasForegroundDevice) {
          await this.pushService.notifyOfflineUser({
            userId: memberId,
            senderName: session.userName,
            message: msg,
            adTitle: channel.adContext?.ad_title || '',
          });
        }
      }
      return;
    }

    if (event === 'sync_request') {
      const channelId = String(packet.channel_id || '').trim();
      const requestedAfter =
        packet.after_message_id !== undefined && packet.after_message_id !== null
          ? String(packet.after_message_id)
          : this.kvStore.getDeviceCursor(session.userId, session.deviceId, channelId);

      const messages = this.kvStore.syncAfter(channelId, requestedAfter, packet.limit || 100);
      let newCursor = requestedAfter;
      if (messages.length > 0) {
        newCursor = messages[messages.length - 1].message_id;
        this.kvStore.updateDeviceCursor(session.userId, session.deviceId, channelId, newCursor);
      }

      session.send({
        event: 'sync_response',
        channel_id: channelId,
        device_id: session.deviceId,
        cur_max_message_id: newCursor,
        messages,
      });
      return;
    }

    if (event === 'typing') {
      const channelId = String(packet.channel_id || '').trim();
      const channel = this.channels.get(channelId);
      if (!channel || !channel.members.has(session.userId)) return;

      for (const memberId of channel.members) {
        if (memberId === session.userId) continue;
        const memberSessions = this.sessionsByUser.get(memberId);
        if (!memberSessions) continue;
        for (const targetSession of memberSessions) {
          targetSession.send({
            event: 'typing',
            channel_id: channelId,
            user_id: session.userId,
            user_name: session.userName,
            is_typing: packet.is_typing === true,
          });
        }
      }
      return;
    }

    if (event === 'ack_read') {
      const channelId = String(packet.channel_id || '').trim();
      const lastReadMessageId = String(packet.last_read_message_id || '0');
      const channel = this.channels.get(channelId);
      if (!channel || !channel.members.has(session.userId)) return;

      for (const memberId of channel.members) {
        if (memberId === session.userId) continue;
        const memberSessions = this.sessionsByUser.get(memberId);
        if (!memberSessions) continue;
        for (const targetSession of memberSessions) {
          targetSession.send({
            event: 'read_receipt',
            channel_id: channelId,
            user_id: session.userId,
            last_read_message_id: lastReadMessageId,
          });
        }
      }
    }
  }
}
