import 'dart:typed_data';

/// Severity/category level for in-memory bug reporting diagnostics.
enum BugLogLevel {
  info,
  warning,
  error,
  navigation,
  network,
}

/// Single sanitized diagnostic log or navigation/API breadcrumb entry.
class BugLogEntry {
  final DateTime timestampUtc;
  final BugLogLevel level;
  final String tag;
  final String message;
  final Map<String, dynamic>? meta;

  const BugLogEntry({
    required this.timestampUtc,
    required this.level,
    required this.tag,
    required this.message,
    this.meta,
  });

  Map<String, dynamic> toJson() {
    return {
      'ts': timestampUtc.toIso8601String(),
      'level': level.name,
      'tag': tag,
      'message': message,
      if (meta != null && meta!.isNotEmpty) 'meta': meta,
    };
  }
}

/// Origin of a screenshot attached to a bug report.
enum BugScreenshotSource {
  autoCapture,
  manualCapture,
  galleryUpload,
}

/// Cross-platform in-memory screenshot attachment (zero dart:io dependency).
class BugScreenshotAttachment {
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final BugScreenshotSource source;

  const BugScreenshotAttachment({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.source,
  });

  int get sizeBytes => bytes.length;
}

/// Context captured right before presenting the bug reporter flow.
///
/// Separates always-collected basic operational context from optional
/// device/viewport metadata that is only sent if the user opts into logs.
class BugReportContextSnapshot {
  final int? userId;
  final String appVersion;
  final String platform;
  final String locale;
  final bool isRtl;
  final String routeName;
  final Map<String, dynamic> optionalDeviceMeta;

  const BugReportContextSnapshot({
    required this.userId,
    required this.appVersion,
    required this.platform,
    required this.locale,
    required this.isRtl,
    required this.routeName,
    this.optionalDeviceMeta = const {},
  });

  /// Minimal operational flags allowed even when optional logs are declined.
  Map<String, dynamic> toBasicDeviceMeta() {
    return {
      'is_rtl': isRtl,
      'authenticated': userId != null,
    };
  }

  /// Full context metadata attached only when `includeLogs == true`.
  Map<String, dynamic> toFullDeviceMeta() {
    return {
      ...optionalDeviceMeta,
      ...toBasicDeviceMeta(),
    };
  }
}

/// Complete payload passed to [BugReportApiService.submitReport].
class BugReportSubmission {
  final String description;
  final bool includeLogs;
  final BugReportContextSnapshot context;
  final Map<String, dynamic>? diagnosticsLogs;
  final BugScreenshotAttachment? screenshot;

  const BugReportSubmission({
    required this.description,
    required this.includeLogs,
    required this.context,
    this.diagnosticsLogs,
    this.screenshot,
  });
}

/// Successful response returned by `POST /api/support/bug-reports`.
class BugReportResult {
  final int id;
  final String status;
  final String? createdAt;
  final String? message;

  const BugReportResult({
    required this.id,
    required this.status,
    this.createdAt,
    this.message,
  });

  factory BugReportResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final rawId = rawData['id'] ?? json['id'] ?? 0;
    final parsedId = rawId is int ? rawId : (int.tryParse('$rawId') ?? 0);

    return BugReportResult(
      id: parsedId,
      status: (rawData['status'] ?? json['status'] ?? 'open').toString(),
      createdAt: rawData['created_at']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

/// Structured API error raised when submitting a bug report fails.
class BugReportApiException implements Exception {
  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;
  final Map<String, List<String>>? validationErrors;

  const BugReportApiException({
    required this.message,
    this.statusCode,
    this.retryAfterSeconds,
    this.validationErrors,
  });

  @override
  String toString() =>
      'BugReportApiException(statusCode: $statusCode, message: $message)';
}
