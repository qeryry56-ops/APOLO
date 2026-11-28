import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Platform-aware native OS Emoji rendering & reaction palettes:
/// - **iOS / macOS**: Renders native Apple 3D emojis (`Apple Color Emoji`) with
///   authentic iOS quick reactions (`❤️ 😂 😮 😢 😡 👍`).
/// - **Android & others**: Renders native Android color emojis (`Noto Color Emoji` /
///   `SamsungColorEmoji`) with authentic Android quick reactions (`👍 ❤️ 😂 😮 😢 🙏`),
///   preventing app UI fonts (`PlusJakartaSans` / `IBMPlexSansArabic`) from turning
///   Unicode hearts into monochrome dingbats.
abstract final class ApoloPlatformEmoji {
  static const List<String> iosQuickReactions = <String>[
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '👍',
  ];

  static const List<String> androidQuickReactions = <String>[
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];

  static const List<String> extendedReactions = <String>[
    '🔥',
    '👏',
    '🎉',
    '💯',
    '😍',
    '🤔',
    '🙌',
    '✨',
    '🤝',
    '💰',
    '✅',
    '👎',
    '🥳',
    '😎',
    '🤩',
    '🫶',
  ];

  static bool isCupertino(
    BuildContext context, {
    TargetPlatform? platformOverride,
  }) {
    final platform = platformOverride ?? Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  static String emojiFontFamily(
    BuildContext context, {
    TargetPlatform? platformOverride,
  }) {
    return isCupertino(context, platformOverride: platformOverride)
        ? 'Apple Color Emoji'
        : 'Noto Color Emoji';
  }

  static List<String> emojiFontFallback(
    BuildContext context, {
    TargetPlatform? platformOverride,
  }) {
    return isCupertino(context, platformOverride: platformOverride)
        ? const <String>['Apple Color Emoji']
        : const <String>[
            'Noto Color Emoji',
            'SamsungColorEmoji',
            'Android Emoji',
            'Segoe UI Emoji',
          ];
  }

  static TextStyle textStyle(
    BuildContext context, {
    double fontSize = 24.0,
    double height = 1.15,
    TargetPlatform? platformOverride,
  }) {
    return TextStyle(
      fontSize: fontSize,
      height: height,
      fontWeight: FontWeight.w400,
      fontFamily: emojiFontFamily(context, platformOverride: platformOverride),
      fontFamilyFallback:
          emojiFontFallback(context, platformOverride: platformOverride),
      decoration: TextDecoration.none,
    );
  }

  static List<String> quickReactions(
    BuildContext context, {
    TargetPlatform? platformOverride,
  }) {
    return isCupertino(context, platformOverride: platformOverride)
        ? iosQuickReactions
        : androidQuickReactions;
  }
}

/// Floating long-press emoji reaction bar tailored to iOS vs Android.
class ApoloEmojiReactionBar extends StatefulWidget {
  final String? selectedEmoji;
  final ValueChanged<String> onSelectEmoji;
  final TargetPlatform? platformOverride;

  const ApoloEmojiReactionBar({
    super.key,
    required this.onSelectEmoji,
    this.selectedEmoji,
    this.platformOverride,
  });

  @override
  State<ApoloEmojiReactionBar> createState() => _ApoloEmojiReactionBarState();
}

class _ApoloEmojiReactionBarState extends State<ApoloEmojiReactionBar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Widget _buildEmojiCell({
    required BuildContext context,
    required String emoji,
    required bool isIos,
    required bool isDark,
    required int index,
    bool fromExtended = false,
  }) {
    final isSelected = (widget.selectedEmoji ?? '').trim() == emoji;
    final selectedFill = isDark
        ? const Color(0xFF3A3A3C)
        : (isIos ? const Color(0xFFEEEEEE) : const Color(0xFFE8EAED));
    final disableAnim = MediaQuery.disableAnimationsOf(context);

    Widget content = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? selectedFill : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Text(
        emoji,
        style: ApoloPlatformEmoji.textStyle(
          context,
          fontSize: isIos ? 24.5 : 23.5,
          platformOverride: widget.platformOverride,
        ),
      ),
    );

    if (!disableAnim && !fromExtended) {
      final start = (index * 0.08).clamp(0.0, 0.55);
      final curved = CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, 1.0, curve: Curves.easeOutBack),
      );
      content = ScaleTransition(scale: curved, child: content);
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: context.l10n.emojiReactWithSemantic(emoji),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('chat-reaction-emoji-$emoji'),
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSelectEmoji(emoji);
          },
          child: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIos = ApoloPlatformEmoji.isCupertino(
      context,
      platformOverride: widget.platformOverride,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quickList = ApoloPlatformEmoji.quickReactions(
      context,
      platformOverride: widget.platformOverride,
    );
    final surfaceColor = isDark
        ? (isIos
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.92)
            : const Color(0xFF28292C))
        : (isIos
            ? Colors.white.withValues(alpha: 0.94)
            : const Color(0xFFFFFFFF));
    final borderRadius = BorderRadius.circular(_expanded ? 24 : (isIos ? 999 : 28));

    Widget barBody = AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 324),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < quickList.length; i++) ...[
                      _buildEmojiCell(
                        context: context,
                        emoji: quickList[i],
                        isIos: isIos,
                        isDark: isDark,
                        index: i,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Semantics(
                      button: true,
                      label: _expanded
                          ? context.l10n.emojiFewerTooltip
                          : context.l10n.emojiMoreTooltip,
                      child: Material(
                        color: isDark
                            ? const Color(0xFF3A3A3C)
                            : const Color(0xFFEEEEEE),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('chat-reaction-more-button'),
                          customBorder: const CircleBorder(),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _expanded = !_expanded);
                          },
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Center(
                              child: Icon(
                                _expanded
                                    ? CupertinoIcons.chevron_up
                                    : CupertinoIcons.add,
                                size: 17,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF000000),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_expanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(
                    height: 1,
                    thickness: 0.6,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.black.withValues(alpha: 0.07),
                  ),
                ),
                SizedBox(
                  key: const Key('chat-reaction-extended-grid'),
                  height: 128,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: [
                        for (int i = 0;
                            i < ApoloPlatformEmoji.extendedReactions.length;
                            i++)
                          _buildEmojiCell(
                            context: context,
                            emoji: ApoloPlatformEmoji.extendedReactions[i],
                            isIos: isIos,
                            isDark: isDark,
                            index: i,
                            fromExtended: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Container(
      key: const Key('apolo-emoji-reaction-bar'),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isIos ? 0.10 : 0.14),
            blurRadius: isIos ? 22 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: isIos
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 0.6,
                    ),
                  ),
                  child: barBody,
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE5E7EB),
                    width: 0.8,
                  ),
                ),
                child: barBody,
              ),
      ),
    );
  }
}
