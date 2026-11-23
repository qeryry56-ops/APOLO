import { SnowflakeIdGenerator } from './snowflake.mjs';

/**
 * Key-Value Message Store (ByteByteGo KV Store Architecture).
 *
 * Partition key: `channelId`
 * Clustering key: `messageId` (64-bit time-ordered Snowflake ID)
 * Idempotency key: `${channelId}:${senderId}:${clientMessageId}` -> `messageId`
 * Multi-device sync cursor: `${userId}:${deviceId}:${channelId}` -> `curMaxMessageId`
 */
export class KvMessageStore {
  constructor({ idGenerator } = {}) {
    this.idGenerator = idGenerator ?? new SnowflakeIdGenerator();
    /** @type {Map<string, Array<object>>} channelId -> sorted messages asc by messageId */
    this.partitions = new Map();
    /** @type {Map<string, object>} idempotencyKey -> canonical message */
    this.idempotencyIndex = new Map();
    /** @type {Map<string, string>} `${userId}:${deviceId}:${channelId}` -> curMaxMessageId */
    this.deviceCursors = new Map();
  }

  /**
   * Persist a message idempotently. Retrying the same `(channelId, senderId, clientMessageId)`
   * returns the original canonical message with `deduplicated: true`.
   */
  putMessage({
    channelId,
    senderId,
    senderName = '',
    clientMessageId,
    type = 'text',
    body = '',
    metadata = {},
  }) {
    const chKey = String(channelId);
    const idempKey = `${chKey}:${senderId}:${clientMessageId}`;

    if (clientMessageId && this.idempotencyIndex.has(idempKey)) {
      return {
        message: this.idempotencyIndex.get(idempKey),
        deduplicated: true,
      };
    }

    const messageId = this.idGenerator.nextId();
    const message = {
      channel_id: chKey,
      message_id: messageId,
      sender_id: Number(senderId),
      sender_name: senderName,
      client_message_id: String(clientMessageId || messageId),
      type: ['text', 'audio', 'image'].includes(type) ? type : 'text',
      body: String(body ?? ''),
      metadata: metadata && typeof metadata === 'object' ? metadata : {},
      created_at: new Date().toISOString(),
    };

    if (!this.partitions.has(chKey)) {
      this.partitions.set(chKey, []);
    }
    this.partitions.get(chKey).push(message);

    if (clientMessageId) {
      this.idempotencyIndex.set(idempKey, message);
    }

    return { message, deduplicated: false };
  }

  /**
   * Range query: fetch messages strictly newer than `afterMessageId` (multi-device sync).
   */
  syncAfter(channelId, afterMessageId = '0', limit = 100) {
    const chKey = String(channelId);
    const list = this.partitions.get(chKey) ?? [];
    const afterBig = BigInt(afterMessageId || '0');
    const safeLimit = Math.max(1, Math.min(Number(limit) || 100, 200));

    if (afterBig === 0n) {
      return list.slice(-safeLimit);
    }

    const out = [];
    for (const msg of list) {
      if (BigInt(msg.message_id) > afterBig) {
        out.push(msg);
        if (out.length >= safeLimit) break;
      }
    }
    return out;
  }

  getDeviceCursor(userId, deviceId, channelId) {
    return this.deviceCursors.get(`${userId}:${deviceId}:${channelId}`) ?? '0';
  }

  updateDeviceCursor(userId, deviceId, channelId, messageId) {
    const key = `${userId}:${deviceId}:${channelId}`;
    const prev = BigInt(this.deviceCursors.get(key) ?? '0');
    const next = BigInt(messageId || '0');
    if (next > prev) {
      this.deviceCursors.set(key, next.toString());
    }
    return this.deviceCursors.get(key) ?? '0';
  }
}
