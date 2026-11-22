import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/bug_report_models.dart';

/// Bounded, sanitized in-memory ring buffer for technical diagnostics.
///
/// Logs remain strictly in RAM and are only snapshot/transmitted if the user
/// explicitly chooses "Include and continue" on the consent screen.
class BugReportLogService {
  BugReportLogService._internal();
  static final BugReportLogService instance = BugReportLogService._internal();

  static const int maxLogEntries = 120;
  static const int maxBreadcrumbEntries = 40;
  static const int _maxMetaDepth = 4;

  final ListQueue<BugLogEntry> _logs = ListQueue<BugLogEntry>(maxLogEntries);
  final ListQueue<BugLogEntry> _breadcrumbs =
      ListQueue<BugLogEntry>(maxBreadcrumbEntries);

  static final RegExp _bearerRegex = RegExp(
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );
  static final RegExp _jwtRegex = RegExp(
    r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
  );
  static final RegExp _basicAuthUrlRegex = RegExp(
    r'(https?://)([^:/@\s]+):([^/@\s]+)@',
    caseSensitive: false,
  );
  static final RegExp _kvSecretRegex = RegExp(
    r'\b(password|passwd|secret|token|otp|pin|cvv|api[_-]?key|authorization|cookie|session|jwt|csrf|signature)\b(\s*[:=]\s*)([^\s,;\[\]}]+)',
    caseSensitive: false,
  );
  static final RegExp _querySecretRegex = RegExp(
    r'([?&](?:token|access_token|refresh_token|api_key|apikey|secret|password|otp|code|auth|signature)=)([^&\s]+)',
    caseSensitive: false,
  );
  static final RegExp _sensitiveKeyRegex = RegExp(
    r'(password|passwd|secret|token|auth|cookie|session|otp|pin|cvv|card|credit|api[_-]?key|private[_-]?key|bearer|jwt|csrf|signature)',
    caseSensitive: false,
  );

  List<BugLogEntry> get logs => List.unmodifiable(_logs);
  List<BugLogEntry> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Strips secrets, credentials, and tokens from free-form diagnostic strings.
  static String sanitizeText(String input, {int maxLength = 400}) {
    if (input.isEmpty) return '';
    var sanitized = input
        .replaceAll(_bearerRegex, 'Bearer [REDACTED]')
        .replaceAll(_jwtRegex, '[REDACTED_JWT]')
        .replaceAllMapped(
          _basicAuthUrlRegex,
          (m) => '${m.group(1)}[REDACTED]:[REDACTED]@',
        )
        .replaceAllMapped(
          _querySecretRegex,
          (m) => '${m.group(1)}[REDACTED]',
        )
        .replaceAllMapped(
          _kvSecretRegex,
          (m) => '${m.group(1)}${m.group(2)}[REDACTED]',
        )
        .trim();

    if (sanitized.length > maxLength) {
      sanitized = '${sanitized.substring(0, maxLength)}...';
    }
    return sanitized;
  }

  /// Removes query strings and URL fragments so PII/tokens in URLs aren't kept.
  static String stripQueryString(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return '/';
    final qIdx = pathOrUrl.indexOf('?');
    final hIdx = pathOrUrl.indexOf('#');
    var cut = pathOrUrl.length;
    if (qIdx >= 0 && qIdx < cut) cut = qIdx;
    if (hIdx >= 0 && hIdx < cut) cut = hIdx;
    final clean = pathOrUrl.substring(0, cut).trim();
    return clean.isEmpty ? '/' : sanitizeText(clean, maxLength: 180);
  }

  /// Recursively redacts sensitive keys and truncates nested diagnostic maps.
  static Map<String, dynamic> sanitizeMap(
    Map<String, dynamic> input, {
    int depth = 0,
  }) {
    if (depth >= _maxMetaDepth) {
      return const {'_truncated': true};
    }
    final out = <String, dynamic>{};
    var count = 0;
    for (final entry in input.entries) {
      if (count >= 30) break;
      count++;
      final key = sanitizeText(entry.key, maxLength: 64);
      if (_sensitiveKeyRegex.hasMatch(key)) {
        out[key] = '[REDACTED]';
        continue;
      }
      out[key] = _sanitizeValue(entry.value, depth: depth + 1);
    }
    return out;
  }

