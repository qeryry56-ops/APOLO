import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bug_report_models.dart';
import '../services/bug_report_api_service.dart';
import '../services/bug_report_log_service.dart';
import '../services/bug_report_screenshot_service.dart';
import 'bug_report_strings.dart';
import 'bug_report_theme.dart';

/// Step 3: Issue Composer & Screenshot Screen.
///
/// Designed to live inside a `PageRouteBuilder(opaque: false)` route so that
/// tapping "Screenshot" can temporarily paint `SizedBox.shrink()` for two frames
/// and capture the live underlying app screen without losing typed text.
class BugReportComposerScreen extends StatefulWidget {
  final BugReportStrings strings;
  final bool includeLogs;
  final BugReportContextSnapshot contextSnapshot;
  final BugScreenshotAttachment? initialScreenshot;
  final BugReportApiService apiService;
  final BugReportScreenshotService screenshotService;
  final Future<ScreenshotPickResult> Function()? onPickUpload;

  const BugReportComposerScreen({
    super.key,
    required this.strings,
    required this.includeLogs,
    required this.contextSnapshot,
    required this.apiService,
    required this.screenshotService,
    this.initialScreenshot,
    this.onPickUpload,
  });

  @override
  State<BugReportComposerScreen> createState() =>
      _BugReportComposerScreenState();
}

class _BugReportComposerScreenState extends State<BugReportComposerScreen> {
  final TextEditingController _descController = TextEditingController();
  final FocusNode _descFocus = FocusNode();

  BugScreenshotAttachment? _attachment;
  bool _submitting = false;
  bool _capturing = false;
  bool _hidingForCapture = false;
  bool _captureUnavailableHint = false;
  String? _errorMessage;
  bool _canRetrySubmit = false;

