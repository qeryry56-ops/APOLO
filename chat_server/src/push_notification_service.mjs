/**
 * Third-Party Push Notification Service (ByteByteGo Push Notification Integration).
 *
 * Dispatches push notifications (FCM / APNs / WebPush) for recipients who are
 * offline or backgrounded. Accepts an optional `transport` function so unit &
 * integration tests can assert exact push delivery without external network calls.
 */
export class PushNotificationService {
  constructor({ fcmEndpoint = '', fcmServerKey = '', transport = null } = {}) {
    this.fcmEndpoint = fcmEndpoint;
    this.fcmServerKey = fcmServerKey;
    this.transport = transport;
    /** @type {Map<number, Map<string, { platform: string, provider: string, token: string }>>} */
    this.tokensByUser = new Map();
    /** @type {Array<object>} */
    this.deliveryLog = [];
  }

  registerToken({ userId, deviceId, platform = 'web', provider = 'fcm', token }) {
    const uid = Number(userId);
    if (!uid || !deviceId || !token) return;
    if (!this.tokensByUser.has(uid)) {
      this.tokensByUser.set(uid, new Map());
    }
    this.tokensByUser.get(uid).set(String(deviceId), {
      platform: String(platform),
      provider: String(provider),
      token: String(token),
    });
  }

  unregisterToken(userId, deviceId) {
    const uid = Number(userId);
    this.tokensByUser.get(uid)?.delete(String(deviceId));
  }

  async notifyOfflineUser({ userId, senderName, message, adTitle = '' }) {
    const uid = Number(userId);
    const devices = this.tokensByUser.get(uid);
    if (!devices || devices.size === 0) return [];

    const preview =
      message.type === 'audio'
        ? 'رسالة صوتية'
        : message.type === 'image'
          ? 'صورة'
          : String(message.body || '').slice(0, 120);

    const title = adTitle ? `${senderName} · ${adTitle}` : senderName;
    const results = [];

    for (const [deviceId, info] of devices.entries()) {
      const payload = {
        user_id: uid,
        device_id: deviceId,
        provider: info.provider,
        platform: info.platform,
        token: info.token,
        notification: { title, body: preview },
        data: {
          channel_id: String(message.channel_id),
          message_id: String(message.message_id),
          sender_id: String(message.sender_id),
          type: String(message.type),
        },
      };

      if (typeof this.transport === 'function') {
        await this.transport(payload);
      } else if (this.fcmEndpoint && this.fcmServerKey && typeof fetch === 'function') {
        await fetch(this.fcmEndpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.fcmServerKey}`,
          },
          body: JSON.stringify({
            message: {
              token: info.token,
              notification: payload.notification,
              data: payload.data,
            },
          }),
        }).catch(() => {});
      }

      this.deliveryLog.push(payload);
      results.push(payload);
    }

    return results;
  }
}
