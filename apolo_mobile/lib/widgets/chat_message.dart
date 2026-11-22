import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../screens/widgets/app_image.dart';
import '../screens/widgets/chat_utils.dart';

/// Delivery status for a [ChatMessage] bubble (Rule 3: Optimistic UI).
enum ChatMessageStatus {
  sending,
  sent,
  read,
  failed,
}

/// Precomputed layout & grouping metadata for a single message in a virtualized list.
class ChatMessageGroupMeta {
  final bool showDateDivider;
  final String? dateLabel;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showAvatar;
  final double topSpacing;

  const ChatMessageGroupMeta({
    required this.showDateDivider,
    this.dateLabel,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.showAvatar,
    required this.topSpacing,
  });
}

/// Reusable, low-noise chat message bubble implementing Rules 1, 2, and 3:
/// - Rule 1 (Message Grouping): Shows only 1 avatar at the top of a 2-minute same-sender group,
///   no avatar on consecutive messages, and 8px spacing between different senders.
/// - Rule 2 (Precision on Demand): Hides timestamp by default; reveals exact timestamp
///   only on desktop hover or mobile long-press. Shows date divider only when date changes.
/// - Rule 3 (Optimistic UI): Renders immediately with no loading spinner; if sending fails,
///   displays an inline retry button directly on the bubble instead of a toast.
class ChatMessage extends StatefulWidget {
  final String messageKey;
  final String body;
  final bool isMine;
  final String senderName;
  final String? senderAvatar;
  final String timestamp;
  final DateTime? createdAt;
  final ChatMessageStatus status;
  final bool showAvatar;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final double topSpacing;
  final bool showDateDivider;
  final String? dateLabel;
  final bool isDeleted;
  final bool isEdited;
  final bool isPinned;
  final bool isStarred;
  final List<String> reactions;
  final Uint8List? imageBytes;
  final Widget? customContent;
  final VoidCallback? onRetry;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onImageTap;
  final VoidCallback? onOpenActions;
  final String retryLabel;
  final bool useRichTextForBody;

  const ChatMessage({
    super.key,
    required this.messageKey,
    required this.body,
    required this.isMine,
    required this.senderName,
    this.senderAvatar,
    this.timestamp = '',
    this.createdAt,
    this.status = ChatMessageStatus.sent,
    this.showAvatar = true,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.topSpacing = interSenderSpacing,
    this.showDateDivider = false,
    this.dateLabel,
    this.isDeleted = false,
    this.isEdited = false,
    this.isPinned = false,
    this.isStarred = false,
    this.reactions = const <String>[],
    this.imageBytes,
    this.customContent,
    this.onRetry,
    this.onAvatarTap,
    this.onImageTap,
    this.onOpenActions,
    this.retryLabel = 'Retry',
    this.useRichTextForBody = false,
  });

  /// Rule 1: Maximum time window (2 minutes) to group consecutive messages from the same sender.
  static const Duration groupingWindow = Duration(minutes: 2);

  /// Rule 1: Exact 8px vertical spacing between messages from different senders.
  static const double interSenderSpacing = 8.0;

  /// Compact vertical spacing between consecutive grouped messages from the same sender.
  static const double intraGroupSpacing = 2.0;

  /// Fixed avatar diameter for sender alignment.
  static const double avatarSize = 28.0;

  /// Gap between avatar column and message bubble.
  static const double avatarGap = 8.0;

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _surfaceGrey = Color(0xFFF2F3F7);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textSubtle = Color(0xFF9CA3AF);
  static const Color _errorRed = Color(0xFFD9261C);

