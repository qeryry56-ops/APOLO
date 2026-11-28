import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dynamic Layer-inspired color tokens resolved cleanly for Light & Dark modes.
@immutable
class ApoloDlPalette {
  const ApoloDlPalette({
    required this.bg,
    required this.surfaceSubtle,
    required this.groupCard,
    required this.pill,
    required this.border,
    required this.separator,
    required this.ink,
    required this.onInk,
    required this.muted,
    required this.iconMuted,
    required this.subtle,
    required this.danger,
    required this.dangerSoft,
    required this.success,
    required this.successSoft,
    required this.info,
    required this.infoSoft,
  });

  final Color bg;
  final Color surfaceSubtle;
  final Color groupCard;
  final Color pill;
  final Color border;
  final Color separator;
  final Color ink;
  final Color onInk;
  final Color muted;
  final Color iconMuted;
  final Color subtle;
  final Color danger;
  final Color dangerSoft;
  final Color success;
  final Color successSoft;
  final Color info;
  final Color infoSoft;

  static const ApoloDlPalette light = ApoloDlPalette(
    bg: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF6F6F6),
    groupCard: Color(0xFFF6F6F6),
    pill: Color(0xFFEEEEEE),
    border: Color(0xFFE2E2E2),
    separator: Color(0xFFEEEEEE),
    ink: Color(0xFF000000),
    onInk: Color(0xFFFFFFFF),
    muted: Color(0xFF757575),
    iconMuted: Color(0xFF757575),
    subtle: Color(0xFFAFAFAF),
    danger: Color(0xFFE31B23),
    dangerSoft: Color(0xFFF6F6F6),
    success: Color(0xFF15803D),
    successSoft: Color(0xFFF6F6F6),
    info: Color(0xFF2997FF),
    infoSoft: Color(0xFFF6F6F6),
  );

  static const ApoloDlPalette dark = ApoloDlPalette(
    bg: Color(0xFF0A0A0A),
    surfaceSubtle: Color(0xFF161618),
    groupCard: Color(0xFF161618),
    pill: Color(0xFF222226),
    border: Color(0xFF2E2E34),
    separator: Color(0xFF242429),
    ink: Color(0xFFFFFFFF),
    onInk: Color(0xFF0A0A0A),
    muted: Color(0xFFA1A1AA),
    iconMuted: Color(0xFF8E8E93),
    subtle: Color(0xFF71717A),
    danger: Color(0xFFFF453A),
    dangerSoft: Color(0x29FF453A),
    success: Color(0xFF32D74B),
    successSoft: Color(0x2632D74B),
    info: Color(0xFF2997FF),
    infoSoft: Color(0x262997FF),
  );

  static ApoloDlPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// 1px hairline horizontal separator inspired by Dynamic Layer's DlSeparator.
class ApoloDlSeparator extends StatelessWidget {
  const ApoloDlSeparator({
    super.key,
    this.indentStart = 0,
    this.indentEnd = 0,
  });

  final double indentStart;
  final double indentEnd;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indentStart, end: indentEnd),
      child: SizedBox(
        width: double.infinity,
        height: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: palette.separator),
        ),
      ),
    );
  }
}

/// 40x40 circular icon button used in top navigation and modal headers.
class ApoloDlIconCircleButton extends StatelessWidget {
  const ApoloDlIconCircleButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.iconSize = 20,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final button = Material(
      color: backgroundColor ?? palette.pill,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? palette.ink,
            ),
          ),
        ),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

enum ApoloDlTopNavSize { md, lg }

/// Dynamic Layer-inspired top navigation bar supporting compact (`md`) and
/// bold large-title (`lg`) headers with automatic RTL/LTR chevron mirroring.
class ApoloDlTopNav extends StatelessWidget {
  const ApoloDlTopNav({
    required this.title,
    super.key,
    this.size = ApoloDlTopNavSize.md,
    this.showSeparator = false,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.horizontalPadding = 16,
    this.backButtonKey,
  });

  final String title;
  final ApoloDlTopNavSize size;
  final bool showSeparator;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double horizontalPadding;
  final Key? backButtonKey;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon =
        isRtl ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;
    final backTooltip = MaterialLocalizations.of(context).backButtonTooltip;
    final handleBack = onBack ?? () => Navigator.of(context).maybePop();

