import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import 'chat_websocket_transport.dart';

/// Presence state reported by the Stateful Presence Server.
class PeerPresenceState {
  final int userId;
  final bool isOnline;
  final DateTime? lastActiveAt;

  const PeerPresenceState({
    required this.userId,
    required this.isOnline,
    this.lastActiveAt,
  });

  factory PeerPresenceState.fromJson(Map<String, dynamic> json) {
    final uid = int.tryParse('${json['user_id'] ?? 0}') ?? 0;
    final status = (json['status'] ?? 'offline').toString().toLowerCase();
    final rawTs = json['last_active_at']?.toString();
    return PeerPresenceState(
      userId: uid,
      isOnline: status == 'online',
      lastActiveAt: rawTs != null && rawTs.isNotEmpty
          ? DateTime.tryParse(rawTs)?.toLocal()
          : null,
    );
  }
}

/// Persistent WebSocket Real-Time Chat & Presence Client (WhatsApp / Zero-Polling Architecture):
///
/// 1. Discovers the optimal Stateful WebSocket Gateway + `fallback_nodes` once via
///    `GET /chat/service-discovery` (ZERO periodic HTTP polling).
/// 2. Maintains a single persistent WebSocket connection with automatic
///    **Exponential Backoff + Jitter** reconnect and automatic gateway failover.
/// 3. Automatically emits `ack_delivered` when incoming messages (live or
///    Store-and-Forward offline flush) arrive, and provides `sendReadAck` when
///    the user views an active conversation.
/// 4. Streams real-time `message_ack` (✓), `delivery_receipt` (✓✓), and
///    `read_receipt` (✓✓) events plus per-channel `cur_max_message_id` resync.
class ChatRealtimeClient {
  static final ChatRealtimeClient instance = ChatRealtimeClient._internal();
  factory ChatRealtimeClient() => instance;
  ChatRealtimeClient._internal();

  static const String _deviceIdPrefsKey = 'apolo_chat_device_id_v1';
  static const String _cursorPrefix = 'apolo_chat_cursor_';

  ChatWebSocketTransport? _transport;
  StreamSubscription<String>? _msgSub;
  StreamSubscription<void>? _closeSub;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  String? _deviceId;
  int _userId = 0;
  String _userName = '';
  String? _activeWsUrl;
  final List<String> _gatewayPool = <String>[];
  int _gatewayIndex = 0;
  int _heartbeatIntervalMs = 10000;
  int _reconnectAttempt = 0;
  bool _authenticated = false;
  bool _connecting = false;
  bool _disposed = false;

  final Set<int> _subscribedPresenceUsers = <int>{};
  final Set<String> _activeSyncChannels = <String>{};
  final Map<int, PeerPresenceState> _presenceCache = <int, PeerPresenceState>{};

  final _messageCtrl =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final _ackCtrl =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final _deliveryReceiptCtrl =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final _readReceiptCtrl =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final _syncCtrl =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final _presenceCtrl =
      StreamController<PeerPresenceState>.broadcast(sync: true);
  final _typingCtrl =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final _connectionCtrl = StreamController<bool>.broadcast(sync: true);

  Stream<Map<String, dynamic>> get incomingMessages => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get messageAcks => _ackCtrl.stream;
  Stream<Map<String, dynamic>> get deliveryReceipts =>
      _deliveryReceiptCtrl.stream;
  Stream<Map<String, dynamic>> get readReceipts => _readReceiptCtrl.stream;
  Stream<Map<String, dynamic>> get syncResponses => _syncCtrl.stream;
  Stream<PeerPresenceState> get presenceUpdates => _presenceCtrl.stream;
  Stream<Map<String, dynamic>> get typingEvents => _typingCtrl.stream;
  Stream<bool> get connectionState => _connectionCtrl.stream;

  bool get isConnected => _authenticated && (_transport?.isOpen ?? false);
  String get deviceId => _deviceId ?? 'dev-pending';

  PeerPresenceState? cachedPresence(int userId) => _presenceCache[userId];

  /// Injects a real-time message directly onto [incomingMessages] so live streams
  /// and deterministic widget tests update UI immediately in 0ms without polling.
  void injectIncomingMessage(Map<String, dynamic> payload) {
    _disposed = false;
    _messageCtrl.add(payload);
  }

