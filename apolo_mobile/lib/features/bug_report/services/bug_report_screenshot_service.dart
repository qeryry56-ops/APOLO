import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bug_report_models.dart';
import 'bug_report_log_service.dart';

enum ScreenshotPickError {
  none,
  fileTooLarge,
  unsupportedFormat,
  emptyFile,
  readFailed,
}

class ScreenshotPickResult {
  final BugScreenshotAttachment? attachment;
  final bool cancelled;
  final ScreenshotPickError error;

  const ScreenshotPickResult({
    this.attachment,
    this.cancelled = false,
    this.error = ScreenshotPickError.none,
  });
}

/// Captures the app RepaintBoundary and validates gallery/file uploads
/// across Chrome Web and iOS without importing `dart:io`.
class BugReportScreenshotService {
  BugReportScreenshotService({GlobalKey? boundaryKey})
      : boundaryKey = boundaryKey ?? GlobalKey();

  static final BugReportScreenshotService instance =
      BugReportScreenshotService();

  /// Key attached to the root [RepaintBoundary] in [ApoloMobileApp].
  final GlobalKey boundaryKey;

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Captures the current screen wrapped by [boundaryKey].
  ///
  /// Returns `null` gracefully if the boundary is unavailable or if Web
  /// CanvasKit/CORS/HtmlElementView prevents pixel readback.
  Future<BugScreenshotAttachment?> captureCurrentScreen({
    double? maxPixelRatio,
    BugScreenshotSource source = BugScreenshotSource.autoCapture,
  }) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final ctx = boundaryKey.currentContext;
      if (ctx == null) return null;

      final renderObj = ctx.findRenderObject();
      if (renderObj is! RenderRepaintBoundary) return null;

      if (renderObj.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await WidgetsBinding.instance.endOfFrame;
      }
      if (renderObj.debugNeedsPaint) return null;

      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final dpr = view.devicePixelRatio > 0 ? view.devicePixelRatio : 1.0;
      final cappedRatio = math.min(dpr, maxPixelRatio ?? 1.5).clamp(0.5, 2.0);

      var bytes = await _rasterizeBoundary(renderObj, cappedRatio.toDouble());
      if (bytes == null) return null;

      if (bytes.length > maxFileSizeBytes) {
        final smaller = await _rasterizeBoundary(renderObj, 0.85);
        if (smaller != null && smaller.length <= maxFileSizeBytes) {
          bytes = smaller;
        } else {
          BugReportLogService.instance.log(
            'Auto screenshot skipped: exceeded 5MB limit (${bytes.length} bytes)',
            level: BugLogLevel.warning,
            tag: 'screenshot',
          );
          return null;
        }
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      return BugScreenshotAttachment(
        bytes: bytes,
        filename: 'apolo_bug_$ts.png',
        mimeType: 'image/png',
        source: source,
      );
    } catch (e) {
      BugReportLogService.instance.log(
        'Screenshot capture unavailable on current platform/view: $e',
        level: BugLogLevel.warning,
        tag: 'screenshot',
      );
      return null;
    }
  }

  Future<Uint8List?> _rasterizeBoundary(
    RenderRepaintBoundary boundary,
    double pixelRatio,
  ) async {
    ui.Image? image;
    try {
      image = await boundary
          .toImage(pixelRatio: pixelRatio)
          .timeout(const Duration(seconds: 2));
      final byteData = await image
          .toByteData(format: ui.ImageByteFormat.png)
          .timeout(const Duration(seconds: 2));
      return byteData?.buffer.asUint8List();
    } finally {
      image?.dispose();
    }
  }

  /// Picks an image from gallery (iOS) or file dialog (Chrome Web) and validates
  /// magic bytes and the 5 MB limit before returning.
  Future<ScreenshotPickResult> pickFromGallery({ImagePicker? picker}) async {
    try {
      final activePicker = picker ?? ImagePicker();
      final picked = await activePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picked == null) {
        return const ScreenshotPickResult(cancelled: true);
      }

      final bytes = await picked.readAsBytes();
      return validatePickedImageBytes(
        bytes: bytes,
        originalName: picked.name,
        mimeHint: picked.mimeType,
      );
    } catch (e) {
      BugReportLogService.instance.log(
        'Image picker failed: $e',
        level: BugLogLevel.warning,
        tag: 'screenshot',
      );
      return const ScreenshotPickResult(error: ScreenshotPickError.readFailed);
    }
  }

  /// Validates bytes against size and magic-byte image signatures (PNG/JPEG/WebP).
  static ScreenshotPickResult validatePickedImageBytes({
    required Uint8List bytes,
    required String originalName,
    String? mimeHint,
  }) {
    if (bytes.isEmpty) {
      return const ScreenshotPickResult(error: ScreenshotPickError.emptyFile);
    }
    if (bytes.length > maxFileSizeBytes) {
      return const ScreenshotPickResult(
        error: ScreenshotPickError.fileTooLarge,
      );
    }

    final mime = detectImageMimeType(bytes, originalName, mimeHint: mimeHint);
    if (mime == null) {
      return const ScreenshotPickResult(
        error: ScreenshotPickError.unsupportedFormat,
      );
    }

    final ext = switch (mime) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final safeStem = originalName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final stem = safeStem.isEmpty ? 'upload' : safeStem;

    return ScreenshotPickResult(
      attachment: BugScreenshotAttachment(
        bytes: bytes,
        filename: '${stem}_${DateTime.now().millisecondsSinceEpoch}.$ext',
        mimeType: mime,
        source: BugScreenshotSource.galleryUpload,
      ),
    );
  }

  /// Detects PNG, JPEG, or WebP from binary file signatures.
  static String? detectImageMimeType(
    Uint8List bytes,
    String filename, {
    String? mimeHint,
  }) {
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    // JPEG: FF D8 FF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return null;
  }
}
