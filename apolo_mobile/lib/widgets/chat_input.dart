import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_message.dart';
import 'ios26_imessage_kit.dart';
import 'perceived_performance.dart';
import 'voice_recorder.dart';

/// Type of staged attachment in [ChatInput].
enum ChatAttachmentType {
  image,
  file,
  audio,
}

/// Model representing an attachment staged above the text input in [ChatInput] (Rule 6).
class ChatAttachment {
  final String id;
  final String name;
  final ChatAttachmentType type;
  final Uint8List? bytes;
  final String? subtitle;

  const ChatAttachment({
    required this.id,
    required this.name,
    this.type = ChatAttachmentType.file,
    this.bytes,
    this.subtitle,
  });
}

/// Reusable, accessible chat composer implementing Rule 6:
/// - Auto-expands from 1 up to 5 lines, then scrolls internally.
/// - Renders staged attachments, images, and files ABOVE the text input, never below.
/// - Keeps the Send button visible at all times with no loading spinner.
/// - Supports desktop keyboard navigation (`Enter` to send, `Shift+Enter` for newline).
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final List<ChatAttachment> attachments;
  final ValueChanged<String>? onSend;
  final VoidCallback? onAttachTap;
  final ValueChanged<ChatAttachment>? onRemoveAttachment;
  final VoidCallback? onVoiceTap;
  final ValueChanged<VoiceRecordingData>? onSendVoice;
  final double Function()? voiceAmplitudeProvider;
  final bool simulateMicMuted;
  final bool isRecordingVoice;
  final int recordSeconds;
  final VoidCallback? onCancelVoice;
  final VoidCallback? onStopAndSendVoice;
  final String? editingBannerText;
  final VoidCallback? onCancelEdit;
  final String hintText;
  final String recordingText;
  final int minLines;
  final int maxLines;
  final bool isDrawerOpen;
  final bool hasBottomSheetBelow;
  final bool isKeyboardOpen;
  final GlobalKey<VoiceRecorderState>? voiceRecorderKey;

  const ChatInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.attachments = const <ChatAttachment>[],
    this.onSend,
    this.onAttachTap,
    this.onRemoveAttachment,
    this.onVoiceTap,
    this.onSendVoice,
    this.voiceAmplitudeProvider,
    this.simulateMicMuted = false,
    this.isRecordingVoice = false,
    this.recordSeconds = 0,
    this.onCancelVoice,
    this.onStopAndSendVoice,
    this.editingBannerText,
    this.onCancelEdit,
    this.hintText = 'Type a message...',
    this.recordingText = 'Recording...',
    this.minLines = 1,
    this.maxLines = 5,
    this.isDrawerOpen = false,
    this.hasBottomSheetBelow = false,
    this.isKeyboardOpen = false,
    this.voiceRecorderKey,
  });

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _surfaceGrey = Color(0xFFF2F3F7);
  static const Color _textMuted = Color(0xFF6B7280);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  FocusNode? _internalFocusNode;
  final ScrollController _inputScrollController = ScrollController();
  final GlobalKey<VoiceRecorderState> _internalVoiceRecorderKey =
      GlobalKey<VoiceRecorderState>();
  bool _isVoiceRecorderActive = false;
  bool _isSendPressed = false;
  double _maxObservedViewportHeight = 0.0;

  GlobalKey<VoiceRecorderState> get _effectiveVoiceRecorderKey =>
      widget.voiceRecorderKey ?? _internalVoiceRecorderKey;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_onFocusChanged);
      _effectiveFocusNode.addListener(_onFocusChanged);
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _effectiveFocusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    _inputScrollController.dispose();
    super.dispose();
  }

  bool get _hasSendableContent =>
      widget.controller.text.trim().isNotEmpty ||
      widget.attachments.isNotEmpty;

  void _triggerSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty && widget.attachments.isEmpty) return;
    widget.onSend?.call(text);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (!isShiftPressed) {
        if (_hasSendableContent) {
          _triggerSend();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildAttachmentsAboveStrip() {
    return Container(
      key: const Key('chat-attachments-above'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: widget.attachments.map((att) {
            final isImage =
                att.type == ChatAttachmentType.image && att.bytes != null;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Semantics(
                container: true,
                label: 'Staged attachment: ${att.name}',
                child: Container(
                  key: Key('chat-attachment-item-${att.id}'),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ChatInput._surfaceGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            att.bytes!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            att.type == ChatAttachmentType.image
                                ? CupertinoIcons.photo
                                : CupertinoIcons.doc_fill,
                            size: 18,
                            color: ChatInput._ink,
                          ),
                        ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              att.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: ChatInput._ink,
                              ),
                            ),
                            if (att.subtitle != null &&
                                att.subtitle!.isNotEmpty)
                              Text(
                                att.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ChatInput._textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Semantics(
                        button: true,
                        label: 'Remove attachment ${att.name}',
                        child: InkWell(
                          key: Key('chat-attachment-remove-${att.id}'),
                          onTap: () => widget.onRemoveAttachment?.call(att),
                          borderRadius: BorderRadius.circular(999),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 17,
                              color: ChatInput._textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mediaSize = MediaQuery.sizeOf(context);
    final screenWidth = mediaSize.width;
    final screenHeight = mediaSize.height;
    final mqKeyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final viewRef = View.maybeOf(context);
    final rawViewKeyboardInset = viewRef != null && viewRef.devicePixelRatio > 0
        ? viewRef.viewInsets.bottom / viewRef.devicePixelRatio
        : 0.0;
    final effectiveKeyboardInset = math.max(mqKeyboardInset, rawViewKeyboardInset);
    final fullHeightCandidate = screenHeight + effectiveKeyboardInset;
    if (fullHeightCandidate > _maxObservedViewportHeight) {
      _maxObservedViewportHeight = fullHeightCandidate;
    }
    // Detects open keyboard across iOS Safari, iOS Chrome WKWebView (viewport shrink),
    // native mobile (`View.viewInsets` even inside `Scaffold.body`), and widget tests.
    final bool keyboardOpen = widget.isKeyboardOpen ||
        effectiveKeyboardInset > 0 ||
        (_effectiveFocusNode.hasFocus &&
            (_maxObservedViewportHeight - screenHeight) > 100.0);

    // Exact Figma `4:1061` & `1:2660` (`326 × 45` on `375` screen -> start 25, end 24;
    // `+` 45 + gap 19 + input `262 × 45` = `326 × 45`;
    // Closed keyboard: `41 px` from bottom; Open keyboard: `14 px` above keyboard -> `Y = 411 px`).
    final double startInset = screenWidth >= 360 ? 25.0 : 16.0;
    final double endInset = screenWidth >= 360 ? 24.0 : 16.0;
    final double controlsGap =
        screenWidth >= 360 ? Ios26IMessageTokens.composerControlGap : 12.0;
    final double bottomOffset = widget.hasBottomSheetBelow
        ? 12.0
        : (keyboardOpen
            ? Ios26IMessageTokens.composerKeyboardGap
            : math.max(
                Ios26IMessageTokens.composerBottomOffset,
                bottomInset + 7.0,
              ));
    final canSend = _hasSendableContent;
    final contextDir = Directionality.of(context);
    final inputTextDir = widget.controller.text.trim().isEmpty
        ? contextDir
        : ChatMessage.detectTextDirection(
            widget.controller.text,
            fallback: contextDir,
          );

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          startInset,
          0,
          endInset,
          bottomOffset,
        ),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.editingBannerText != null &&
                widget.editingBannerText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LiquidGlassSurface(
                  borderRadius: BorderRadius.circular(18),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.pencil,
                        size: 15,
                        color: Ios26IMessageTokens.bubbleMine,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.editingBannerText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Ios26IMessageTokens.labelPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onCancelEdit,
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 18,
                          color: Ios26IMessageTokens.dateGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Rule 6: Attachments, images, and files appear ABOVE the text input, never below.
            if (widget.attachments.isNotEmpty) _buildAttachmentsAboveStrip(),

            Row(
              key: const Key('chat-composer-bar-row'),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_isVoiceRecorderActive) ...[
                  // Exact Figma `1:2` Add button: `(25, 411, 45, 45)` circular clear-glass, 20px black `+`
                  Semantics(
                    button: true,
                    label: 'Add attachment',
                    child: LiquidGlassSurface(
                      key: const Key('chat-attach-button'),
                      width: Ios26IMessageTokens.controlCircleSize,
                      height: Ios26IMessageTokens.controlCircleSize,
                      fillAlpha: Ios26IMessageTokens.headerButtonFillAlpha,
                      borderRadius: BorderRadius.circular(
                        Ios26IMessageTokens.controlRadius,
                      ),
                      onTap: widget.onAttachTap,
                      child: Center(
                        child: AnimatedRotation(
                          turns: widget.isDrawerOpen ? 0.125 : 0.0,
                          duration: ApoloMotion.microDuration,
                          curve: ApoloMotion.easeOutCurve,
                          child: const Icon(
                            CupertinoIcons.plus,
                            color: Ios26IMessageTokens.composerPlusIcon,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: controlsGap),
                ],

                // Exact Figma `I4:1061;1:2659;1:76` Input glass capsule: `262 × 45 px`
                Expanded(
                  child: _isVoiceRecorderActive
                      ? VoiceRecorder(
                          key: _effectiveVoiceRecorderKey,
                          compactWhenIdle: true,
                          amplitudeProvider: widget.voiceAmplitudeProvider,
                          simulateMicMuted: widget.simulateMicMuted,
                          onRecordingStateChanged: (active) {
                            if (mounted && _isVoiceRecorderActive != active) {
                              setState(() => _isVoiceRecorderActive = active);
                            }
                          },
                          onUnsupportedTap: widget.onVoiceTap,
                          onSend: (recording) {
                            if (widget.onSendVoice != null) {
                              widget.onSendVoice!(recording);
                            } else {
                              widget.onStopAndSendVoice?.call();
                            }
                          },
                          onCancel: () {
                            widget.onCancelVoice?.call();
                          },
                        )
                      : LiquidGlassSurface(
                          key: const Key('chat-input-capsule'),
                          fillAlpha: Ios26IMessageTokens.composerFillAlpha,
                          borderRadius: BorderRadius.circular(
                            Ios26IMessageTokens.composerRadius,
                          ),
                          constraints: const BoxConstraints(
                            minHeight: Ios26IMessageTokens.composerMinHeight,
                          ),
                          padding: const EdgeInsetsDirectional.only(
                            start: 16,
                            end: 4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                key: const ValueKey<String>(
                                    'chat-draft-expanded'),
                                child: Focus(
                                  onKeyEvent: _handleKeyEvent,
                                  child: Semantics(
                                    textField: true,
                                    label: 'Message input',
                                    child: TextField(
                                      key: const Key('chat-draft'),
                                      controller: widget.controller,
                                      focusNode: _effectiveFocusNode,
                                      scrollController: _inputScrollController,
                                      scrollPhysics:
                                          const ClampingScrollPhysics(),
                                      keyboardType: TextInputType.multiline,
                                      textDirection: inputTextDir,
                                      minLines: widget.minLines,
                                      maxLines: widget.maxLines,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      textInputAction: TextInputAction.newline,
                                      onSubmitted: (_) => _triggerSend(),
                                      style: const TextStyle(
                                        fontSize:
                                            Ios26IMessageTokens.composerFontSize,
                                        height: 22.0 / 17.0,
                                        color: Ios26IMessageTokens.labelPrimary,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.25,
                                      ),
                                      decoration: InputDecoration(
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        hintText: widget.hintText,
                                        hintStyle: const TextStyle(
                                          color: Ios26IMessageTokens
                                              .placeholderGray,
                                          fontSize: Ios26IMessageTokens
                                              .composerFontSize,
                                          height: 22.0 / 17.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 11.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // When empty: exact Figma `#CCCCCC` microphone `(324, 425, 13, 19)`.
                              // When text/attachment present: iconic `#0088FF` circular Send up-arrow.
                              if (!canSend)
                                Flexible(
                                  key: const ValueKey<String>(
                                      'chat-voice-recorder-flex'),
                                  flex: 0,
                                  child: VoiceRecorder(
                                    key: _effectiveVoiceRecorderKey,
                                    compactWhenIdle: true,
                                    amplitudeProvider:
                                        widget.voiceAmplitudeProvider,
                                    simulateMicMuted: widget.simulateMicMuted,
                                    onRecordingStateChanged: (active) {
                                      if (mounted &&
                                          _isVoiceRecorderActive != active) {
                                        setState(() =>
                                            _isVoiceRecorderActive = active);
                                      }
                                    },
                                    onUnsupportedTap: widget.onVoiceTap,
                                    onSend: (recording) {
                                      if (widget.onSendVoice != null) {
                                        widget.onSendVoice!(recording);
                                      } else {
                                        widget.onStopAndSendVoice?.call();
                                      }
                                    },
                                    onCancel: () {
                                      widget.onCancelVoice?.call();
                                    },
                                  ),
                                )
                              else
                                Semantics(
                                  button: true,
                                  enabled: true,
                                  label: 'Send message',
                                  child: GestureDetector(
                                    key: const Key('chat-send'),
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (_) {
                                      HapticFeedback.lightImpact();
                                      setState(() => _isSendPressed = true);
                                    },
                                    onTapUp: (_) {
                                      setState(() => _isSendPressed = false);
                                      _triggerSend();
                                    },
                                    onTapCancel: () {
                                      if (_isSendPressed) {
                                        setState(() => _isSendPressed = false);
                                      }
                                    },
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                      ),
                                      child: Center(
                                        child: AnimatedScale(
                                          key: const Key('chat-send-scale'),
                                          scale: _isSendPressed
                                              ? ApoloMotion.pressedScale
                                              : 1.0,
                                          duration: ApoloMotion.microDuration,
                                          curve: ApoloMotion.easeOutCurve,
                                          child: AnimatedOpacity(
                                            key: const Key('chat-send-opacity'),
                                            opacity: _isSendPressed
                                                ? ApoloMotion.pressedOpacity
                                                : 1.0,
                                            duration: ApoloMotion.microDuration,
                                            curve: ApoloMotion.easeOutCurve,
                                            child: Container(
                                              width: 33,
                                              height: 33,
                                              decoration: const BoxDecoration(
                                                color: Ios26IMessageTokens
                                                    .bubbleMine,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                widget.editingBannerText != null
                                                    ? Icons.check_rounded
                                                    : CupertinoIcons.arrow_up,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