  /// Computes deterministic-bounded exponential backoff with jitter (`1s..30s`)
  /// to prevent thundering-herd reconnect storms when a cellular tower recovers.
  static int computeReconnectDelayMs(
    int attempt, {
    math.Random? random,
  }) {
    final clamped = attempt.clamp(1, 6);
    final baseMs = math.min(30000, 1000 * (1 << (clamped - 1)));
    final rng = random ?? math.Random();
    final jitterMs = rng.nextInt(math.max(250, (baseMs * 0.25).round()));
    return math.min(30000, baseMs + jitterMs);
  }

  Future<String> ensureDeviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdPrefsKey);
    if (existing != null && existing.isNotEmpty) {
      _deviceId = existing;
      return existing;
    }
    final rand = math.Random().nextInt(0x7fffffff).toRadixString(36);
    final generated = 'dev_${DateTime.now().millisecondsSinceEpoch}_$rand';
    await prefs.setString(_deviceIdPrefsKey, generated);
    _deviceId = generated;
    return generated;
  }

  Future<String> getChannelCursor(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_cursorPrefix$channelId') ?? '0';
  }

  Future<void> saveChannelCursor(String channelId, String messageId) async {
    final next = BigInt.tryParse(messageId) ?? BigInt.zero;
    if (next <= BigInt.zero) return;
    final prefs = await SharedPreferences.getInstance();
    final prev =
        BigInt.tryParse(prefs.getString('$_cursorPrefix$channelId') ?? '0') ??
            BigInt.zero;
    if (next > prev) {
      await prefs.setString('$_cursorPrefix$channelId', next.toString());
    }
  }

  /// Registers a channel as actively open so missed messages resync immediately
  /// after any reconnect without periodic HTTP polling.
  void registerActiveChannel(String channelId) {
    if (channelId.trim().isNotEmpty) {
      _activeSyncChannels.add(channelId.trim());
    }
  }

  void unregisterActiveChannel(String channelId) {
    _activeSyncChannels.remove(channelId.trim());
  }

  /// Discover optimal Chat Server WebSocket URL via Stateless Service Discovery,
  /// then establish the persistent WebSocket connection.
  Future<bool> connect({
    required int userId,
    required String userName,
    String? overrideWsUrl,
  }) async {
    if (userId <= 0) return false;
    _disposed = false;
    _userId = userId;
    _userName = userName;
    await ensureDeviceId();

    if (isConnected) return true;
    if (_connecting) return false;
    _connecting = true;

    try {
      String? wsUrl = overrideWsUrl;
      if (wsUrl == null || wsUrl.isEmpty) {
        wsUrl = await _discoverChatServerUrl(userId);
      } else if (!_gatewayPool.contains(wsUrl)) {
        _gatewayPool.insert(0, wsUrl);
      }
      if (wsUrl == null || wsUrl.isEmpty) {
        _connecting = false;
        return false;
      }

      _activeWsUrl = wsUrl;
      await _openSocket(wsUrl);
      _reconnectAttempt = 0;
      _connecting = false;
      return true;
    } catch (_) {
      _connecting = false;
      _authenticated = false;
      _connectionCtrl.add(false);
      _scheduleReconnect();
      return false;
    }
  }

  Future<String?> _discoverChatServerUrl(int userId) async {
    try {
      final res = await ApiClient()
          .dio
          .get(
            '/chat/service-discovery',
            queryParameters: {'user_id': userId},
            options: Options(
              sendTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
            ),
          )
          .timeout(const Duration(seconds: 3));
      final data = res.data is Map ? res.data['data'] : null;
      if (data is Map) {
        final hb = int.tryParse('${data['heartbeat_interval_ms'] ?? ''}');
        if (hb != null && hb >= 3000) {
          _heartbeatIntervalMs = hb;
        }
        final primary = (data['chat_server_ws_url'] ?? '').toString().trim();
        final pool = <String>[];
        if (primary.startsWith('ws://') || primary.startsWith('wss://')) {
          pool.add(primary);
        }
        final fallbacks = data['fallback_nodes'];
        if (fallbacks is List) {
          for (final item in fallbacks) {
            if (item is Map) {
              final fbUrl = (item['ws_url'] ?? '').toString().trim();
              if ((fbUrl.startsWith('ws://') || fbUrl.startsWith('wss://')) &&
                  !pool.contains(fbUrl)) {
                pool.add(fbUrl);
              }
            }
          }
        }
        if (pool.isNotEmpty) {
          _gatewayPool
            ..clear()
            ..addAll(pool);
          _gatewayIndex = 0;
          return pool.first;
        }
      }
    } catch (_) {
      // Service discovery unavailable -> caller handles gracefully without polling
    }
    return null;
  }

  Future<void> _openSocket(String url) async {
    await _teardownSocket();
    final transport = ChatWebSocketTransport();
    _transport = transport;
    await transport.connect(url);

    _msgSub = transport.messages.listen(_onRawFrame);
    _closeSub = transport.onClose.listen((_) {
      _authenticated = false;
      _heartbeatTimer?.cancel();
      _connectionCtrl.add(false);
      if (!_disposed) {
        _scheduleReconnect();
      }
    });

    _sendJson({
      'event': 'auth',
      'user_id': _userId,
      'user_name': _userName,
      'device_id': _deviceId,
      'backgrounded': false,
    });
  }

  void _onRawFrame(String raw) {
    Map<String, dynamic> packet;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      packet = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    final event = (packet['event'] ?? '').toString();
    switch (event) {
      case 'auth_ok':
        _authenticated = true;
        _reconnectAttempt = 0;
        final hb = int.tryParse('${packet['heartbeat_interval_ms'] ?? ''}');
        if (hb != null && hb >= 3000) _heartbeatIntervalMs = hb;
        _startHeartbeat();
        _connectionCtrl.add(true);
        if (_subscribedPresenceUsers.isNotEmpty) {
          _sendJson({
            'event': 'presence_subscribe',
            'user_ids': _subscribedPresenceUsers.toList(),
          });
        }
        for (final ch in _activeSyncChannels) {
          unawaited(requestChannelSync(ch));
        }
        break;
      case 'message':
        final data = packet['data'];
        if (data is Map) {
          final msg = Map<String, dynamic>.from(data);
          final ch = (msg['channel_id'] ?? '').toString();
          final mid = (msg['message_id'] ?? '').toString();
          final senderId = int.tryParse('${msg['sender_id'] ?? 0}') ?? 0;
          if (ch.isNotEmpty && mid.isNotEmpty) {
            saveChannelCursor(ch, mid);
            // Stage 2 ACK (`delivered` ✓✓): automatically acknowledge receipt
            // back to the gateway so Store-and-Forward purges the queue and
            // notifies the sender in real time.
            if (senderId > 0 && senderId != _userId) {
              sendDeliveredAck(
                channelId: ch,
                messageIds: [mid],
                senderId: senderId,
              );
            }
          }
          _messageCtrl.add(msg);
        }
        break;
      case 'message_ack':
        final ch = (packet['channel_id'] ?? '').toString();
        final mid = (packet['message_id'] ?? '').toString();
        if (ch.isNotEmpty && mid.isNotEmpty) {
          saveChannelCursor(ch, mid);
        }
        _ackCtrl.add(packet);
        break;
      case 'delivery_receipt':
        _deliveryReceiptCtrl.add(packet);
        break;
      case 'read_receipt':
        _readReceiptCtrl.add(packet);
        break;
      case 'sync_response':
        final ch = (packet['channel_id'] ?? '').toString();
        final cur = (packet['cur_max_message_id'] ?? '').toString();
        if (ch.isNotEmpty && cur.isNotEmpty) {
          saveChannelCursor(ch, cur);
        }
        final syncedMsgs = packet['messages'];
        if (ch.isNotEmpty && syncedMsgs is List && syncedMsgs.isNotEmpty) {
          final peerMsgIds = <String>[];
          for (final item in syncedMsgs) {
            if (item is Map) {
              final sid = int.tryParse('${item['sender_id'] ?? 0}') ?? 0;
              final mid = (item['message_id'] ?? '').toString();
              if (sid > 0 && sid != _userId && mid.isNotEmpty) {
                peerMsgIds.add(mid);
              }
            }
          }
          if (peerMsgIds.isNotEmpty) {
            sendDeliveredAck(channelId: ch, messageIds: peerMsgIds);
          }
        }
        _syncCtrl.add(packet);
        break;
      case 'presence_snapshot':
        final data = packet['data'];
        if (data is Map) {
          for (final entry in data.entries) {
            if (entry.value is Map) {
              final state = PeerPresenceState.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              );
              if (state.userId > 0) {
                _presenceCache[state.userId] = state;
                _presenceCtrl.add(state);
              }
            }
          }
        }
        break;
      case 'presence_update':
        final data = packet['data'];
        if (data is Map) {
          final state = PeerPresenceState.fromJson(
            Map<String, dynamic>.from(data),
          );
          if (state.userId > 0) {
            _presenceCache[state.userId] = state;
            _presenceCtrl.add(state);
          }
        }
        break;
      case 'typing':
        _typingCtrl.add(packet);
        break;
    }
  }

  void subscribePresence(int peerUserId) {
    if (peerUserId <= 0) return;
    _subscribedPresenceUsers.add(peerUserId);
    if (isConnected) {
      _sendJson({
        'event': 'presence_subscribe',
        'user_ids': [peerUserId],
      });
    }
  }

  Future<void> requestChannelSync(String channelId) async {
    if (!isConnected || channelId.isEmpty) return;
    final cursor = await getChannelCursor(channelId);
    _sendJson({
      'event': 'sync_request',
      'channel_id': channelId,
      'after_message_id': cursor,
      'limit': 100,
    });
  }

  bool sendMessage({
    required String channelId,
    required List<int> recipientIds,
    required String clientMessageId,
    required String type,
    required String body,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? adContext,
    String channelType = 'direct',
  }) {
    if (!isConnected) return false;
    _sendJson({
      'event': 'send_message',
      'channel_id': channelId,
      'channel_type': channelType,
      'recipient_ids': recipientIds,
      'client_message_id': clientMessageId,
      'type': type,
      'body': body,
      if (metadata != null) 'metadata': metadata,
      if (adContext != null) 'ad_context': adContext,
    });
    return true;
  }

  /// Stage 2 ACK (`delivered` ✓✓): confirms receipt of incoming message(s) on this device.
  void sendDeliveredAck({
    required String channelId,
    List<String> messageIds = const <String>[],
    String? lastDeliveredMessageId,
    int? senderId,
  }) {
    if (!isConnected || channelId.isEmpty) return;
    if (messageIds.isEmpty &&
        (lastDeliveredMessageId == null || lastDeliveredMessageId.isEmpty)) {
      return;
    }
    _sendJson({
      'event': 'ack_delivered',
      'channel_id': channelId,
      if (messageIds.isNotEmpty) 'message_ids': messageIds,
      if (lastDeliveredMessageId != null && lastDeliveredMessageId.isNotEmpty)
        'last_delivered_message_id': lastDeliveredMessageId,
      if (senderId != null && senderId > 0) 'sender_id': senderId,
    });
  }

  /// Stage 3 ACK (`read` ✓✓): confirms messages up to [lastReadMessageId] were viewed in-chat.
  void sendReadAck({
    required String channelId,
    required String lastReadMessageId,
    int? senderId,
  }) {
    if (!isConnected || channelId.isEmpty || lastReadMessageId.isEmpty) return;
    _sendJson({
      'event': 'ack_read',
      'channel_id': channelId,
      'last_read_message_id': lastReadMessageId,
      if (senderId != null && senderId > 0) 'sender_id': senderId,
    });
  }

  void sendTyping(String channelId, bool isTyping) {
    if (!isConnected || channelId.isEmpty) return;
    _sendJson({
      'event': 'typing',
      'channel_id': channelId,
      'is_typing': isTyping,
    });
  }

  void setBackgrounded(bool backgrounded) {
    if (!isConnected) return;
    _sendJson({
      'event': 'heartbeat',
      'backgrounded': backgrounded,
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: _heartbeatIntervalMs),
      (_) {
        if (isConnected) {
          _sendJson({'event': 'heartbeat'});
        }
      },
    );
  }

  void _scheduleReconnect() {
    if (_disposed || _userId <= 0) return;
    final targetUrl = _nextGatewayUrl();
    if (targetUrl == null) return;

    _reconnectTimer?.cancel();
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(1, 6);
    final delayMs = computeReconnectDelayMs(_reconnectAttempt);

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_disposed && !isConnected) {
        connect(
          userId: _userId,
          userName: _userName,
          overrideWsUrl: targetUrl,
        );
      }
    });
  }

  String? _nextGatewayUrl() {
    if (_gatewayPool.isNotEmpty) {
      _gatewayIndex = (_gatewayIndex + 1) % _gatewayPool.length;
      return _gatewayPool[_gatewayIndex];
    }
    return _activeWsUrl;
  }

  void _sendJson(Map<String, dynamic> payload) {
    try {
      _transport?.send(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> _teardownSocket() async {
    _heartbeatTimer?.cancel();
    await _msgSub?.cancel();
    await _closeSub?.cancel();
    _msgSub = null;
    _closeSub = null;
    await _transport?.close();
    _transport = null;
    _authenticated = false;
  }

  Future<void> disconnect() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _teardownSocket();
  }

  /// Guarantees zero duplicate messages across WebSocket, multi-device sync,
  /// optimistic pending queue, and Firestore/REST fallback by deduplicating
  /// on `client_message_id`/`local_id`, canonical `message_id`/`doc_id`/`id`,
  /// and short-window semantic sender+body fingerprint.
  static List<Map<String, dynamic>> deduplicateMessages(
    List<Map<String, dynamic>> messages,
  ) {
    final seenClientIds = <String>{};
    final seenServerIds = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final m in messages) {
      final clientId =
          (m['client_message_id'] ?? m['local_id'] ?? m['_local_id'] ?? '')
              .toString()
              .trim();
      final serverId =
          (m['message_id'] ?? m['doc_id'] ?? m['id'] ?? '').toString().trim();

      if (clientId.isNotEmpty && seenClientIds.contains(clientId)) continue;
      if (serverId.isNotEmpty &&
          serverId != '0' &&
          seenServerIds.contains(serverId)) {
        continue;
      }

      final body = (m['body'] ?? '').toString().trim();
      final msgType = (m['type'] ?? 'text').toString();
      final isMine = m['is_mine'] == true;
      final senderId = (m['sender_id'] ?? '').toString().trim();
      final createdMs = int.tryParse('${m['created_at_ms'] ?? 0}') ?? 0;

      if (body.isNotEmpty && msgType == 'text') {
        final duplicateIdx = result.indexWhere((prev) {
          if ((prev['type'] ?? 'text').toString() != 'text') return false;
          if ((prev['is_mine'] == true) != isMine) return false;
          final prevSender = (prev['sender_id'] ?? '').toString().trim();
          if (senderId.isNotEmpty &&
              prevSender.isNotEmpty &&
              senderId != prevSender) {
            return false;
          }
          if ((prev['body'] ?? '').toString().trim() != body) return false;
          final prevId =
              (prev['message_id'] ?? prev['doc_id'] ?? prev['id'] ?? '')
                  .toString()
                  .trim();
          final prevIsPending = prev['_pending'] == true ||
              prevId.startsWith('opt_') ||
              prevId.startsWith('srv_');
          final curIsPending = m['_pending'] == true ||
              serverId.startsWith('opt_') ||
              serverId.startsWith('srv_');
          // Only collapse across distinct transports (e.g. optimistic/Firestore vs Backend)
          // within a tight window so legitimate repeated user texts aren't dropped if both have distinct real IDs from same source.
          if (!prevIsPending &&
              !curIsPending &&
              prev['doc_id'] != null &&
              m['doc_id'] != null &&
              prev['doc_id'] != m['doc_id']) {
            return false;
          }
          if (!prevIsPending &&
              !curIsPending &&
              prev['doc_id'] == null &&
              m['doc_id'] == null &&
              prevId.isNotEmpty &&
              serverId.isNotEmpty &&
              prevId != serverId) {
            return false;
          }
          final prevMs = int.tryParse('${prev['created_at_ms'] ?? 0}') ?? 0;
          if (createdMs > 0 && prevMs > 0) {
            return (createdMs - prevMs).abs() <= 90000;
          }
          return prevIsPending || curIsPending;
        });

        if (duplicateIdx >= 0) {
          // Prefer confirmed server/Firestore copy over pending optimistic copy
          if (result[duplicateIdx]['_pending'] == true &&
              m['_pending'] != true) {
            result[duplicateIdx] = m;
          }
          if (clientId.isNotEmpty) seenClientIds.add(clientId);
          if (serverId.isNotEmpty && serverId != '0') {
            seenServerIds.add(serverId);
          }
          continue;
        }
      }

      if (clientId.isNotEmpty) seenClientIds.add(clientId);
      if (serverId.isNotEmpty && serverId != '0') seenServerIds.add(serverId);
      result.add(m);
    }

    return result;
  }
}
