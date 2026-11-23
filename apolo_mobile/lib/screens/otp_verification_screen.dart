import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

/// Android 5.0+ SMS Auto-Read implementation using Google Play Services
/// SMS User Consent API via `smart_auth` + `pinput`'s [SmsRetriever] interface.
///
/// Works on Android 5.0+ without requiring `READ_SMS` permissions and safely
/// no-ops on iOS/Web/Desktop.
class SmartAuthSmsRetriever implements SmsRetriever {
  SmartAuthSmsRetriever({
    SmartAuth? smartAuth,
    this.useRetrieverApi = false,
  }) : _smartAuth = smartAuth ?? SmartAuth.instance;

  final SmartAuth _smartAuth;

  /// Set `true` if your backend appends the 11-char Android App Hash to SMS
  /// (SMS Retriever API); leave `false` to use SMS User Consent API.
  final bool useRetrieverApi;

  @override
  bool get listenForMultipleSms => false;

  @override
  Future<String?> getSmsCode() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final res = useRetrieverApi
          ? await _smartAuth.getSmsWithRetrieverApi(matcher: r'\d{6}')
          : await _smartAuth.getSmsWithUserConsentApi(matcher: r'\d{6}');
      if (res.hasData) {
        final code = res.data?.code?.trim();
        if (code != null && code.length == 6) {
          return code;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> dispose() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      if (useRetrieverApi) {
        await _smartAuth.removeSmsRetrieverApiListener();
      } else {
        await _smartAuth.removeUserConsentApiListener();
      }
    } catch (_) {}
  }
}

/// Premium minimalist 6-digit OTP Verification Screen built with `pinput`:
///
/// - **Pinput Setup**: 6 digits, auto-focus next, auto-paste 6-digit clipboard code,
///   auto-submit via `onCompleted`, backspace moves to previous box, numeric keyboard only.
/// - **Theming (4 visual states)**:
///   - Default: gray border (`#D1D5DB`), white background.
///   - Focused: blue border (`#2563EB`) with subtle elevation shadow.
///   - Submitted / Verified: green border (`#16A34A`) + checkmark icon.
///   - Error: red border (`#DC2626`) + horizontal shake animation.
/// - **Error Handling**:
///   - Shakes all 6 boxes on invalid code.
///   - Holds red border for 2 seconds with `"Code incorrect, try again"`.
///   - Clears fields automatically after the shake animation.
/// - **Android SMS Auto-Read**:
///   - Uses [SmartAuthSmsRetriever] (`SmsRetriever` + `SmartAuth`) on Android 5.0+.
/// - **Resend Countdown**:
///   - 30-second countdown timer before enabling `"Resend code"`.
class OtpVerificationScreen extends StatefulWidget {
  final String destination;
  final Future<bool> Function(String code) onVerify;
  final Future<void> Function()? onResend;
  final VoidCallback? onSuccess;
  final SmsRetriever? smsRetriever;
  final int initialResendSeconds;

  const OtpVerificationScreen({
    super.key,
    required this.destination,
    required this.onVerify,
    this.onResend,
    this.onSuccess,
    this.smsRetriever,
    this.initialResendSeconds = 30,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final SmsRetriever _smsRetriever;
  late final AnimationController _shakeController;

  Timer? _resendTimer;
  Timer? _errorResetTimer;

  late int _secondsRemaining;
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _isError = false;
  String? _errorMessage;

  static const Color _bgWhite = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _defaultBorder = Color(0xFFD1D5DB);
  static const Color _focusedBlue = Color(0xFF2563EB);
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _errorRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialResendSeconds;
    _smsRetriever = widget.smsRetriever ?? SmartAuthSmsRetriever();

    // Horizontal damped shake controller for invalid OTP feedback
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _errorResetTimer?.cancel();
    _shakeController.dispose();
    _smsRetriever.dispose();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = widget.initialResendSeconds);
    if (_secondsRemaining <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isVerifying) return;
    HapticFeedback.lightImpact();
    _errorResetTimer?.cancel();
    setState(() {
      _isError = false;
      _errorMessage = null;
      _isVerified = false;
    });
    _pinController.clear();
    _startResendCountdown();
    await widget.onResend?.call();
  }