  /// Extracts a [DateTime] from a raw message map if available.
  static DateTime? parseTimestamp(
    Map<String, dynamic> msg, {
    DateTime? referenceDate,
  }) {
    final direct = msg['created_at'] ?? msg['timestamp'];
    if (direct is DateTime) return direct.toLocal();
    if (direct is String && direct.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(direct.trim());
      if (parsed != null) return parsed.toLocal();
    }

    final msRaw = msg['created_at_ms'];
    final ms = msRaw is int ? msRaw : int.tryParse('${msRaw ?? ''}');
    if (ms != null && ms > 0) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    final clockRaw = (msg['created_at_time'] ?? '').toString().trim();
    if (clockRaw.isNotEmpty) {
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$',
      ).firstMatch(clockRaw);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String? ampm = match.group(3)?.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        final base = referenceDate ?? DateTime.now();
        return DateTime(base.year, base.month, base.day, hour, minute);
      }
    }
    return null;
  }

  /// Checks whether [msg] carries an explicit calendar date (not just a clock string).
  static bool hasExplicitCalendarDate(Map<String, dynamic> msg) {
    if (msg['date_label'] != null &&
        msg['date_label'].toString().trim().isNotEmpty) {
      return true;
    }
    if (msg['created_at'] != null || msg['timestamp'] != null) {
      return true;
    }
    final msRaw = msg['created_at_ms'];
    final ms = msRaw is int ? msRaw : int.tryParse('${msRaw ?? ''}');
    return ms != null && ms > 0;
  }

  /// Returns a normalized sender identifier for grouping checks.
  static String senderKeyOf(Map<String, dynamic> msg) {
    final isMine = msg['is_mine'] == true;
    final rawId = (msg['sender_id'] ?? '').toString().trim();
    if (rawId.isNotEmpty) return '${isMine ? "me" : "peer"}:$rawId';
    final rawName = (msg['sender_name'] ?? '').toString().trim();
    if (rawName.isNotEmpty) return '${isMine ? "me" : "peer"}:$rawName';
    return isMine ? 'me' : 'peer';
  }

  /// Rule 1: Determines whether [curr] belongs to the same group as [prev]
  /// (same sender, same calendar date, and within 2 minutes).
  static bool shouldGroupWithPrevious(
    Map<String, dynamic> prev,
    Map<String, dynamic> curr,
  ) {
    if (senderKeyOf(prev) != senderKeyOf(curr)) return false;

    final prevDateLabel = (prev['date_label'] ?? '').toString().trim();
    final currDateLabel = (curr['date_label'] ?? '').toString().trim();
    if (prevDateLabel.isNotEmpty &&
        currDateLabel.isNotEmpty &&
        prevDateLabel != currDateLabel) {
      return false;
    }

    final prevDt = parseTimestamp(prev);
    final currDt = parseTimestamp(curr);
    if (prevDt != null && currDt != null) {
      if (!isSameChatDay(prevDt, currDt)) return false;
      final diff = currDt.difference(prevDt).abs();
      return diff <= groupingWindow;
    }
    return true;
  }

  /// Precomputes O(N) grouping and date-divider metadata for a virtualized message list.
  static List<ChatMessageGroupMeta> computeGrouping(
    List<Map<String, dynamic>> messages, {
    AppStrings? strings,
  }) {
    if (messages.isEmpty) return const <ChatMessageGroupMeta>[];
    final s = strings ?? AppStrings('en');
    final int n = messages.length;
    final firstInGroup = List<bool>.filled(n, false);
    final showDate = List<bool>.filled(n, false);
    final dateLabels = List<String?>.filled(n, null);
    final topSpacings = List<double>.filled(n, 0.0);

    DateTime? lastExplicitDate;
    String? lastExplicitLabel;

    for (int i = 0; i < n; i++) {
      final curr = messages[i];
      final explicitLabel = (curr['date_label'] ?? '').toString().trim();
      final currDt = parseTimestamp(curr);
      final hasDate = hasExplicitCalendarDate(curr);

      bool dateChanged = false;
      String? resolvedLabel;

      if (explicitLabel.isNotEmpty) {
        if (lastExplicitLabel != explicitLabel) {
          dateChanged = true;
          resolvedLabel = explicitLabel;
          lastExplicitLabel = explicitLabel;
        }
      } else if (hasDate && currDt != null) {
        if (lastExplicitDate == null ||
            !isSameChatDay(lastExplicitDate, currDt)) {
          dateChanged = true;
          resolvedLabel = formatChatDayLabel(currDt, s);
          lastExplicitDate = currDt;
        }
      }

      showDate[i] = dateChanged;
      dateLabels[i] = resolvedLabel;

      if (i == 0) {
        firstInGroup[i] = true;
        topSpacings[i] = 0.0;
      } else {
        final prev = messages[i - 1];
        final grouped = !dateChanged && shouldGroupWithPrevious(prev, curr);
        firstInGroup[i] = !grouped;
        final sameSender = senderKeyOf(prev) == senderKeyOf(curr);
        // Rule 1: Keep 8px spacing between messages from different senders.
        topSpacings[i] = !sameSender
            ? interSenderSpacing
            : (grouped ? intraGroupSpacing : interSenderSpacing);
      }
    }

    final result = List<ChatMessageGroupMeta>.generate(n, (i) {
      final isFirst = firstInGroup[i];
      final isLast = (i == n - 1) || firstInGroup[i + 1];
      return ChatMessageGroupMeta(
        showDateDivider: showDate[i],
        dateLabel: dateLabels[i],
        isFirstInGroup: isFirst,
        isLastInGroup: isLast,
        showAvatar: isFirst,
        topSpacing: topSpacings[i],
      );
    });

    return result;
  }

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  bool _isHovered = false;
  bool _isTimestampPinned = false;

  bool get _shouldShowTimestamp =>
      widget.timestamp.trim().isNotEmpty &&
      (_isHovered || _isTimestampPinned);

  void _handleLongPress() {
    setState(() {
      _isTimestampPinned = !_isTimestampPinned;
    });
  }

  Widget _buildAvatar() {
    final avatarUrl = widget.senderAvatar?.trim() ?? '';
    return GestureDetector(
      onTap: widget.onAvatarTap,
      child: Container(
        key: Key('chat-avatar-${widget.messageKey}'),
        width: ChatMessage.avatarSize,
        height: ChatMessage.avatarSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: ChatMessage._surfaceGrey,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: avatarUrl.isNotEmpty
              ? AppImage(
                  url: avatarUrl,
                  width: ChatMessage.avatarSize,
                  height: ChatMessage.avatarSize,
                  fit: BoxFit.cover,
                  fallback: ChatInitialAvatar(
                    name: widget.senderName,
                    size: ChatMessage.avatarSize,
                  ),
                )
              : ChatInitialAvatar(
                  name: widget.senderName,
                  size: ChatMessage.avatarSize,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    final isFailed = widget.status == ChatMessageStatus.failed;
    final isDeleted = widget.isDeleted;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 700;
    final maxBubbleWidth =
        isDesktop ? 520.0 : (screenWidth * 0.74).clamp(200.0, 420.0);

    final borderRadius = BorderRadiusDirectional.only(
      topStart: Radius.circular(
        !isMine && !widget.isFirstInGroup ? 6 : 18,
      ),
      topEnd: Radius.circular(
        isMine && !widget.isFirstInGroup ? 6 : 18,
      ),
      bottomStart: Radius.circular(
        isMine ? 18 : (widget.isLastInGroup ? 4 : 6),
      ),
      bottomEnd: Radius.circular(
        isMine ? (widget.isLastInGroup ? 4 : 6) : 18,
      ),
    );

    final uniqueEmojis = widget.reactions
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .take(4)
        .join(' ');

    final bubbleBg = isDeleted
        ? ChatMessage._surfaceGrey
        : isFailed
            ? const Color(0xFFFEF2F2)
            : (isMine ? ChatMessage._ink : ChatMessage._surfaceGrey);

    final textColor = isDeleted
        ? ChatMessage._textMuted
        : isFailed
            ? ChatMessage._errorRed
            : (isMine ? Colors.white : ChatMessage._ink);

    final semanticStatus = isFailed
        ? ', Send failed, double tap to retry'
        : (widget.status == ChatMessageStatus.sending ? ', Sending' : '');
    final semanticTime =
        widget.timestamp.isNotEmpty ? ', ${widget.timestamp}' : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDateDivider &&
            widget.dateLabel != null &&
            widget.dateLabel!.isNotEmpty)
          ChatDateDivider(label: widget.dateLabel!),
        SizedBox(height: widget.topSpacing),
        Semantics(
          container: true,
          label:
              '${widget.senderName}: ${widget.body}$semanticTime$semanticStatus',
          child: MouseRegion(
            onEnter: (_) {
              if (!_isHovered) setState(() => _isHovered = true);
            },
            onExit: (_) {
              if (_isHovered) setState(() => _isHovered = false);
            },
            child: Row(
              mainAxisAlignment:
                  isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine) ...[
                  if (widget.showAvatar)
                    _buildAvatar()
                  else
                    const SizedBox(
                      width: ChatMessage.avatarSize,
                      height: 1,
                    ),
                  const SizedBox(width: ChatMessage.avatarGap),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: _handleLongPress,
                        onSecondaryTap: widget.onOpenActions,
                        child: Container(
                          key: Key('chat-bubble-${widget.messageKey}'),
                          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: bubbleBg,
                            borderRadius: borderRadius,
                            border: isFailed
                                ? Border.all(
                                    color: ChatMessage._errorRed
                                        .withValues(alpha: 0.45),
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.customContent != null)
                                widget.customContent!
                              else if (widget.imageBytes != null) ...[
                                GestureDetector(
                                  onTap: widget.onImageTap,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 230,
                                        maxHeight: 260,
                                      ),
                                      child: Image.memory(
                                        widget.imageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                if (widget.body.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.body,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ] else if (widget.useRichTextForBody)
                                RichText(
                                  text: TextSpan(
                                    text: widget.body,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      height: 1.35,
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  widget.body,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    fontStyle: isDeleted
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    color: textColor,
                                    fontWeight: isDeleted
                                        ? FontWeight.w400
                                        : FontWeight.w500,
                                  ),
                                ),
                              if (widget.isPinned ||
                                  widget.isStarred ||
                                  (widget.isEdited && !isDeleted)) ...[
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.isPinned) ...[
                                      Icon(
                                        CupertinoIcons.pin_fill,
                                        size: 11,
                                        color: isMine
                                            ? Colors.white70
                                            : ChatMessage._textSubtle,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (widget.isStarred) ...[
                                      Icon(
                                        CupertinoIcons.star_fill,
                                        size: 11,
                                        color: isMine
                                            ? const Color(0xFFFBBF24)
                                            : const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (widget.isEdited && !isDeleted)
                                      Text(
                                        'edited',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isMine
                                              ? Colors.white60
                                              : ChatMessage._textSubtle,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Rule 2: Precision on demand — exact timestamp only shown on hover or long-press
                      if (_shouldShowTimestamp)
                        Padding(
                          padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.timestamp,
                                key: Key('chat-timestamp-${widget.messageKey}'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ChatMessage._textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (widget.onOpenActions != null && !isDeleted) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  key: Key('chat-actions-${widget.messageKey}'),
                                  onTap: widget.onOpenActions,
                                  child: const Icon(
                                    CupertinoIcons.ellipsis,
                                    size: 14,
                                    color: ChatMessage._textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Rule 3: Optimistic UI — inline retry button on failed bubble (no toast, no spinner)
                      if (isFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Semantics(
                            button: true,
                            label: 'Retry sending message',
                            child: InkWell(
                              key: Key('chat-retry-${widget.messageKey}'),
                              onTap: widget.onRetry,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.refresh_bold,
                                      size: 12,
                                      color: ChatMessage._errorRed,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.retryLabel,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: ChatMessage._errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (widget.reactions.isNotEmpty)
                        Transform.translate(
                          offset: const Offset(0, -4),
                          child: GestureDetector(
                            onTap: widget.onOpenActions,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    uniqueEmojis,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  if (widget.reactions.length > 1) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.reactions.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: ChatMessage._ink,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: ChatMessage.avatarGap),
                  if (widget.showAvatar)
                    _buildAvatar()
                  else
                    const SizedBox(
                      width: ChatMessage.avatarSize,
                      height: 1,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Rule 2: Date divider shown only when the calendar date changes between messages.
class ChatDateDivider extends StatelessWidget {
  final String label;

  const ChatDateDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Semantics(
          header: true,
          label: label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rule 5: Inline typing indicator rendered in-flow where the next message will appear,
/// attached to the sender's avatar, supporting single and multiple typers.
class ChatTypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  final String? avatarUrl;

  const ChatTypingIndicator({
    super.key,
    required this.typingUsers,
    this.avatarUrl,
  });

  /// Rule 5: Formats 1 or more typers, e.g. `"Maya is typing..."` or `"Maya and 2 others are typing"`.
  static String formatLabel(List<String> users) {
    final cleaned = users
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return '';
    if (cleaned.length == 1) {
      return '${cleaned.first} is typing...';
    }
    final othersCount = cleaned.length - 1;
    final otherWord = othersCount == 1 ? 'other' : 'others';
    return '${cleaned.first} and $othersCount $otherWord are typing';
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = typingUsers
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();

    final label = formatLabel(cleaned);
    final leadName = cleaned.first;
    final trimmedAvatar = avatarUrl?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: ChatMessage.interSenderSpacing),
      child: Semantics(
        liveRegion: true,
        label: label,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              key: const Key('chat-typing-avatar'),
              width: ChatMessage.avatarSize,
              height: ChatMessage.avatarSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF2F3F7),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: trimmedAvatar.isNotEmpty
                    ? AppImage(
                        url: trimmedAvatar,
                        width: ChatMessage.avatarSize,
                        height: ChatMessage.avatarSize,
                        fit: BoxFit.cover,
                        fallback: ChatInitialAvatar(
                          name: leadName,
                          size: ChatMessage.avatarSize,
                        ),
                      )
                    : ChatInitialAvatar(
                        name: leadName,
                        size: ChatMessage.avatarSize,
                      ),
              ),
            ),
            const SizedBox(width: ChatMessage.avatarGap),
            Flexible(
              child: Container(
                key: const Key('chat-typing-bubble'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6B7280),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
