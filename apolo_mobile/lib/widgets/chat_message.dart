import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config/app_config.dart';
import '../features/chat/models/chat_ack_models.dart';
import '../features/chat/widgets/chat_ack_indicator.dart';
import '../l10n/l10n.dart';
import '../screens/widgets/app_image.dart';
import '../screens/widgets/chat_utils.dart';
import 'apolo_emoji_reaction_bar.dart';
import 'ios26_imessage_kit.dart';
import 'typing_indicator.dart';

/// Delivery status for a [ChatMessage] bubble (Rule 3: Optimistic UI + 3-stage ACKs).
enum ChatMessageStatus {
  sending,
  sent,
  delivered,
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
  final String? imageUrl;
  final Widget? customContent;
  final VoidCallback? onRetry;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onImageTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onOpenActions;
  final String retryLabel;
  final bool useRichTextForBody;
  final bool showSenderName;
  final bool hideAvatarGutter;
  final String? deliveryLabel;
  final ValueListenable<ChatAckStatus>? ackStatusListenable;
  final double swipeRevealProgress;
  final bool isBorderlessCustomContent;
  final String? replySenderName;
  final String? replySenderAvatar;
  final String? replyBody;

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
    this.imageUrl,
    this.customContent,
    this.onRetry,
    this.onAvatarTap,
    this.onImageTap,
    this.onDoubleTap,
    this.onOpenActions,
    this.retryLabel = 'Retry',
    this.useRichTextForBody = false,
    this.showSenderName = false,
    this.hideAvatarGutter = false,
    this.deliveryLabel,
    this.ackStatusListenable,
    this.swipeRevealProgress = 0.0,
    this.isBorderlessCustomContent = false,
    this.replySenderName,
    this.replySenderAvatar,
    this.replyBody,
  });

  static final RegExp _rawMediaFilenameRegex = RegExp(
    r'^[^\s/\\]+\.(png|jpe?g|webp|heic|heif|gif|bmp)$',
    caseSensitive: false,
  );

  /// Returns `true` when [text] is an auto-generated raw image filename such as
  /// `scaled_IMG_0865.png`, `IMG_1234.JPG`, or `image_picker_9921.jpeg`.
  static bool isRawMediaFilename(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return _rawMediaFilenameRegex.hasMatch(trimmed);
  }

  /// Strips auto-generated media filenames when an image preview is rendered so
  /// users never see raw strings like `scaled_IMG_0865.png`.
  static String sanitizeCaption(String body, {required bool hasImage}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '';
    if (hasImage && isRawMediaFilename(trimmed)) return '';
    return body;
  }

  /// Detects natural reading direction (RTL for Arabic/Hebrew, LTR for Latin/digits)
  /// so mixed-script messages ("Tissot watch black", "DH 110.00", "+212 600...", Arabic text)
  /// render cleanly without BiDi scrambling.
  static TextDirection detectTextDirection(
    String text, {
    TextDirection fallback = TextDirection.rtl,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return fallback;
    final rtlRegex = RegExp(r'[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]');
    final ltrRegex = RegExp(r'[A-Za-z]');
    for (final rune in trimmed.runes) {
      final ch = String.fromCharCode(rune);
      if (rtlRegex.hasMatch(ch)) return TextDirection.rtl;
      if (ltrRegex.hasMatch(ch)) return TextDirection.ltr;
    }
    if (RegExp(r'[0-9٠-٩۰-۹]').hasMatch(trimmed)) {
      return TextDirection.ltr;
    }
    return fallback;
  }

  /// Rule 1: Maximum time window (2 minutes) to group consecutive messages from the same sender.
  static const Duration groupingWindow = Duration(minutes: 2);

  /// Rule 1: Exact 8px vertical spacing between messages from different senders.
  static const double interSenderSpacing = 8.0;

  /// Compact vertical spacing between consecutive grouped messages from the same sender.
  static const double intraGroupSpacing = 4.0;

  /// Fixed avatar diameter for sender alignment.
  static const double avatarSize = 28.0;

  /// Gap between avatar column and message bubble.
  static const double avatarGap = 8.0;

  static const Color _surfaceGrey = Color(0xFFF2F3F7);

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

  /// Formats centered iMessage timestamp divider (`"Monday at 11:04PM"`, `"Yesterday at 8:34PM"`).
  static String formatIMessageTimestampDivider(DateTime t, AppStrings s) {
    final dayPart = formatChatDayLabel(t, s);
    final bool hasClock = t.hour != 0 || t.minute != 0;
    if (!hasClock) return dayPart;

    final int h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String mm = t.minute.toString().padLeft(2, '0');
    final bool isPm = t.hour >= 12;

    if (s.isEn) {
      return '$dayPart at $h12:$mm${isPm ? "PM" : "AM"}';
    }
    if (s.isAr) {
      return '$dayPart \u2066$h12:$mm\u2069 ${isPm ? "م" : "ص"}';
    }
    final String hh = t.hour.toString().padLeft(2, '0');
    return '$dayPart à $hh:$mm';
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
          resolvedLabel = formatIMessageTimestampDivider(currDt, s);
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

class _ChatMessageState extends State<ChatMessage>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isTimestampPinned = false;
  late final AnimationController _heartBurstCtrl;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartBurstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.25, end: 1.28)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.28, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_heartBurstCtrl);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartBurstCtrl);
  }

  @override
  void dispose() {
    _heartBurstCtrl.dispose();
    super.dispose();
  }

  bool get _hasReplyQuote =>
      !widget.isDeleted &&
      widget.replyBody != null &&
      widget.replyBody!.trim().isNotEmpty;

  bool get _shouldShowTimestamp =>
      widget.timestamp.trim().isNotEmpty &&
      (_isHovered || _isTimestampPinned || _hasReplyQuote);

  Widget _buildReplyQuotePreview(
    TextDirection contextDir,
    double maxBubbleWidth,
    bool isDark,
  ) {
    final quotedAuthor = (widget.replySenderName ?? '').trim();
    final quotedAvatar = (widget.replySenderAvatar ?? '').trim();
    final quotedBody = (widget.replyBody ?? '').trim();
    final lineColor =
        isDark ? const Color(0xFF404045) : const Color(0xFFD9D9D9);
    final quoteInk =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF525252);

    return Padding(
      key: Key('chat-reply-quote-${widget.messageKey}'),
      padding: const EdgeInsets.only(bottom: 6.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 2.5,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(999.0),
                ),
              ),
              const SizedBox(width: 10.0),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quotedAuthor.isNotEmpty) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18.0,
                            height: 18.0,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEEEEEE),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: quotedAvatar.isNotEmpty
                                ? AppImage(
                                    url: quotedAvatar,
                                    width: 18.0,
                                    height: 18.0,
                                    fit: BoxFit.cover,
                                    fallback: ChatInitialAvatar(
                                      name: quotedAuthor,
                                      size: 18.0,
                                    ),
                                  )
                                : ChatInitialAvatar(
                                    name: quotedAuthor,
                                    size: 18.0,
                                  ),
                          ),
                          const SizedBox(width: 6.0),
                          Flexible(
                            child: Text(
                              quotedAuthor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: ChatMessage.detectTextDirection(
                                quotedAuthor,
                                fallback: contextDir,
                              ),
                              style: TextStyle(
                                color: quoteInk,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3.0),
                    ],
                    Text(
                      quotedBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: ChatMessage.detectTextDirection(
                        quotedBody,
                        fallback: contextDir,
                      ),
                      style: TextStyle(
                        color: quoteInk,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDoubleTap() {
    if (widget.isDeleted || widget.onDoubleTap == null) return;
    HapticFeedback.mediumImpact();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _heartBurstCtrl.forward(from: 0.0);
    }
    widget.onDoubleTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isTimestampPinned = !_isTimestampPinned;
    });
    if (!widget.isDeleted) {
      widget.onOpenActions?.call();
    }
  }

  static ChatAckStatus _toAckStatus(ChatMessageStatus s) {
    return switch (s) {
      ChatMessageStatus.sending => ChatAckStatus.sending,
      ChatMessageStatus.sent => ChatAckStatus.sent,
      ChatMessageStatus.delivered => ChatAckStatus.delivered,
      ChatMessageStatus.read => ChatAckStatus.read,
      ChatMessageStatus.failed => ChatAckStatus.failed,
    };
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
        isDesktop ? 480.0 : (screenWidth * 0.72).clamp(180.0, 280.0);

    final contextDir = Directionality.of(context);
    final isRtl = contextDir == TextDirection.rtl;
    // Outgoing bubble aligns to trailing edge (right in LTR, left in RTL).
    final tailOnRight = isRtl ? !isMine : isMine;
    // Dynamic Layer v5.1 Chat (`34425:37624`): clean tail-free 18px rounded bubbles.
    const bool showTail = false;
    const double tailDrop = 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasReply = _hasReplyQuote;

    final bubbleBg = isDeleted
        ? const Color(0xFFE5E5EA)
        : isFailed
            ? const Color(0xFFFEF2F2)
            : (isMine && hasReply
                ? (isDark
                    ? const Color(0xFF15324B)
                    : const Color(0xFFD9F0FF))
                : (isMine
                    ? (isDark
                        ? const Color(0xFFFFFFFF)
                        : Ios26IMessageTokens.bubbleMine)
                    : (isDark
                        ? const Color(0xFF1E1E22)
                        : Ios26IMessageTokens.bubbleOther)));

    final textColor = isDeleted
        ? Ios26IMessageTokens.dateGray
        : isFailed
            ? Ios26IMessageTokens.errorRed
            : (isMine && hasReply
                ? (isDark
                    ? const Color(0xFF7CC4FA)
                    : const Color(0xFF0A78E6))
                : (isMine
                    ? (isDark
                        ? const Color(0xFF0A0A0A)
                        : Ios26IMessageTokens.bubbleMineText)
                    : (isDark
                        ? const Color(0xFFFFFFFF)
                        : Ios26IMessageTokens.bubbleOtherText)));

    final trimmedImageUrl = widget.imageUrl?.trim() ?? '';
    final bool hasImage =
        !isDeleted && (widget.imageBytes != null || trimmedImageUrl.isNotEmpty);
    final String displayBody = ChatMessage.sanitizeCaption(
      widget.body,
      hasImage: hasImage,
    );

    final bodyTextDir = ChatMessage.detectTextDirection(
      displayBody,
      fallback: contextDir,
    );

    final bool isPureImageBubble =
        widget.customContent == null && hasImage && displayBody.trim().isEmpty;

    Widget buildMediaImage({
      double? width,
      double? height,
    }) {
      if (widget.imageBytes != null) {
        return Image.memory(
          widget.imageBytes!,
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      }
      return AppImage(
        url: trimmedImageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    final semanticStatus = isFailed
        ? context.l10n.chatSendFailedRetrySemantic
        : (widget.status == ChatMessageStatus.sending
            ? context.l10n.chatSendingSemantic
            : '');
    final semanticTime =
        widget.timestamp.isNotEmpty ? ', ${widget.timestamp}' : '';

    final bool showSwipeTimestamp =
        widget.swipeRevealProgress > 0.05 && widget.timestamp.trim().isNotEmpty;

    final VoidCallback? effectiveDoubleTap =
        (!isDeleted && widget.onDoubleTap != null) ? _handleDoubleTap : null;

    Widget bubbleCore;
    if (widget.isBorderlessCustomContent &&
        widget.customContent != null &&
        !isDeleted) {
      // Authentic iOS iMessage Die-Cut Sticker: floats cleanly with no bubble box
      bubbleCore = GestureDetector(
        key: Key('chat-bubble-${widget.messageKey}'),
        onDoubleTap: effectiveDoubleTap,
        onLongPress: _handleLongPress,
        onSecondaryTap: widget.onOpenActions,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: widget.customContent!,
        ),
      );
    } else if (isPureImageBubble) {
      // Exact Figma `1:2` photo message bubble (`(25, -58, 170, 222)`):
      // `170 × 216` rounded `16px` image body.
      const double photoHeight =
          Ios26IMessageTokens.photoBubbleBodyHeight + tailDrop;
      bubbleCore = GestureDetector(
        key: Key('chat-bubble-${widget.messageKey}'),
        onTap: widget.onImageTap,
        onDoubleTap: effectiveDoubleTap,
        onLongPress: _handleLongPress,
        onSecondaryTap: widget.onOpenActions,
        child: Container(
          key: Key('chat-image-bubble-${widget.messageKey}'),
          width: Ios26IMessageTokens.photoBubbleWidth,
          height: photoHeight,
          constraints: BoxConstraints(
            minWidth: Ios26IMessageTokens.photoBubbleWidth,
            maxWidth: 210,
            minHeight: 156 + tailDrop,
            maxHeight: 246 + tailDrop,
          ),
          child: ClipPath(
            clipper: IMessageBubbleClipper(
              tailOnRight: tailOnRight,
              showTail: showTail,
              radius: Ios26IMessageTokens.bubbleRadius,
            ),
            child: ColoredBox(
              color: const Color(0xFFF2F2F7),
              child: buildMediaImage(
                width: Ios26IMessageTokens.photoBubbleWidth,
                height: photoHeight,
              ),
            ),
          ),
        ),
      );
    } else {
      // Dynamic Layer v5.1 Chat (`47281:3598`) clean 16px rounded bubble:
      final double effectiveTracking = bodyTextDir == TextDirection.rtl
          ? 0.0
          : Ios26IMessageTokens.messageTracking;
      const EdgeInsetsDirectional bubblePadding = EdgeInsetsDirectional.only(
        start: 14,
        end: 14,
        top: 10,
        bottom: 10,
      );

      bubbleCore = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: effectiveDoubleTap,
        onLongPress: _handleLongPress,
        onSecondaryTap: widget.onOpenActions,
        child: CustomPaint(
          painter: IMessageBubblePainter(
            color: bubbleBg,
            gradient: null,
            borderColor: isFailed
                ? Ios26IMessageTokens.errorRed.withValues(alpha: 0.45)
                : null,
            tailOnRight: tailOnRight,
            showTail: showTail,
          ),
          child: Container(
            key: Key('chat-bubble-${widget.messageKey}'),
            constraints: BoxConstraints(
              minHeight: 40.0,
              maxWidth: maxBubbleWidth,
            ),
            padding: bubblePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMine &&
                    widget.showSenderName &&
                    widget.isFirstInGroup &&
                    widget.senderName.trim().isNotEmpty) ...[
                  Text(
                    widget.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: ChatMessage.detectTextDirection(
                      widget.senderName,
                      fallback: contextDir,
                    ),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Ios26IMessageTokens.dateGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                if (widget.customContent != null)
                  widget.customContent!
                else if (hasImage) ...[
                  GestureDetector(
                    onTap: widget.onImageTap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 224,
                          maxHeight: 250,
                        ),
                        child: buildMediaImage(width: 224),
                      ),
                    ),
                  ),
                  if (displayBody.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      displayBody,
                      textDirection: bodyTextDir,
                      style: TextStyle(
                        fontSize: Ios26IMessageTokens.messageFontSize,
                        height: Ios26IMessageTokens.messageLineHeight,
                        letterSpacing: effectiveTracking,
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ] else if (widget.useRichTextForBody)
                  RichText(
                    textDirection: bodyTextDir,
                    text: TextSpan(
                      text: displayBody,
                      style: TextStyle(
                        fontSize: Ios26IMessageTokens.messageFontSize,
                        height: Ios26IMessageTokens.messageLineHeight,
                        letterSpacing: effectiveTracking,
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                else
                  Text(
                    displayBody,
                    textDirection: bodyTextDir,
                    style: TextStyle(
                      fontSize: Ios26IMessageTokens.messageFontSize,
                      height: Ios26IMessageTokens.messageLineHeight,
                      letterSpacing: effectiveTracking,
                      fontStyle:
                          isDeleted ? FontStyle.italic : FontStyle.normal,
                      color: textColor,
                      fontWeight: FontWeight.w400,
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
                              : Ios26IMessageTokens.dateGray,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (widget.isStarred) ...[
                        Icon(
                          CupertinoIcons.star_fill,
                          size: 11,
                          color: isMine
                              ? const Color(0xFFFDE047)
                              : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (widget.isEdited && !isDeleted)
                        Text(
                          context.l10n.chatEditedLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isMine
                                ? Colors.white70
                                : Ios26IMessageTokens.dateGray,
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
      );
    }

    final Widget bubbleWithBurst = AnimatedBuilder(
      animation: _heartBurstCtrl,
      builder: (context, child) {
        if (!_heartBurstCtrl.isAnimating) return child!;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            child!,
            IgnorePointer(
              child: Opacity(
                opacity: _heartOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _heartScale.value,
                  child: Text(
                    '❤️',
                    key: Key('chat-double-tap-heart-${widget.messageKey}'),
                    style: ApoloPlatformEmoji.textStyle(
                      context,
                      fontSize: 34.0,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: bubbleCore,
    );

    // Wrap bubble with floating reaction badge overlapping the bubble's lower corner.
    Widget bubbleWithTapback = widget.reactions.isEmpty
        ? bubbleWithBurst
        : Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: bubbleWithBurst,
              ),
              PositionedDirectional(
                bottom: 0,
                end: isMine ? null : 8,
                start: isMine ? 8 : null,
                child: Ios26TapbackBadge(
                  reactions: widget.reactions,
                  onTap: widget.onOpenActions,
                ),
              ),
            ],
          );

    // Subtle opacity feedback while message is still sending (optimistic UI)
    if (widget.status == ChatMessageStatus.sending && isMine) {
      bubbleWithTapback = Opacity(
        opacity: 0.78,
        child: bubbleWithTapback,
      );
    }

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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMine && !widget.hideAvatarGutter) ...[
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
                      if (hasReply)
                        _buildReplyQuotePreview(
                          contextDir,
                          maxBubbleWidth,
                          isDark,
                        ),
                      bubbleWithTapback,

                      // Explicit 3-stage Message ACK row (Sent ✓ / Delivered ✓✓ / Read ✓✓)
                      // Driven by `ValueListenableBuilder` so real-time ACK updates never
                      // trigger full-list rebuilds or scroll jitter.
                      if (isMine &&
                          !isDeleted &&
                          !isFailed &&
                          ((widget.deliveryLabel != null &&
                                  widget.deliveryLabel!.isNotEmpty) ||
                              widget.ackStatusListenable != null))
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: 3,
                            end: isMine ? 8 : 4,
                            start: isMine ? 4 : 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.deliveryLabel != null &&
                                  widget.deliveryLabel!.isNotEmpty) ...[
                                Flexible(
                                  child: Text(
                                    widget.deliveryLabel!,
                                    key: Key('chat-status-${widget.messageKey}'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Ios26IMessageTokens.dateGray,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              ChatAckIndicator(
                                key: Key('chat-ack-tick-${widget.messageKey}'),
                                statusListenable: widget.ackStatusListenable,
                                fallbackStatus: _toAckStatus(widget.status),
                              ),
                            ],
                          ),
                        ),

                      // Rule 2: Precision on demand — exact timestamp on hover or long-press
                      if (_shouldShowTimestamp)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: 3,
                            start: 6,
                            end: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.timestamp,
                                key: Key('chat-timestamp-${widget.messageKey}'),
                                textDirection: TextDirection.ltr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Ios26IMessageTokens.dateGray,
                                  fontWeight: FontWeight.w500,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              if (widget.onOpenActions != null &&
                                  !isDeleted) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  key: Key('chat-actions-${widget.messageKey}'),
                                  onTap: widget.onOpenActions,
                                  child: const Icon(
                                    CupertinoIcons.ellipsis,
                                    size: 14,
                                    color: Ios26IMessageTokens.dateGray,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Rule 3: Optimistic UI — inline retry pill on failed bubble
                      if (isFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Semantics(
                            button: true,
                            label: context.l10n.chatRetrySendingTooltip,
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
                                      CupertinoIcons.exclamationmark_circle_fill,
                                      size: 13,
                                      color: Ios26IMessageTokens.errorRed,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        widget.retryLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Ios26IMessageTokens.errorRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isMine && !widget.hideAvatarGutter) ...[
                  const SizedBox(width: ChatMessage.avatarGap),
                  if (widget.showAvatar)
                    _buildAvatar()
                  else
                    const SizedBox(
                      width: ChatMessage.avatarSize,
                      height: 1,
                    ),
                ],
                // Classic iMessage swipe-to-reveal inline timestamp
                if (showSwipeTimestamp)
                  AnimatedOpacity(
                    opacity: widget.swipeRevealProgress.clamp(0.0, 1.0),
                    duration: Duration.zero,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Text(
                        widget.timestamp,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Ios26IMessageTokens.dateGray,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Exact Figma `1:2` Timestamps (`(95, 226, 186, 16)` / `(95, 309, 186, 16)`):
/// SF Pro Medium (`w500`), `12px`, `#8E8E93`, center-aligned.
class ChatDateDivider extends StatelessWidget {
  final String label;

  const ChatDateDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Center(
        child: Semantics(
          header: true,
          label: label,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: Ios26IMessageTokens.dateFontSize,
              fontWeight: FontWeight.w400,
              color: Ios26IMessageTokens.dateGray,
              height: 16.0 / 12.0,
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
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TypingIndicatorDots(),
                    const SizedBox(width: 8),
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