  void _handleClipboardFound(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 6 && !_isVerifying && !_isVerified) {
      _pinController.setText(digits);
    }
  }

  Future<void> _handleCompleted(String pin) async {
    if (_isVerifying || _isVerified) return;
    HapticFeedback.selectionClick();
    _errorResetTimer?.cancel();

    setState(() {
      _isVerifying = true;
      _isError = false;
      _errorMessage = null;
    });

    bool ok = false;
    try {
      ok = await widget.onVerify(pin);
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    if (ok) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _isError = false;
        _errorMessage = null;
      });
      widget.onSuccess?.call();
      return;
    }

    // Invalid OTP: shake all boxes, show red border for 2 seconds, show error message,
    // and clear fields right after the shake completes.
    HapticFeedback.vibrate();
    setState(() {
      _isVerifying = false;
      _isVerified = false;
      _isError = true;
      _errorMessage = 'Code incorrect, try again';
    });

    await _shakeController.forward(from: 0.0);
    if (!mounted) return;

    // Clear fields immediately after shake completes
    _pinController.clear();
    _focusNode.requestFocus();

    // Keep red border active for 2 seconds
    _errorResetTimer?.cancel();
    _errorResetTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isError = false;
      });
    });
  }

  PinTheme _buildDefaultPinTheme() {
    return PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _ink,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: BoxDecoration(
        color: _bgWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _defaultBorder, width: 1.4),
      ),
    );
  }

  PinTheme _buildFocusedPinTheme(PinTheme base) {
    return base.copyWith(
      decoration: base.decoration!.copyWith(
        color: _bgWhite,
        border: Border.all(color: _focusedBlue, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: _focusedBlue.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  PinTheme _buildSubmittedPinTheme(PinTheme base) {
    return base.copyWith(
      decoration: base.decoration!.copyWith(
        color: _successGreen.withValues(alpha: 0.06),
        border: Border.all(color: _successGreen, width: 1.6),
      ),
    );
  }

  PinTheme _buildErrorPinTheme(PinTheme base) {
    return base.copyWith(
      decoration: base.decoration!.copyWith(
        color: _errorRed.withValues(alpha: 0.05),
        border: Border.all(color: _errorRed, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultTheme = _buildDefaultPinTheme();
    final focusedTheme = _buildFocusedPinTheme(defaultTheme);
    final submittedTheme = _buildSubmittedPinTheme(defaultTheme);
    final errorTheme = _buildErrorPinTheme(defaultTheme);

    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppBar(
        backgroundColor: _bgWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: _ink,
            size: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Minimalist Header Icon / Verified Checkmark
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: _isVerified
                        ? Container(
                            key: const Key('otp-verified-icon'),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _successGreen.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: _successGreen,
                              size: 34,
                            ),
                          )
                        : Container(
                            key: const Key('otp-lock-icon'),
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.lock_shield_fill,
                              color: _ink,
                              size: 28,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Verify your code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to ${widget.destination}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Centered 6-digit Pinput wrapped in damped horizontal shake animation
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final t = _shakeController.value;
                      // Smooth damped sinusoidal shake (+/- 10px)
                      final dx = math.sin(t * math.pi * 6) * 10.0 * (1.0 - t);
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Pinput(
                        key: const Key('otp-pinput'),
                        length: 6,
                        controller: _pinController,
                        focusNode: _focusNode,
                        autofocus: true,
                        smsRetriever: _smsRetriever,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        defaultPinTheme: defaultTheme,
                        focusedPinTheme: focusedTheme,
                        submittedPinTheme: submittedTheme,
                        errorPinTheme: errorTheme,
                        forceErrorState: _isError,
                        pinputAutovalidateMode:
                            PinputAutovalidateMode.onSubmit,
                        showCursor: true,
                        cursor: Container(
                          width: 2,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _focusedBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        onClipboardFound: _handleClipboardFound,
                        onChanged: (val) {
                          if (_isError && val.isNotEmpty) {
                            setState(() {
                              _isError = false;
                              _errorMessage = null;
                            });
                          }
                        },
                        onCompleted: _handleCompleted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status row: Loading / Verified Checkmark / Error Message
                  SizedBox(
                    height: 26,
                    child: Center(
                      child: _isVerifying
                          ? const CupertinoActivityIndicator(radius: 10)
                          : _isVerified
                              ? const Row(
                                  key: Key('otp-verified-badge'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.checkmark_circle_fill,
                                      size: 16,
                                      color: _successGreen,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Code verified',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _successGreen,
                                      ),
                                    ),
                                  ],
                                )
                              : (_errorMessage != null
                                  ? Text(
                                      _errorMessage!,
                                      key: const Key('otp-error-text'),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: _errorRed,
                                      ),
                                    )
                                  : const SizedBox.shrink()),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resend code button with 30-second countdown timer
                  TextButton(
                    key: const Key('otp-resend-button'),
                    onPressed: _secondsRemaining == 0 && !_isVerifying
                        ? _handleResend
                        : null,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: _focusedBlue,
                      disabledForegroundColor: _muted,
                    ),
                    child: Text(
                      _secondsRemaining > 0
                          ? 'Resend code in ${_secondsRemaining}s'
                          : 'Resend code',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
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