    return Container(
      width: double.infinity,
      color: palette.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (size == ApoloDlTopNavSize.md)
            SizedBox(
              height: 56,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    if (showBack)
                      ApoloDlIconCircleButton(
                        key: backButtonKey,
                        icon: backIcon,
                        tooltip: backTooltip,
                        onPressed: handleBack,
                      )
                    else
                      const SizedBox(width: 40, height: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: trailing ?? const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 56,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    if (showBack)
                      ApoloDlIconCircleButton(
                        key: backButtonKey,
                        icon: backIcon,
                        tooltip: backTooltip,
                        onPressed: handleBack,
                      ),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                14,
              ),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: palette.ink,
                ),
              ),
            ),
          ],
          if (showSeparator) const ApoloDlSeparator(),
        ],
      ),
    );
  }
}

/// Clean section label for grouped settings lists.
class ApoloDlSectionHeader extends StatelessWidget {
  const ApoloDlSectionHeader({
    required this.title,
    super.key,
    this.isFirst = false,
  });

  final String title;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: isFirst ? 12 : 24,
        bottom: 6,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.muted,
        ),
      ),
    );
  }
}

/// 24x24 Dynamic Layer-style circular radio indicator.
class ApoloDlRadio extends StatelessWidget {
  const ApoloDlRadio({
    required this.selected,
    super.key,
    this.disabled = false,
  });

  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final fillColor = selected
        ? (disabled ? palette.subtle : palette.ink)
        : palette.bg;

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: selected
                ? null
                : Border.all(
                    color: palette.border,
                    width: 1.2,
                  ),
          ),
          child: selected
              ? Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: palette.bg,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Custom 50x32 animated pill toggle switch (never wraps Material [Switch]).