  @override
  void initState() {
    super.initState();
    _attachment = widget.initialScreenshot;
    if (_attachment == null) {
      _captureUnavailableHint = false;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _captureUnderlyingScreen() async {
    if (_capturing || _submitting) return;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    setState(() {
      _capturing = true;
      _hidingForCapture = true;
      _errorMessage = null;
      _canRetrySubmit = false;
    });

    BugScreenshotAttachment? captured;
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      captured = await widget.screenshotService.captureCurrentScreen(
        source: BugScreenshotSource.manualCapture,
      );
    } finally {
      if (mounted) {
        setState(() {
          _hidingForCapture = false;
          _capturing = false;
          if (captured != null) {
            _attachment = captured;
            _captureUnavailableHint = false;
          } else {
            _captureUnavailableHint = true;
          }
        });
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    if (_capturing || _submitting) return;
    HapticFeedback.selectionClick();

    setState(() {
      _errorMessage = null;
      _canRetrySubmit = false;
    });

    final result = widget.onPickUpload != null
        ? await widget.onPickUpload!()
        : await widget.screenshotService.pickFromGallery();

    if (!mounted || result.cancelled) return;

    if (result.attachment != null) {
      setState(() {
        _attachment = result.attachment;
        _captureUnavailableHint = false;
      });
      return;
    }

    final errorText = switch (result.error) {
      ScreenshotPickError.fileTooLarge => widget.strings.fileTooLargeError,
      ScreenshotPickError.unsupportedFormat =>
        widget.strings.unsupportedFormatError,
      ScreenshotPickError.emptyFile ||
      ScreenshotPickError.readFailed =>
        widget.strings.uploadFailedError,
      ScreenshotPickError.none => null,
    };

    if (errorText != null) {
      setState(() {
        _errorMessage = errorText;
        _canRetrySubmit = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final trimmed = _descController.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorMessage = widget.strings.descriptionEmptyError;
        _canRetrySubmit = false;
      });
      return;
    }
    if (trimmed.length < 5) {
      setState(() {
        _errorMessage = widget.strings.descriptionTooShortError;
        _canRetrySubmit = false;
      });
      return;
    }

    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _canRetrySubmit = false;
    });

    try {
      final diagnosticsSnapshot = widget.includeLogs
          ? BugReportLogService.instance.snapshotDiagnostics()
          : null;

      final submission = BugReportSubmission(
        description: trimmed,
        includeLogs: widget.includeLogs,
        context: widget.contextSnapshot,
        diagnosticsLogs: diagnosticsSnapshot,
        screenshot: _attachment,
      );

      final result = await widget.apiService.submitReport(submission);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on BugReportApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 429
          ? widget.strings.rateLimitError(e.retryAfterSeconds)
          : widget.strings.submitGenericError(e.message);
      setState(() {
        _submitting = false;
        _errorMessage = msg;
        _canRetrySubmit = e.statusCode != 422;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = widget.strings.submitGenericError(null);
        _canRetrySubmit = true;
      });
    }
  }

  void _openPreviewDialog() {
    final shot = _attachment;
    if (shot == null) return;
    final palette = BugReportPalette.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: palette.surface,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: Icon(Icons.close, color: palette.textPrimary),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(shot.bytes, fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hidingForCapture) {
      return const IgnorePointer(child: SizedBox.expand());
    }

    final palette = BugReportPalette.of(context);
    final strings = widget.strings;

    return Directionality(
      textDirection: strings.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.surface,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: palette.surface,
          foregroundColor: palette.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            tooltip: strings.close,
            icon: Icon(
              strings.isRtl
                  ? CupertinoIcons.chevron_right
                  : CupertinoIcons.chevron_left,
              color: palette.textPrimary,
              size: 22,
            ),
            onPressed:
                _submitting ? null : () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            strings.flowHeaderTitle,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _descController,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return TextButton(
                  key: const Key('bug-report-send-btn'),
                  onPressed: (_submitting || !hasText) ? null : _submit,
                  style: TextButton.styleFrom(
                    foregroundColor: palette.brandRed,
                    disabledForegroundColor:
                        palette.textSecondary.withValues(alpha: 0.45),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.brandRed,
                          ),
                        )
                      : Text(
                          strings.send,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Container(
                      key: const Key('bug-report-error-banner'),
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: palette.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.errorBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.exclamationmark_circle_fill,
                            size: 18,
                            color: palette.errorText,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: palette.errorText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_canRetrySubmit)
                            TextButton(
                              key: const Key('bug-report-retry-btn'),
                              onPressed: _submitting ? null : _submit,
                              child: Text(
                                strings.retry,
                                style: TextStyle(
                                  color: palette.brandRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Multi-line description input (fills space above keyboard)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: const InputDecorationTheme(
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        child: TextField(
                          key: const Key('bug-report-description-field'),
                          controller: _descController,
                          focusNode: _descFocus,
                          autofocus: true,
                          enabled: !_submitting,
                          maxLines: null,
                          expands: true,
                          maxLength: 2000,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 16,
                            height: 1.45,
                          ),
                          onChanged: (_) {
                            if (_errorMessage != null && !_canRetrySubmit) {
                              setState(() => _errorMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            counterText: '',
                            hintText: strings.descriptionHint,
                            hintStyle: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Attachment preview + Screenshot / Upload controls pinned above keyboard
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_attachment != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  key: const Key(
                                    'bug-report-screenshot-thumbnail',
                                  ),
                                  onTap: _openPreviewDialog,
                                  child: Tooltip(
                                    message: strings.previewScreenshotTooltip,
                                    child: Container(
                                      width: 72,
                                      height: 108,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: palette.border),
                                        color: palette.card,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.memory(
                                        _attachment!.bytes,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                PositionedDirectional(
                                  top: -8,
                                  end: -8,
                                  child: Material(
                                    color: palette.textPrimary,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: InkWell(
                                      key: const Key(
                                        'bug-report-remove-screenshot-btn',
                                      ),
                                      customBorder: const CircleBorder(),
                                      onTap: _submitting
                                          ? null
                                          : () {
                                              HapticFeedback.selectionClick();
                                              setState(() => _attachment = null);
                                            },
                                      child: Tooltip(
                                        message: strings.removeScreenshotTooltip,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: palette.surface,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: palette.surface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_captureUnavailableHint) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              strings.webCaptureFallbackHint,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _ComposerActionButton(
                                buttonKey:
                                    const Key('bug-report-capture-btn'),
                                palette: palette,
                                icon: CupertinoIcons.camera,
                                label: strings.screenshotButton,
                                loading: _capturing,
                                onTap: (_submitting || _capturing)
                                    ? null
                                    : _captureUnderlyingScreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ComposerActionButton(
                                buttonKey:
                                    const Key('bug-report-upload-btn'),
                                palette: palette,
                                icon: CupertinoIcons.photo,
                                label: strings.uploadButton,
                                onTap: (_submitting || _capturing)
                                    ? null
                                    : _uploadFromGallery,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _ComposerActionButton extends StatelessWidget {
  final Key buttonKey;
  final BugReportPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _ComposerActionButton({
    required this.buttonKey,
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.secondarySurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.textPrimary,
                  ),
                )
              else
                Icon(icon, size: 18, color: palette.textPrimary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
