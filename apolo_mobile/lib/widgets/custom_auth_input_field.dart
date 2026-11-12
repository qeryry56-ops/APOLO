import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';

/// Clean, high-fidelity rounded input card with stacked label and inner text field.
///
/// Fully eliminates default grey fill artifacts and highlights with a vibrant purple
/// (#5E48E8) border on active focus, exactly matching the reference design.
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
  });

  @override
  State<CustomAuthInputField> createState() => _CustomAuthInputFieldState();
}

class _CustomAuthInputFieldState extends State<CustomAuthInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _obscure = widget.secret;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null && _error!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: AppConfig.fontPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: hasError
                        ? const Color(0xFFEF4444)
                        : (_isFocused
                            ? const Color(0xFF5E48E8)
                            : const Color(0xFF6B7280)),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
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
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                            letterSpacing: -0.2,
                          ),
                          cursorColor: const Color(0xFF5E48E8),
                          inputFormatters: widget.type == TextInputType.number
                              ? [
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) => newValue.copyWith(
                                      text: AccountValidation.normalizeDigits(
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
                            hintText: widget.hint,
                            hintStyle: const TextStyle(
                              fontFamily: AppConfig.fontPrimary,
                              fontSize: 15.5,
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
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 16, right: 16),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontFamily: AppConfig.fontPrimary,
                  fontSize: 12,
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