class ApoloDlSwitch extends StatelessWidget {
  const ApoloDlSwitch({
    required this.value,
    super.key,
    this.onChanged,
    this.disabled = false,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final isInteractive = !disabled && onChanged != null;
    final trackColor = disabled
        ? palette.pill
        : (value ? (activeColor ?? const Color(0xFF16A34A)) : palette.border);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: !isInteractive
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onChanged!(!value);
            },
      child: Semantics(
        toggled: value,
        enabled: isInteractive,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 50,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment:
                value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ApoloDlButtonVariant { primary, secondary, tertiary, danger, dangerSoft }

enum ApoloDlButtonSize { lg, md, sm, xs }

/// Dynamic Layer-inspired button supporting primary, secondary, tertiary,
/// danger, and soft-danger styles with press feedback and loading state.
class ApoloDlButton extends StatefulWidget {
  const ApoloDlButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = ApoloDlButtonVariant.primary,
    this.size = ApoloDlButtonSize.lg,
    this.fullWidth = false,
    this.isLoading = false,
    this.leadingIcon,
    this.borderRadius,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final ApoloDlButtonVariant variant;
  final ApoloDlButtonSize size;
  final bool fullWidth;
  final bool isLoading;
  final IconData? leadingIcon;
  final double? borderRadius;
  final double? height;

  @override
  State<ApoloDlButton> createState() => _ApoloDlButtonState();
}

class _ApoloDlButtonState extends State<ApoloDlButton> {
  bool _pressed = false;

  double get _height =>
      widget.height ??
      switch (widget.size) {
        ApoloDlButtonSize.lg => 54,
        ApoloDlButtonSize.md => 48,
        ApoloDlButtonSize.sm => 40,
        ApoloDlButtonSize.xs => 32,
      };

  double get _fontSize => switch (widget.size) {
        ApoloDlButtonSize.lg => 15.5,
        ApoloDlButtonSize.md => 15,
        ApoloDlButtonSize.sm => 14,
        ApoloDlButtonSize.xs => 12.5,
      };

  double get _horizontalPadding => switch (widget.size) {
        ApoloDlButtonSize.lg => 20,
        ApoloDlButtonSize.md => 18,
        ApoloDlButtonSize.sm => 16,
        ApoloDlButtonSize.xs => 12,
      };

  double get _resolvedRadius =>
      widget.borderRadius ?? (widget.size == ApoloDlButtonSize.xs ? 999 : 14);

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final Color bg;
    final Color fg;
    BorderSide? side;

    switch (widget.variant) {
      case ApoloDlButtonVariant.primary:
        bg = palette.ink;
        fg = palette.onInk;
      case ApoloDlButtonVariant.secondary:
        bg = palette.pill;
        fg = palette.ink;
      case ApoloDlButtonVariant.tertiary:
        bg = palette.bg;
        fg = palette.ink;
        side = BorderSide(color: palette.border, width: 1.2);
      case ApoloDlButtonVariant.danger:
        bg = palette.danger;
        fg = Colors.white;
      case ApoloDlButtonVariant.dangerSoft:
        bg = palette.dangerSoft;
        fg = palette.danger;
    }

    final effectiveBg = isDisabled && widget.variant == ApoloDlButtonVariant.primary
        ? palette.subtle.withValues(alpha: 0.35)
        : bg;
    final effectiveFg = isDisabled && widget.variant == ApoloDlButtonVariant.primary
        ? palette.muted
        : fg;

    return AnimatedScale(
      scale: _pressed && !isDisabled ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: effectiveBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_resolvedRadius),
          side: side ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                },
          onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel:
              isDisabled ? null : () => setState(() => _pressed = false),
          child: SizedBox(
            width: widget.fullWidth ? double.infinity : null,
            height: _height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: Center(
                widthFactor: widget.fullWidth ? null : 1,
                child: widget.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: effectiveFg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.leadingIcon != null) ...[
                            Icon(
                              widget.leadingIcon,
                              size: _fontSize + 3,
                              color: effectiveFg,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.w700,
                                  color: effectiveFg,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ApoloDlAlertType { info, success, danger }

/// Inline feedback alert inspired by Dynamic Layer's DlAlert.
class ApoloDlAlert extends StatelessWidget {
  const ApoloDlAlert({
    required this.message,
    super.key,
    this.title,
    this.type = ApoloDlAlertType.info,
  });

  final String message;
  final String? title;
  final ApoloDlAlertType type;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final Color bg;
    final Color accent;
    final IconData icon;

    switch (type) {
      case ApoloDlAlertType.info:
        bg = palette.infoSoft;
        accent = palette.info;
        icon = CupertinoIcons.info_circle_fill;
      case ApoloDlAlertType.success:
        bg = palette.successSoft;
        accent = palette.success;
        icon = CupertinoIcons.check_mark_circled_solid;
      case ApoloDlAlertType.danger:
        bg = palette.dangerSoft;
        accent = palette.danger;
        icon = CupertinoIcons.exclamationmark_circle_fill;
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null && title!.trim().isNotEmpty) ...[
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ApoloDlLineItemType { chevron, radio, toggle, button, plain }

enum ApoloDlLineItemState { normal, disabled, danger, success }

/// Full-width settings / option row inspired by Dynamic Layer's DlLineItem.
class ApoloDlLineItem extends StatelessWidget {
  const ApoloDlLineItem({
    required this.title,
    super.key,
    this.description,
    this.leadingIcon,
    this.leadingWidget,
    this.trailingText,
    this.trailingBadge,
    this.type = ApoloDlLineItemType.chevron,
    this.state = ApoloDlLineItemState.normal,
    this.showSeparator = true,
    this.value = false,
    this.onChanged,
    this.buttonLabel,
    this.onButtonPressed,
    this.onTap,
    this.horizontalPadding = 0,
  });

  final String title;
  final String? description;
  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final String? trailingText;
  final Widget? trailingBadge;
  final ApoloDlLineItemType type;
  final ApoloDlLineItemState state;
  final bool showSeparator;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDisabled = state == ApoloDlLineItemState.disabled;
    final isDanger = state == ApoloDlLineItemState.danger;
    final isSuccess = state == ApoloDlLineItemState.success;

    final Color titleColor = isDisabled
        ? palette.subtle
        : isDanger
            ? palette.danger
            : palette.ink;

    final Color leadingColor = isDisabled
        ? palette.subtle
        : isDanger
            ? palette.danger
            : isSuccess
                ? palette.success
                : palette.ink;

    final bool hasDescription =
        description != null && description!.trim().isNotEmpty;

    VoidCallback? rowTap;
    if (!isDisabled) {
      if (type == ApoloDlLineItemType.radio ||
          type == ApoloDlLineItemType.toggle) {
        if (onChanged != null) {
          rowTap = () {
            HapticFeedback.selectionClick();
            onChanged!(!value);
          };
        } else if (onTap != null) {
          rowTap = () {
            HapticFeedback.selectionClick();
            onTap!();
          };
        }
      } else if (type != ApoloDlLineItemType.button && onTap != null) {
        rowTap = () {
          HapticFeedback.selectionClick();
          onTap!();
        };
      }
    }

    final Widget? trailingWidget = _buildTrailing(palette, isRtl, isDisabled);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: rowTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leadingWidget != null) ...[
                    leadingWidget!,
                    const SizedBox(width: 14),
                  ] else if (leadingIcon != null) ...[
                    Icon(
                      leadingIcon,
                      size: 22,
                      color: leadingColor,
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: isDisabled
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        if (hasDescription) ...[
                          const SizedBox(height: 2),
                          Text(
                            description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailingBadge != null) ...[
                    const SizedBox(width: 10),
                    trailingBadge!,
                  ],
                  if (trailingText != null &&
                      trailingText!.trim().isNotEmpty) ...[
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: _buildBidiTrailingText(trailingText!, palette),
                    ),
                  ],
                  if (trailingWidget != null) ...[
                    const SizedBox(width: 10),
                    trailingWidget,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showSeparator) const ApoloDlSeparator(),
      ],
    );
  }

  Widget _buildBidiTrailingText(String text, ApoloDlPalette palette) {
    final forceLtr = text.startsWith('@') ||
        text.startsWith('+') ||
        RegExp(r'^v?\d').hasMatch(text);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: forceLtr ? TextDirection.ltr : null,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: palette.muted,
      ),
    );
  }

  Widget? _buildTrailing(
    ApoloDlPalette palette,
    bool isRtl,
    bool isDisabled,
  ) {
    switch (type) {
      case ApoloDlLineItemType.chevron:
        return Icon(
          isRtl ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
          size: 18,
          color: isDisabled ? palette.subtle : palette.muted,
        );
      case ApoloDlLineItemType.radio:
        return ApoloDlRadio(
          selected: value,
          disabled: isDisabled,
        );
      case ApoloDlLineItemType.toggle:
        return ApoloDlSwitch(
          value: value,
          disabled: isDisabled,
          onChanged: onChanged,
        );
      case ApoloDlLineItemType.button:
        return ApoloDlButton(
          label: buttonLabel ?? '',
          size: ApoloDlButtonSize.xs,
          variant: ApoloDlButtonVariant.secondary,
          onPressed: isDisabled ? null : onButtonPressed,
        );
      case ApoloDlLineItemType.plain:
        return null;
    }
  }
}

/// Shows a Dynamic Layer-styled modal bottom sheet with centered header title,
/// circular close button, optional media & text, and stacked action buttons.
Future<T?> showApoloDlBottomSheet<T>(
  BuildContext context, {
  required String headerTitle,
  Widget? media,
  String? contentTitle,
  String? contentDescription,
  List<Widget> actions = const [],
}) {
  final palette = ApoloDlPalette.of(context);
  final textDirection = Directionality.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return Directionality(
        textDirection: textDirection,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 40, height: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            headerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ApoloDlIconCircleButton(
                          icon: CupertinoIcons.xmark,
                          iconSize: 18,
                          onPressed: () => Navigator.of(sheetCtx).maybePop(),
                        ),
                      ],
                    ),
                  ),
                ),
                const ApoloDlSeparator(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (media != null) ...[
                        Center(child: media),
                        const SizedBox(height: 16),
                      ],
                      if (contentTitle != null &&
                          contentTitle.trim().isNotEmpty) ...[
                        Text(
                          contentTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (contentDescription != null &&
                          contentDescription.trim().isNotEmpty) ...[
                        Text(
                          contentDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.45,
                            color: palette.muted,
                          ),
                        ),
                      ],
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        for (int i = 0; i < actions.length; i++) ...[
                          actions[i],
                          if (i < actions.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Dynamic Layer v5.1 Settings section group: crisp dark label above a rounded
/// #F6F6F6 flat container with hairline #EEEEEE row separators and zero shadows.
class ApoloDlSettingsGroup extends StatelessWidget {
  const ApoloDlSettingsGroup({
    required this.title,
    required this.children,
    super.key,
    this.isFirst = false,
  });

  final String title;
  final List<Widget> children;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: palette.groupCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 54,
                        end: 10,
                      ),
                      child: SizedBox(
                        height: 1,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: palette.separator),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual row inside an [ApoloDlSettingsGroup] matching Dynamic Layer v5.1's
/// 32x32 #FFFFFF icon circle + crisp #000000 label + chevron minimalism.
class ApoloDlGroupedItem extends StatelessWidget {
  const ApoloDlGroupedItem({
    required this.icon,
    required this.title,
    super.key,
    this.onTap,
    this.trailingText,
    this.trailingBadge,
    this.showChevron = true,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final String? trailingText;
  final Widget? trailingBadge;
  final bool showChevron;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final bool hasTrailingText =
        trailingText != null && trailingText!.trim().isNotEmpty;
    final bool forceLtr = hasTrailingText &&
        (trailingText!.startsWith('@') ||
            trailingText!.startsWith('+') ||
            RegExp(r'^v?\d').hasMatch(trailingText!));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disabled || onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: palette.bg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 16.5,
                  color: disabled ? palette.subtle : palette.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: disabled ? palette.subtle : palette.ink,
                  ),
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 8),
                trailingBadge!,
              ],
              if (hasTrailingText) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: forceLtr ? TextDirection.ltr : null,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.muted,
                    ),
                  ),
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  isRtl
                      ? CupertinoIcons.chevron_left
                      : CupertinoIcons.chevron_right,
                  size: 14,
                  color: disabled ? palette.subtle : palette.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tabular metric column for [ApoloDlAccountHeader].
@immutable
class ApoloDlAccountStat {
  const ApoloDlAccountStat({
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;
}

/// Dynamic Layer v5.1 centered Account Header used in Profile and Seller Profile.
/// Renders a 72x72 circular avatar, centered name & @handle, 3 dividerless
/// tabular stats, two equal side-by-side pill actions, and centered bio text.
class ApoloDlAccountHeader extends StatelessWidget {
  const ApoloDlAccountHeader({
    required this.avatar,
    required this.displayName,
    required this.handle,
    required this.stats,
    required this.primaryAction,
    required this.secondaryAction,
    super.key,
    this.onAvatarTap,
    this.onNameTap,
    this.nameTrailing,
    this.bio,
    this.extraActions,
  });

  final Widget avatar;
  final String displayName;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNameTap;
  final Widget? nameTrailing;
  final String handle;
  final List<ApoloDlAccountStat> stats;
  final Widget primaryAction;
  final Widget secondaryAction;
  final String? bio;
  final Widget? extraActions;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final bool hasBio = bio != null && bio!.trim().isNotEmpty;
    final bool forceLtrHandle = handle.trim().startsWith('@');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: palette.groupCard,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: avatar,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onNameTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              if (nameTrailing != null) ...[
                const SizedBox(width: 6),
                nameTrailing!,
              ],
            ],
          ),
        ),
        if (handle.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            handle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: forceLtrHandle ? TextDirection.ltr : null,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: palette.muted,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: stats.map((stat) {
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: stat.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: primaryAction),
            const SizedBox(width: 12),
            Expanded(child: secondaryAction),
          ],
        ),
        if (hasBio) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(
              bio!.trim(),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: palette.ink,
              ),
            ),
          ),
        ],
        if (extraActions != null) ...[
          const SizedBox(height: 16),
          extraActions!,
        ],
      ],
    );
  }
}

