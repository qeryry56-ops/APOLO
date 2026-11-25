import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/chat_ack_models.dart';
import '../theme/apolo_chat_dl_tokens.dart';

/// Compact, zero-jitter WhatsApp-style Message ACK indicator (`✓` / `✓✓` / `✓✓`).
///
/// Subscribes directly to a per-message [ValueListenable<ChatAckStatus>] so
/// live WebSocket `message_ack`, `delivery_receipt`, and `read_receipt` updates
/// repaint only this 16px indicator without rebuilding the message list.
class ChatAckIndicator extends StatelessWidget {
  final ValueListenable<ChatAckStatus>? statusListenable;
  final ChatAckStatus fallbackStatus;
  final bool onRedSurface;
  final String? semanticPrefix;

  const ChatAckIndicator({
    super.key,
    this.statusListenable,
    this.fallbackStatus = ChatAckStatus.sent,
    this.onRedSurface = false,
    this.semanticPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final listenable = statusListenable;
    if (listenable == null) {
      return _buildGlyph(fallbackStatus);
    }
    return ValueListenableBuilder<ChatAckStatus>(
      valueListenable: listenable,
      builder: (_, status, __) => _buildGlyph(status),
    );
  }

  Widget _buildGlyph(ChatAckStatus status) {
    final (IconData icon, Color color, String semantics) = switch (status) {
      ChatAckStatus.sending => (
          Icons.schedule_rounded,
          onRedSurface
              ? ApoloChatDlTokens.pureWhite.withValues(alpha: 0.72)
              : ApoloChatDlTokens.ackSentColor,
          'Sending',
        ),
      ChatAckStatus.sent => (
          Icons.done_rounded,
          onRedSurface
              ? ApoloChatDlTokens.pureWhite.withValues(alpha: 0.80)
              : ApoloChatDlTokens.ackSentColor,
          'Sent to server',
        ),
      ChatAckStatus.delivered => (
          Icons.done_all_rounded,
          onRedSurface
              ? ApoloChatDlTokens.pureWhite.withValues(alpha: 0.86)
              : ApoloChatDlTokens.ackDeliveredColor,
          'Delivered to device',
        ),
      ChatAckStatus.read => (
          Icons.done_all_rounded,
          onRedSurface
              ? ApoloChatDlTokens.pureWhite
              : ApoloChatDlTokens.ackReadColor,
          'Read',
        ),
      ChatAckStatus.failed => (
          Icons.error_outline_rounded,
          ApoloChatDlTokens.primaryRed,
          'Failed to send',
        ),
    };

    return Semantics(
      label: semanticPrefix != null ? '$semanticPrefix: $semantics' : semantics,
      child: Icon(
        icon,
        size: 14.5,
        color: color,
      ),
    );
  }
}
