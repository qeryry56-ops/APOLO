import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';

/// Compact, premium 54px rounded input card with an animated floating label.
///
/// Features:
/// - Compact 54px height to avoid overly tall inputs.
/// - Smooth floating label animation: centered as placeholder when empty/unfocused,
///   floats gracefully to top when active or filled.
/// - Zero grey background or underline artifacts.
/// - Vibrant interactive purple (#5E48E8) border and soft glow on focus.
/// - Secret text visibility toggle.
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
    final hasError = _error != null && _error!.isNotEmpty;

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
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFEF4444)
                      : (_isFocused
                          ? const Color(0xFF5E48E8)
                          : const Color(0xFFE5E7EB)),
                  width: _isFocused ? 1.8 : 1.2,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF5E48E8).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.015),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  // Animated Floating Label
                  AnimatedPositionedDirectional(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    top: _shouldFloat ? 7 : 17,
                    start: 0,
                    end: widget.secret ? 36 : 0,
                    child: IgnorePointer(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontFamily: AppConfig.fontPrimary,
                          fontSize: _shouldFloat ? 10.5 : 14.5,
                          fontWeight: _shouldFloat
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: hasError
                              ? const Color(0xFFEF4444)
                              : (_isFocused
                                  ? const Color(0xFF5E48E8)
                                  : (_hasContent
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF9CA3AF))),
                          letterSpacing: -0.1,
                        ),
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // Input Text Field & Secret Toggle
                  Positioned(
                    top: _shouldFloat ? 16 : 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        Expanded(
                          child: Theme(
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
                              textDirection:
                                  widget.ltr ? TextDirection.ltr : null,
                              keyboardType: widget.type,
                              autofillHints: widget.autofill,
                              obscureText: widget.secret && _obscure,
                              autocorrect: false,
                              enableSuggestions: !widget.secret,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                fontFamily: AppConfig.fontPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                                letterSpacing: -0.2,
                              ),
                              cursorColor: const Color(0xFF5E48E8),
                              cursorHeight: 18,
                              inputFormatters: widget.type == TextInputType.number
                                  ? [
                                      TextInputFormatter.withFunction(
                                        (oldValue, newValue) =>
                                            newValue.copyWith(
                                          text:
                                              AccountValidation.normalizeDigits(
                                            newValue.text,
                                          ),
                                        ),
                                      ),
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ]
                                  : null,
                              validator: (value) {
                                final err = widget.validator(value);
                                if (mounted && err != _error) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
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
                                errorStyle:
                                    const TextStyle(height: 0, fontSize: 0),
                                hintText: _shouldFloat ? widget.hint : null,
                                hintStyle: const TextStyle(
                                  fontFamily: AppConfig.fontPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.secret)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _obscure = !_obscure);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: AppConfig.fontPrimary,
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
