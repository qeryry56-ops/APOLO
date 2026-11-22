import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _surfaceGrey = Color(0xFFF2F3F7);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textSubtle = Color(0xFF9CA3AF);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  FocusNode? _internalFocusNode;
  final ScrollController _inputScrollController = ScrollController();
  bool _isVoiceRecorderActive = false;
  bool _isSendPressed = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
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
    final canSend = _hasSendableContent;

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 8, 14, bottomInset + 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.editingBannerText != null &&
                widget.editingBannerText!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ChatInput._surfaceGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.pencil,
                      size: 15,
                      color: ChatInput._ink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.editingBannerText!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ChatInput._ink,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelEdit,
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 18,
                        color: ChatInput._textMuted,
                      ),
                    ),
                  ],
                ),
              ),

            // Rule 6: Attachments, images, and files appear ABOVE the text input, never below.
            if (widget.attachments.isNotEmpty) _buildAttachmentsAboveStrip(),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_isVoiceRecorderActive) ...[
                  // Attach button (`+`) with min 44x44px touch target
                  Semantics(
                    button: true,
                    label: 'Add attachment',
                    child: GestureDetector(
                      key: const Key('chat-attach-button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onAttachTap,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        child: Center(
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: ChatInput._surfaceGrey,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              CupertinoIcons.plus,
                              color: ChatInput._ink,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Rule 6: Auto-expanding input up to 5 lines, then scrollable
                  Expanded(
                    key: const ValueKey<String>('chat-draft-expanded'),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.only(left: 14, right: 6),
                      decoration: BoxDecoration(
                        color: ChatInput._surfaceGrey,
                        borderRadius: BorderRadius.circular(22),
                      ),
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
                            scrollPhysics: const ClampingScrollPhysics(),
                            keyboardType: TextInputType.multiline,
                            minLines: widget.minLines,
                            maxLines: widget.maxLines,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            onSubmitted: (_) => _triggerSend(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              color: ChatInput._ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              hintText: widget.hintText,
                              hintStyle: const TextStyle(
                                color: ChatInput._textSubtle,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Reusable <VoiceRecorder onSend={} onCancel={} /> (Rules 1-4)
                Flexible(
                  key: const ValueKey<String>('chat-voice-recorder-flex'),
                  flex: _isVoiceRecorderActive ? 1 : 0,
                  child: VoiceRecorder(
                    key: const ValueKey<String>('chat-voice-recorder'),
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
                  ),
                ),

                if (!_isVoiceRecorderActive) ...[
                  const SizedBox(width: 4),
                  // Rule 1 ("REACT AT ONCE") & Rule 3 ("MOVE WITH EASE"):
                  // Send button reacts on touch down (<16ms) with 95% scale, 0.82 opacity, and haptic feedback,
                  // using 220ms cubic-bezier(0.22, 1, 0.36, 1) ease-out curve.
                  Semantics(
                    button: true,
                    enabled: canSend,
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
                              child: AnimatedContainer(
                                duration: ApoloMotion.microDuration,
                                curve: ApoloMotion.easeOutCurve,
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: canSend
                                      ? ChatInput._ink
                                      : const Color(0xFFD1D5DB),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  widget.editingBannerText != null
                                      ? Icons.check_rounded
                                      : CupertinoIcons.arrow_up,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
