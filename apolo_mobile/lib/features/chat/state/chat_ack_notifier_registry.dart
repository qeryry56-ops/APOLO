import 'package:flutter/foundation.dart';

import '../models/chat_ack_models.dart';

/// Granular per-message ACK state registry backed by [ValueNotifier].
///
/// When a `message_ack` (`sent` ✓), `delivery_receipt` (`delivered` ✓✓), or
/// `read_receipt` (`read` ✓✓) arrives over the persistent WebSocket connection,
/// updating this registry notifies ONLY the affected 16×16px tick indicator
/// widget—eliminating full-list `setState` rebuilds and scroll jitter.
class ChatAckNotifierRegistry {
  final Map<String, ValueNotifier<ChatAckStatus>> _notifiers =
      <String, ValueNotifier<ChatAckStatus>>{};

  /// Maps canonical server `message_id` -> all linked local keys (e.g. `opt_1`,
  /// `id_opt_1`, `id_900001`) so range receipts (`upToMessageId`) and single-ID
  /// receipts both update every registered alias without overwriting one another.
  final Map<String, Set<String>> _serverIdToPrimaryKeys =
      <String, Set<String>>{};
  final Map<String, BigInt> _primaryKeyToServerBigInt = <String, BigInt>{};

  ValueListenable<ChatAckStatus> listenableFor(
    String primaryKey, {
    ChatAckStatus initial = ChatAckStatus.sent,
    String? serverMessageId,
  }) {
    final cleanKey = primaryKey.trim();
    if (serverMessageId != null && serverMessageId.trim().isNotEmpty) {
      linkServerId(cleanKey, serverMessageId.trim());
    }

    final existing = _notifiers[cleanKey];
    if (existing != null) {
      // Advance monotonically if initial snapshot from server is already further ahead
      if (initial.rank > existing.value.rank) {
        existing.value = initial;
      }
      return existing;
    }

    final created = ValueNotifier<ChatAckStatus>(initial);
    _notifiers[cleanKey] = created;
    return created;
  }

  void linkServerId(String primaryKey, String serverMessageId) {
    final cleanPrimary = primaryKey.trim();
    final cleanServer = serverMessageId.trim();
    if (cleanPrimary.isEmpty || cleanServer.isEmpty || cleanServer == '0') {
      return;
    }
    _serverIdToPrimaryKeys
        .putIfAbsent(cleanServer, () => <String>{})
        .add(cleanPrimary);
    final parsed = BigInt.tryParse(cleanServer);
    if (parsed != null && parsed > BigInt.zero) {
      _primaryKeyToServerBigInt[cleanPrimary] = parsed;
    }
  }

  /// Advances a single message's ACK status monotonically (never downgrades
  /// `read` -> `delivered` or `delivered` -> `sent`, unless explicitly `failed`
  /// from `sending` or retrying `failed` -> `sending`).
  void updateStatus(
    String keyOrServerId,
    ChatAckStatus nextStatus, {
    bool allowResetForRetry = false,
  }) {
    final clean = keyOrServerId.trim();
    if (clean.isEmpty) return;

    final targets = <String>{
      clean,
      ...?_serverIdToPrimaryKeys[clean],
    };

    for (final resolvedKey in targets) {
      final notifier = _notifiers[resolvedKey];
      if (notifier == null) {
        if (resolvedKey == clean && targets.length == 1) {
          _notifiers[resolvedKey] = ValueNotifier<ChatAckStatus>(nextStatus);
        }
        continue;
      }

      final current = notifier.value;
      if (nextStatus == current) continue;

      if (allowResetForRetry ||
          nextStatus == ChatAckStatus.failed ||
          nextStatus.rank > current.rank) {
        notifier.value = nextStatus;
      }
    }
  }

  /// Applies a server ACK (`sent` ✓) linking `clientMessageId` -> canonical `serverMessageId`.
  void applyServerAck({
    required String clientMessageId,
    required String serverMessageId,
    ChatAckStatus status = ChatAckStatus.sent,
  }) {
    if (clientMessageId.trim().isNotEmpty && serverMessageId.trim().isNotEmpty) {
      linkServerId(clientMessageId, serverMessageId);
      linkServerId('id_$clientMessageId', serverMessageId);
    }
    updateStatus(clientMessageId, status);
    updateStatus('id_$clientMessageId', status);
    if (serverMessageId.trim().isNotEmpty) {
      updateStatus('id_$serverMessageId', status);
    }
  }

  /// Applies a Delivered (`✓✓`) or Read (`✓✓`) receipt for explicit message IDs
  /// and/or all messages with `message_id <= upToMessageId`.
  void applyReceipt({
    required ChatAckStatus status,
    Iterable<String> messageIds = const <String>[],
    Iterable<String> clientMessageIds = const <String>[],
    String? upToMessageId,
  }) {
    for (final mid in messageIds) {
      updateStatus(mid, status);
      updateStatus('id_$mid', status);
    }
    for (final cid in clientMessageIds) {
      updateStatus(cid, status);
      updateStatus('id_$cid', status);
    }

    if (upToMessageId != null && upToMessageId.trim().isNotEmpty) {
      final upToBig = BigInt.tryParse(upToMessageId.trim());
      if (upToBig != null && upToBig > BigInt.zero) {
        for (final entry in _primaryKeyToServerBigInt.entries) {
          if (entry.value <= upToBig) {
            updateStatus(entry.key, status);
          }
        }
      }
    }
  }

  ChatAckStatus? currentStatus(String primaryKey) =>
      _notifiers[primaryKey.trim()]?.value;

  void dispose() {
    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }
    _notifiers.clear();
    _serverIdToPrimaryKeys.clear();
    _primaryKeyToServerBigInt.clear();
  }
}
