/**
 * Dedicated Stateful Presence Server (ByteByteGo Presence Architecture).
 *
 * - Tracks online/offline status across multiple devices per user.
 * - Uses heartbeat timestamps with a configurable timeout grace period (default 30s)
 *   to avoid flapping on brief mobile network drops.
 * - Publishes presence transitions (`online` / `offline`) to subscribed peers.
 */
export class PresenceServer {
  constructor({ timeoutMs = 30000, sweepIntervalMs = 5000 } = {}) {
    this.timeoutMs = timeoutMs;
    this.sweepIntervalMs = sweepIntervalMs;
    /** @type {Map<number, { status: 'online'|'offline', lastHeartbeatMs: number, lastActiveAt: string, devices: Set<string> }>} */
    this.states = new Map();
    /** @type {Map<number, Set<function>>} targetUserId -> listeners */
    this.subscribers = new Map();
    this._sweepTimer = null;
  }

  start() {
    if (this._sweepTimer) return;
    this._sweepTimer = setInterval(() => this.sweepExpired(), this.sweepIntervalMs);
    if (typeof this._sweepTimer.unref === 'function') {
      this._sweepTimer.unref();
    }
  }

  stop() {
    if (this._sweepTimer) {
      clearInterval(this._sweepTimer);
      this._sweepTimer = null;
    }
  }

  markConnected(userId, deviceId) {
    const uid = Number(userId);
    const nowMs = Date.now();
    const nowIso = new Date(nowMs).toISOString();

    let entry = this.states.get(uid);
    const wasOnline = entry?.status === 'online';

    if (!entry) {
      entry = {
        status: 'online',
        lastHeartbeatMs: nowMs,
        lastActiveAt: nowIso,
        devices: new Set([String(deviceId)]),
      };
      this.states.set(uid, entry);
    } else {
      entry.devices.add(String(deviceId));
      entry.status = 'online';
      entry.lastHeartbeatMs = nowMs;
      entry.lastActiveAt = nowIso;
    }

    if (!wasOnline) {
      this._publish(uid, this.getStatus(uid));
    }
    return this.getStatus(uid);
  }

  heartbeat(userId, deviceId) {
    return this.markConnected(userId, deviceId);
  }

  markDisconnected(userId, deviceId) {
    const uid = Number(userId);
    const entry = this.states.get(uid);
    if (!entry) return;

    entry.devices.delete(String(deviceId));
    entry.lastActiveAt = new Date().toISOString();

    // Multi-device rule: user remains online as long as at least one other device is active.
    if (entry.devices.size === 0 && entry.status !== 'offline') {
      entry.status = 'offline';
      this._publish(uid, this.getStatus(uid));
    }
  }

  sweepExpired(nowMs = Date.now()) {
    for (const [uid, entry] of this.states.entries()) {
      if (entry.status === 'online' && nowMs - entry.lastHeartbeatMs > this.timeoutMs) {
        entry.status = 'offline';
        entry.devices.clear();
        entry.lastActiveAt = new Date(entry.lastHeartbeatMs).toISOString();
        this._publish(uid, this.getStatus(uid));
      }
    }
  }

  getStatus(userId) {
    const uid = Number(userId);
    const entry = this.states.get(uid);
    if (!entry) {
      return {
        user_id: uid,
        status: 'offline',
        last_active_at: null,
        active_devices: 0,
      };
    }
    return {
      user_id: uid,
      status: entry.status,
      last_active_at: entry.lastActiveAt,
      active_devices: entry.devices.size,
    };
  }

  subscribe(targetUserId, listener) {
    const uid = Number(targetUserId);
    if (!this.subscribers.has(uid)) {
      this.subscribers.set(uid, new Set());
    }
    this.subscribers.get(uid).add(listener);
    return () => {
      this.subscribers.get(uid)?.delete(listener);
    };
  }

  _publish(userId, payload) {
    const listeners = this.subscribers.get(userId);
    if (!listeners) return;
    for (const fn of listeners) {
      try {
        fn(payload);
      } catch (_) {}
    }
  }
}
