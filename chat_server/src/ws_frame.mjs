import crypto from 'node:crypto';

const WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

export const OPCODE = {
  CONT: 0x0,
  TEXT: 0x1,
  BINARY: 0x2,
  CLOSE: 0x8,
  PING: 0x9,
  PONG: 0xa,
};

export function computeAcceptKey(secWebSocketKey) {
  return crypto
    .createHash('sha1')
    .update(String(secWebSocketKey).trim() + WS_GUID)
    .digest('base64');
}

/**
 * Encode an RFC 6455 WebSocket frame.
 * Set `masked: true` when sending from a client to a server.
 */
export function encodeFrame(payload, { opcode = OPCODE.TEXT, masked = false } = {}) {
  const data = Buffer.isBuffer(payload) ? payload : Buffer.from(String(payload), 'utf8');
  const len = data.length;
  const headerParts = [];

  headerParts.push(0x80 | (opcode & 0x0f)); // FIN=1

  const maskBit = masked ? 0x80 : 0x00;
  if (len < 126) {
    headerParts.push(maskBit | len);
  } else if (len < 65536) {
    headerParts.push(maskBit | 126, (len >> 8) & 0xff, len & 0xff);
  } else {
    headerParts.push(maskBit | 127);
    const lenBuf = Buffer.alloc(8);
    lenBuf.writeBigUInt64BE(BigInt(len), 0);
    for (const b of lenBuf) headerParts.push(b);
  }

  const header = Buffer.from(headerParts);
  if (!masked) {
    return Buffer.concat([header, data]);
  }

  const maskKey = crypto.randomBytes(4);
  const maskedPayload = Buffer.alloc(len);
  for (let i = 0; i < len; i++) {
    maskedPayload[i] = data[i] ^ maskKey[i % 4];
  }
  return Buffer.concat([header, maskKey, maskedPayload]);
}

/**
 * Stateful incremental RFC 6455 frame parser.
 */
export class WsFrameDecoder {
  constructor() {
    this.buffer = Buffer.alloc(0);
  }

  push(chunk) {
    this.buffer = Buffer.concat([this.buffer, chunk]);
    const frames = [];

    while (this.buffer.length >= 2) {
      const first = this.buffer[0];
      const second = this.buffer[1];
      const opcode = first & 0x0f;
      const isMasked = (second & 0x80) !== 0;
      let payloadLen = second & 0x7f;
      let offset = 2;

      if (payloadLen === 126) {
        if (this.buffer.length < 4) break;
        payloadLen = this.buffer.readUInt16BE(2);
        offset = 4;
      } else if (payloadLen === 127) {
        if (this.buffer.length < 10) break;
        payloadLen = Number(this.buffer.readBigUInt64BE(2));
        offset = 10;
      }

      const maskLen = isMasked ? 4 : 0;
      const totalLen = offset + maskLen + payloadLen;
      if (this.buffer.length < totalLen) break;

      let payload = this.buffer.subarray(offset + maskLen, totalLen);
      if (isMasked) {
        const maskKey = this.buffer.subarray(offset, offset + 4);
        const unmasked = Buffer.alloc(payloadLen);
        for (let i = 0; i < payloadLen; i++) {
          unmasked[i] = payload[i] ^ maskKey[i % 4];
        }
        payload = unmasked;
      } else {
        payload = Buffer.from(payload);
      }

      this.buffer = this.buffer.subarray(totalLen);
      frames.push({ opcode, payload });
    }

    return frames;
  }
}