/// Dynamic Layer v5.1 `Empty State` (`44239:11751`):
/// - Centered minimalist visual (custom widget, clean asset image, `#EEEEEE` icon circle,
///   or official `#E31828` Apolo brand squircle)
/// - `20px Bold` `#000000` headline
/// - `15px Regular` `#757575` description (`maxWidth: 295px`)
/// - Hug-width `#EEEEEE` stadium pill CTA (`52px` height, `#000000` `15px Bold` label, e.g. `Try again`)
class ApoloDlEmptyState extends StatelessWidget {
  const ApoloDlEmptyState({
    required this.headline,
    required this.description,
    super.key,
    this.visual,
    this.assetPath,
    this.icon,
    this.imageSize = 128.0,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.actionKey,
  });

  final String headline;
  final String description;
  final Widget? visual;
  final String? assetPath;
  final IconData? icon;
  final double imageSize;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Key? actionKey;

  Widget _buildVisual(ApoloDlPalette palette) {
    if (visual != null) return visual!;

    if (assetPath != null && assetPath!.trim().isNotEmpty) {
      return SizedBox(
        width: imageSize,
        height: imageSize,
        child: Image.asset(
          assetPath!,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Container(
            width: 88.0,
            height: 88.0,
            decoration: BoxDecoration(
              color: palette.pill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon ?? CupertinoIcons.sparkles,
              size: 36.0,
              color: palette.ink,
            ),
          ),
        ),
      );
    }

    if (icon != null) {
      return Container(
        width: 88.0,
        height: 88.0,
        decoration: BoxDecoration(
          color: palette.pill,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 36.0,
          color: palette.ink,
        ),
      );
    }

    return Container(
      width: 96.0,
      height: 96.0,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE31828),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Image.asset(
        'assets/images/apolo_logo_white_transparent.png',
        fit: BoxFit.contain,
        semanticLabel: 'Apolo',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: const Key('dl-empty-state-visual'),
              child: _buildVisual(palette),
            ),
            const SizedBox(height: 28.0),
            Text(
              headline,
              key: const Key('dl-empty-state-headline'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.ink,
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                height: 28.0 / 20.0,
                letterSpacing: -0.2,
              ),
            ),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 8.0),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 295.0),
                child: Text(
                  description,
                  key: const Key('dl-empty-state-description'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400,
                    height: 22.0 / 15.0,
                  ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32.0),
              Material(
                color: palette.pill,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: actionKey ?? const Key('dl-empty-state-action'),
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAction!();
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              actionLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                height: 22.0 / 15.0,
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
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 12.0),
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel!,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



