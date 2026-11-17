import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../theme/app_typography.dart';

/// Meta-style 59px rounded input container with an inner animated floating label.
///
/// Features:
/// - Smooth 180ms ease-out floating label transition: vertically centered when
///   empty/unfocused, anchors cleanly to top-start (`8px`) on focus or fill.
/// - Light (`#FFFFFF`) and dark (`#1E1E1E`) surface tokens with 1px inactive
///   border (`#E5E7EB` / `#333333`) transitioning to 2px active `#E31B23`.
/// - Optional leading country/prefix badge (e.g. `+212` Moroccan phone pill).
/// - 44x44px vertically centered password visibility toggle on the trailing edge.
class CustomAuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String keyName;
  final FormFieldValidator<String> validator;
  final bool secret;
  final bool ltr;
  final TextInputType? type;
  final Iterable<String>? autofill;
  final String? hint;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Color focusColor;
  final TextInputAction textInputAction;
  final VoidCallback? onFieldSubmitted;
  final Widget? prefixBadge;

  const CustomAuthInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.keyName,
    required this.validator,
    this.secret = false,
    this.ltr = true,
    this.type,
    this.autofill,
    this.hint,
    this.enabled = true,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.focusColor = AppConfig.primary,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.prefixBadge,
  });

  @override
  State<CustomAuthInputField> createState() => _CustomAuthInputFieldState();
}

class _CustomAuthInputFieldState extends State<CustomAuthInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _obscure = true;
  String? _error;

  bool get _isFocused => _focusNode.hasFocus;
  bool get _hasContent => widget.controller.text.isNotEmpty;
  bool get _shouldFloat => _isFocused || _hasContent;

  @override
  void initState() {
    super.initState();
    _obscure = widget.secret;
    _focusNode.addListener(_onStateChange);
    widget.controller.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onStateChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = _error != null && _error!.isNotEmpty;
    final animDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);

    final Color bgSurface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color borderColor = hasError
        ? const Color(0xFFEF4444)
        : (_isFocused
            ? widget.focusColor
            : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)));
    final Color labelColor = hasError
        ? const Color(0xFFEF4444)
        : (_isFocused
            ? widget.focusColor
            : (_shouldFloat
                ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
                : const Color(0xFF8E8E93)));
    final Color textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final Color hintColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    final Widget textFormField = Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
      child: TextFormField(
        key: Key(widget.keyName),
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        textDirection: widget.ltr ? TextDirection.ltr : null,
        keyboardType: widget.type,
        autofillHints: widget.autofill,
        obscureText: widget.secret && _obscure,
        autocorrect: false,
        enableSuggestions: !widget.secret,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: AppTypography.trackingForContext(context, -0.2),
        ),
        cursorColor: widget.focusColor,
        cursorHeight: 19,
        inputFormatters: widget.type == TextInputType.number
            ? [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) => newValue.copyWith(
                    text: AccountValidation.normalizeDigits(newValue.text),
                  ),
                ),
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ]
            : null,
        validator: (value) {
          final err = widget.validator(value);
          if (mounted && err != _error) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _error = err);
            });
          }
          return err != null ? '' : null;
        },
        onChanged: (val) {
          if (_error != null) {
            setState(() => _error = null);
          }
          widget.onChanged?.call(val);
        },
        decoration: InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          hintText: _shouldFloat ? widget.hint : null,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: hintColor,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (widget.onTap != null) {
                widget.onTap!();
              } else if (widget.enabled && !widget.readOnly) {
                _focusNode.requestFocus();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: animDuration,
              curve: Curves.easeOut,
              height: 59,
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused || hasError ? 2.0 : 1.0,
                ),
              ),
              padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  // Meta-style Floating Label (centered at 18px -> anchors top-start 8px)
                  AnimatedPositionedDirectional(
                    duration: animDuration,
                    curve: Curves.easeOut,
                    top: _shouldFloat ? 8.0 : 18.0,
                    start: 0,
                    end: widget.secret ? 44 : 4,
                    child: IgnorePointer(
                      child: AnimatedDefaultTextStyle(
                        duration: animDuration,
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: _shouldFloat ? 11.5 : 15,
                          fontWeight: _isFocused
                              ? FontWeight.w600
                              : (_shouldFloat
                                  ? FontWeight.w500
                                  : FontWeight.w400),
                          color: labelColor,
                          letterSpacing:
                              AppTypography.trackingForContext(context, -0.1),
                        ),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // Input Text Row (anchored on second line when floated)
                  PositionedDirectional(
                    top: _shouldFloat ? 21 : 0,
                    bottom: 0,
                    start: 0,
                    end: widget.secret ? 44 : 4,
                    child: widget.prefixBadge != null
                        ? Directionality(
                            textDirection: widget.ltr
                                ? TextDirection.ltr
                                : Directionality.of(context),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                widget.prefixBadge!,
                                const SizedBox(width: 8),
                                Expanded(child: textFormField),
                              ],
                            ),
                          )
                        : Center(child: textFormField),
                  ),

                  // Trailing Show/Hide Password Toggle (44x44px hit target, vertically centered)
                  if (widget.secret)
                    PositionedDirectional(
                      end: -4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _obscure = !_obscure);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Semantics(
                            button: true,
                            label: _obscure
                                ? 'إظهار كلمة المرور'
                                : 'إخفاء كلمة المرور',
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
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
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 12, right: 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
