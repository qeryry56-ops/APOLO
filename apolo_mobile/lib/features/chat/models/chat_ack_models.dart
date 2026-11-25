/// Core real-time chat ACK & offline sync models for Apolo.ma.
library;

/// Explicit 3-stage WhatsApp-style acknowledgement lifecycle plus optimistic states:
/// - [sending]: Optimistic local bubble before backend confirms receipt
/// - [sent]: Server ACK (`✓`) — received & persisted/queued by backend
/// - [delivered]: Recipient Device ACK (`✓✓`) — received by recipient's device
/// - [read]: Conversation Read ACK (`✓✓` highlighted) — viewed inside active chat
/// - [failed]: Delivery failed locally -> inline retry without toast/spinner
enum ChatAckStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

extension ChatAckStatusCodec on ChatAckStatus {
  String get wireValue => switch (this) {
        ChatAckStatus.sending => 'sending',
        ChatAckStatus.sent => 'sent',
        ChatAckStatus.delivered => 'delivered',
        ChatAckStatus.read => 'read',
        ChatAckStatus.failed => 'failed',
      };

  /// Monotonic precedence rank so an out-of-order network packet can never
  /// downgrade `read` back to `delivered` or `delivered` back to `sent`.
  int get rank => switch (this) {
        ChatAckStatus.failed => -1,
        ChatAckStatus.sending => 0,
        ChatAckStatus.sent => 1,
        ChatAckStatus.delivered => 2,
        ChatAckStatus.read => 3,
      };

  static ChatAckStatus fromWire(Object? raw, {bool? isRead, bool? isDelivered}) {
    final normalized = (raw ?? '').toString().trim().toLowerCase();
    switch (normalized) {
      case 'sending':
      case 'pending':
        return ChatAckStatus.sending;
      case 'sent':
        return ChatAckStatus.sent;
      case 'delivered':
        return ChatAckStatus.delivered;
      case 'read':
      case 'seen':
        return ChatAckStatus.read;
      case 'failed':
        return ChatAckStatus.failed;
    }
    if (isRead == true) return ChatAckStatus.read;
    if (isDelivered == true) return ChatAckStatus.delivered;
    return ChatAckStatus.sent;
  }
}

class ChatMessageRecord {
  final String clientMessageId;
  final String messageId;
  final String channelId;
  final int senderId;
  final String senderName;
  final String type;
  final String body;
  final DateTime createdAt;
  final ChatAckStatus ackStatus;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final Map<String, dynamic> metadata;

  const ChatMessageRecord({
    required this.clientMessageId,
    required this.messageId,
    required this.channelId,
    required this.senderId,
    this.senderName = '',
    this.type = 'text',
    required this.body,
    required this.createdAt,
    this.ackStatus = ChatAckStatus.sent,
    this.deliveredAt,
    this.readAt,
    this.metadata = const <String, dynamic>{},
  });

  factory ChatMessageRecord.fromJson(Map<String, dynamic> json) {
    final createdRaw = (json['created_at'] ?? '').toString();
    final createdDt = DateTime.tryParse(createdRaw)?.toLocal() ??
        (json['created_at_ms'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['created_at_ms'] as int)
            : DateTime.now());
    final deliveredRaw = json['delivered_at']?.toString();
    final readRaw = json['read_at']?.toString();

    return ChatMessageRecord(
      clientMessageId:
          (json['client_message_id'] ?? json['local_id'] ?? '').toString(),
      messageId: (json['message_id'] ?? json['id'] ?? '').toString(),
      channelId: (json['channel_id'] ?? '').toString(),
      senderId: int.tryParse('${json['sender_id'] ?? 0}') ?? 0,
      senderName: (json['sender_name'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: createdDt,
      ackStatus: ChatAckStatusCodec.fromWire(
        json['ack_status'],
        isRead: json['read'] == true || (readRaw != null && readRaw.isNotEmpty),
        isDelivered: json['delivered'] == true ||
            (deliveredRaw != null && deliveredRaw.isNotEmpty),
      ),
      deliveredAt: deliveredRaw != null && deliveredRaw.isNotEmpty
          ? DateTime.tryParse(deliveredRaw)?.toLocal()
          : null,
      readAt: readRaw != null && readRaw.isNotEmpty
          ? DateTime.tryParse(readRaw)?.toLocal()
          : null,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const <String, dynamic>{},
    );
  }
}

class ChatSyncState {
  final String channelId;
  final String deviceId;
  final String curMaxMessageId;
  final int pendingQueueFlushedCount;

  const ChatSyncState({
    required this.channelId,
    required this.deviceId,
    required this.curMaxMessageId,
    this.pendingQueueFlushedCount = 0,
  });
}
