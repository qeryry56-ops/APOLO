-- ============================================================================
-- ByteByteGo "Design a Chat System" — Data Storage Separation
-- 1. Relational Database (PostgreSQL / MySQL) for generic metadata:
--    channels (1-on-1 & small group <= 100 members), memberships,
--    multi-device sync cursors (`cur_max_message_id`), push tokens, presence.
-- 2. Key-Value Store schema (`chat_kv_messages` / Redis / HBase / Cassandra):
--    Partition key = `channel_id`, Clustering key = `message_id` (Snowflake).
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_channels (
    id                   BIGSERIAL PRIMARY KEY,
    channel_key          VARCHAR(191) NOT NULL UNIQUE,
    type                 VARCHAR(16)  NOT NULL CHECK (type IN ('direct', 'group')),
    name                 VARCHAR(120),
    max_members          SMALLINT     NOT NULL DEFAULT 2 CHECK (max_members BETWEEN 2 AND 100),
    ad_id                BIGINT,
    ad_title             VARCHAR(255),
    ad_price             VARCHAR(64),
    ad_image             VARCHAR(512),
    created_by           BIGINT,
    last_message_id      BIGINT       NOT NULL DEFAULT 0,
    last_message_preview VARCHAR(255),
    last_message_at      TIMESTAMPTZ,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_channels_ad_id ON chat_channels (ad_id);
CREATE INDEX IF NOT EXISTS idx_chat_channels_last_msg_at ON chat_channels (last_message_at DESC);

CREATE TABLE IF NOT EXISTS chat_channel_members (
    id                   BIGSERIAL PRIMARY KEY,
    channel_id           BIGINT      NOT NULL REFERENCES chat_channels (id) ON DELETE CASCADE,
    user_id              BIGINT      NOT NULL,
    role                 VARCHAR(16) NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    last_read_message_id BIGINT      NOT NULL DEFAULT 0,
    muted_until          TIMESTAMPTZ,
    joined_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (channel_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_members_user ON chat_channel_members (user_id, channel_id);

-- Multi-device sync cursor table (tracks `cur_max_message_id` per user + device + channel)
CREATE TABLE IF NOT EXISTS chat_device_sync_cursors (
    id                 BIGSERIAL PRIMARY KEY,
    user_id            BIGINT       NOT NULL,
    device_id          VARCHAR(128) NOT NULL,
    channel_id         BIGINT       NOT NULL REFERENCES chat_channels (id) ON DELETE CASCADE,
    cur_max_message_id BIGINT       NOT NULL DEFAULT 0,
    last_synced_at     TIMESTAMPTZ,
    UNIQUE (user_id, device_id, channel_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_device_sync_user_dev ON chat_device_sync_cursors (user_id, device_id);

-- Third-party Push Notification tokens (APNs / FCM / WebPush)
CREATE TABLE IF NOT EXISTS chat_push_tokens (
    id           BIGSERIAL PRIMARY KEY,
    user_id      BIGINT       NOT NULL,
    device_id    VARCHAR(128) NOT NULL,
    platform     VARCHAR(16)  NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    provider     VARCHAR(16)  NOT NULL CHECK (provider IN ('apns', 'fcm', 'webpush')),
    token        VARCHAR(512) NOT NULL,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    last_seen_at TIMESTAMPTZ,
    UNIQUE (user_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_push_tokens_user_active ON chat_push_tokens (user_id, is_active);

-- Presence state snapshot (updated by Presence Server heartbeats)
CREATE TABLE IF NOT EXISTS chat_user_presence (
    user_id            BIGINT PRIMARY KEY,
    status             VARCHAR(16) NOT NULL DEFAULT 'offline' CHECK (status IN ('online', 'offline')),
    last_heartbeat_at  TIMESTAMPTZ,
    last_active_at     TIMESTAMPTZ,
    presence_server_id VARCHAR(64)
);

-- ============================================================================
-- Key-Value Message Store Schema (Cassandra / Scylla / HBase / SQL-KV mirror)
-- Primary key: (channel_id, message_id) — fast range scans for sync & history.
-- Idempotency key: (channel_id, sender_id, client_message_id) — zero duplicates.
-- ============================================================================
CREATE TABLE IF NOT EXISTS chat_kv_messages (
    channel_id        BIGINT       NOT NULL,
    message_id        BIGINT       NOT NULL,
    sender_id         BIGINT       NOT NULL,
    client_message_id VARCHAR(128) NOT NULL,
    type              VARCHAR(16)  NOT NULL CHECK (type IN ('text', 'audio', 'image')),
    body              TEXT,
    metadata          JSONB,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (channel_id, message_id),
    UNIQUE (channel_id, sender_id, client_message_id)
);