  static dynamic _sanitizeValue(dynamic value, {required int depth}) {
    if (value == null || value is bool || value is num) {
      return value;
    }
    if (value is String) {
      return sanitizeText(value, maxLength: 250);
    }
    if (value is Map) {
      final casted = <String, dynamic>{};
      value.forEach((k, v) {
        casted['$k'] = v;
      });
      return sanitizeMap(casted, depth: depth);
    }
    if (value is Iterable) {
      if (depth >= _maxMetaDepth) return const ['[TRUNCATED]'];
      return value
          .take(20)
          .map((item) => _sanitizeValue(item, depth: depth + 1))
          .toList();
    }
    return sanitizeText(value.toString(), maxLength: 250);
  }

  void log(
    String message, {
    BugLogLevel level = BugLogLevel.info,
    String tag = 'app',
    Map<String, dynamic>? meta,
  }) {
    final entry = BugLogEntry(
      timestampUtc: DateTime.now().toUtc(),
      level: level,
      tag: sanitizeText(tag, maxLength: 40),
      message: sanitizeText(message),
      meta: meta == null ? null : sanitizeMap(meta),
    );
    _pushBounded(_logs, entry, maxLogEntries);
  }

  void recordNavigation(String action, String routeName) {
    final cleanRoute = stripQueryString(routeName);
    final entry = BugLogEntry(
      timestampUtc: DateTime.now().toUtc(),
      level: BugLogLevel.navigation,
      tag: 'nav',
      message: '$action -> $cleanRoute',
      meta: {'action': sanitizeText(action, maxLength: 24), 'route': cleanRoute},
    );
    _pushBounded(_breadcrumbs, entry, maxBreadcrumbEntries);
  }

  void recordApiError({
    required String method,
    required String path,
    int? statusCode,
    required String errorType,
  }) {
    final cleanPath = stripQueryString(path);
    final cleanMethod = sanitizeText(method.toUpperCase(), maxLength: 12);
    final cleanType = sanitizeText(errorType, maxLength: 40);
    final entry = BugLogEntry(
      timestampUtc: DateTime.now().toUtc(),
      level: BugLogLevel.network,
      tag: 'http',
      message: '$cleanMethod $cleanPath failed (${statusCode ?? cleanType})',
      meta: {
        'method': cleanMethod,
        'path': cleanPath,
        if (statusCode != null) 'status_code': statusCode,
        'error_type': cleanType,
      },
    );
    _pushBounded(_breadcrumbs, entry, maxBreadcrumbEntries);
    _pushBounded(_logs, entry, maxLogEntries);
  }

  void recordFlutterError(FlutterErrorDetails details) {
    final firstLine = details.exceptionAsString().split('\n').first;
    final stackTop = details.stack
            ?.toString()
            .split('\n')
            .take(4)
            .map((line) => sanitizeText(line, maxLength: 140))
            .toList() ??
        const <String>[];
    log(
      'FlutterError: $firstLine',
      level: BugLogLevel.error,
      tag: details.library ?? 'flutter',
      meta: {
        if (stackTop.isNotEmpty) 'stack_head': stackTop,
      },
    );
  }

  void recordPlatformError(Object error, StackTrace stack) {
    final stackTop = stack
        .toString()
        .split('\n')
        .take(4)
        .map((line) => sanitizeText(line, maxLength: 140))
        .toList();
    log(
      'UnhandledError: ${error.toString().split('\n').first}',
      level: BugLogLevel.error,
      tag: 'zone',
      meta: {
        if (stackTop.isNotEmpty) 'stack_head': stackTop,
      },
    );
  }

  /// Creates an immutable JSON-ready snapshot for bug report submission.
  Map<String, dynamic> snapshotDiagnostics() {
    return {
      'captured_at': DateTime.now().toUtc().toIso8601String(),
      'logs_count': _logs.length,
      'breadcrumbs_count': _breadcrumbs.length,
      'breadcrumbs': _breadcrumbs.map((e) => e.toJson()).toList(),
      'logs': _logs.map((e) => e.toJson()).toList(),
    };
  }

  void clear() {
    _logs.clear();
    _breadcrumbs.clear();
  }

  void _pushBounded(
    ListQueue<BugLogEntry> queue,
    BugLogEntry entry,
    int limit,
  ) {
    while (queue.length >= limit) {
      queue.removeFirst();
    }
    queue.addLast(entry);
  }
}
