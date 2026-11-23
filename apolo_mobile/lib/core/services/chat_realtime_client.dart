import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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

/// Real-time Chat & Presence Client (ByteByteGo Architecture):
///
/// 1. Calls Stateless Service Discovery (`GET /chat/service-discovery`) over HTTP
///    to obtain the optimal Stateful WebSocket Chat Server hostname.
/// 2. Maintains a persistent bidirectional WebSocket connection with automatic
///    exponential-backoff reconnect.
/// 3. Sends periodic Presence heartbeats and receives live `presence_update`
///    events for subscribed peers.
/// 4. Tracks a persistent per-device `device_id` and per-channel `cur_max_message_id`
///    cursor for multi-device & offline catch-up sync without duplicate messages.
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
  int _heartbeatIntervalMs = 10000;
  int _reconnectAttempt = 0;
  bool _authenticated = false;
  bool _connecting = false;
  bool _disposed = false;

  final Set<int> _subscribedPresenceUsers = <int>{};
  final Map<int, PeerPresenceState> _presenceCache = <int, PeerPresenceState>{};

  final _messageCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _ackCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _syncCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceCtrl = StreamController<PeerPresenceState>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionCtrl = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get incomingMessages => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get messageAcks => _ackCtrl.stream;
  Stream<Map<String, dynamic>> get syncResponses => _syncCtrl.stream;
  Stream<PeerPresenceState> get presenceUpdates => _presenceCtrl.stream;
  Stream<Map<String, dynamic>> get typingEvents => _typingCtrl.stream;
  Stream<bool> get connectionState => _connectionCtrl.stream;

  bool get isConnected => _authenticated && (_transport?.isOpen ?? false);
  String get deviceId => _deviceId ?? 'dev-pending';

  PeerPresenceState? cachedPresence(int userId) => _presenceCache[userId];

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
      final res = await ApiClient().dio.get(
            '/chat/service-discovery',
            queryParameters: {'user_id': userId},
          );
      final data = res.data is Map ? res.data['data'] : null;
      if (data is Map) {
        final hb = int.tryParse('${data['heartbeat_interval_ms'] ?? ''}');
        if (hb != null && hb >= 3000) {
          _heartbeatIntervalMs = hb;
        }
        final url = (data['chat_server_ws_url'] ?? '').toString().trim();
        if (url.startsWith('ws://') || url.startsWith('wss://')) {
          return url;
        }
      }
    } catch (_) {
      // Service discovery unavailable (e.g. static preview) -> caller falls back cleanly
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
        break;
      case 'message':
        final data = packet['data'];
        if (data is Map) {
          final msg = Map<String, dynamic>.from(data);
          final ch = (msg['channel_id'] ?? '').toString();
          final mid = (msg['message_id'] ?? '').toString();
          if (ch.isNotEmpty && mid.isNotEmpty) {
            saveChannelCursor(ch, mid);
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
      case 'sync_response':
        final ch = (packet['channel_id'] ?? '').toString();
        final cur = (packet['cur_max_message_id'] ?? '').toString();
        if (ch.isNotEmpty && cur.isNotEmpty) {
          saveChannelCursor(ch, cur);
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
    if (_disposed || _userId <= 0 || _activeWsUrl == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(1, 6);
    final delaySec = math.min(30, 1 << _reconnectAttempt);
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (!_disposed && !isConnected) {
        connect(
          userId: _userId,
          userName: _userName,
          overrideWsUrl: _activeWsUrl,
        );
      }
    });
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
  /// on `client_message_id` and canonical `message_id`/`id`.
  static List<Map<String, dynamic>> deduplicateMessages(
    List<Map<String, dynamic>> messages,
  ) {
    final seenClientIds = <String>{};
    final seenServerIds = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final m in messages) {
      final clientId =
          (m['client_message_id'] ?? m['_local_id'] ?? '').toString().trim();
      final serverId = (m['message_id'] ?? m['id'] ?? '').toString().trim();

      if (clientId.isNotEmpty && seenClientIds.contains(clientId)) continue;
      if (serverId.isNotEmpty &&
          serverId != '0' &&
          seenServerIds.contains(serverId)) {
        continue;
      }

      if (clientId.isNotEmpty) seenClientIds.add(clientId);
      if (serverId.isNotEmpty && serverId != '0') seenServerIds.add(serverId);
      result.add(m);
    }

    return result;
  }
}
