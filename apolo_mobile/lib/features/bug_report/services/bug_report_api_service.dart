import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/state/app_state.dart';
import '../../../l10n/l10n.dart';
import '../models/bug_report_models.dart';
import 'bug_report_log_service.dart';

/// Submits technical bug reports to Apolo.ma's self-hosted Laravel API.
class BugReportApiService {
  final Dio? _dioOverride;

  const BugReportApiService({Dio? dio}) : _dioOverride = dio;

  Dio get _dio => _dioOverride ?? AppState().api.dio;

  /// Resolves the canonical `POST /api/support/bug-reports` endpoint across
  /// production, staging, local dev, and Vercel proxy rewrites.
  static String resolveEndpoint(String baseUrl) {
    var normalized = baseUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isEmpty) {
      return '/api/support/bug-reports';
    }
    if (normalized.endsWith('/api/v1')) {
      final root = normalized.substring(0, normalized.length - '/api/v1'.length);
      return '$root/api/support/bug-reports';
    }
    if (normalized.endsWith('/api')) {
      return '$normalized/support/bug-reports';
    }
    if (normalized.endsWith('/apolo-staging-api')) {
      return '$normalized/support/bug-reports';
    }
    return '$normalized/api/support/bug-reports';
  }

  Future<BugReportResult> submitReport(BugReportSubmission submission) async {
    final trimmedDesc = submission.description.trim();
    if (trimmedDesc.length < 5) {
      throw BugReportApiException(
        message: appL10n.bugReportDescMinLengthError,
        statusCode: 422,
      );
    }

    // Hard privacy gate: NEVER attach optional diagnostics or detailed device
    // metadata unless the user explicitly opted in on Step 2.
    final Map<String, dynamic> deviceMeta = submission.includeLogs
        ? BugReportLogService.sanitizeMap(submission.context.toFullDeviceMeta())
        : submission.context.toBasicDeviceMeta();

    final Map<String, dynamic>? diagnostics =
        submission.includeLogs && submission.diagnosticsLogs != null
            ? BugReportLogService.sanitizeMap(submission.diagnosticsLogs!)
            : null;

    final effectiveBase = _dio.options.baseUrl.isNotEmpty
        ? _dio.options.baseUrl
        : AppConfig.effectiveBaseUrl;
    final endpoint = resolveEndpoint(effectiveBase);

    try {
      final dynamic requestBody;
      if (submission.screenshot != null) {
        final shot = submission.screenshot!;
        final fields = <String, dynamic>{
          'description': trimmedDesc,
          'include_logs': submission.includeLogs ? '1' : '0',
          'app_version': submission.context.appVersion,
          'platform': submission.context.platform,
          'locale': submission.context.locale,
          'route_name': submission.context.routeName,
          'device_meta': jsonEncode(deviceMeta),
          if (diagnostics != null) 'diagnostics_logs': jsonEncode(diagnostics),
          'screenshot': MultipartFile.fromBytes(
            shot.bytes,
            filename: shot.filename,
            contentType: DioMediaType.parse(shot.mimeType),
          ),
        };
        requestBody = FormData.fromMap(fields);
      } else {
        requestBody = <String, dynamic>{
          'description': trimmedDesc,
          'include_logs': submission.includeLogs,
          'app_version': submission.context.appVersion,
          'platform': submission.context.platform,
          'locale': submission.context.locale,
          'route_name': submission.context.routeName,
          'device_meta': deviceMeta,
          if (diagnostics != null) 'diagnostics_logs': diagnostics,
        };
      }

      final response = await _dio.post<dynamic>(
        endpoint,
        data: requestBody,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      if (data is Map) {
        return BugReportResult.fromJson(Map<String, dynamic>.from(data));
      }
      return const BugReportResult(id: 0, status: 'open');
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      throw BugReportApiException(message: e.toString());
    }
  }

  BugReportApiException _mapDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    int? retryAfter;
    final retryHeader = e.response?.headers.value('retry-after');
    if (retryHeader != null) {
      retryAfter = int.tryParse(retryHeader.trim());
    }

    String message = appL10n.bugReportNetworkFailedError;
    Map<String, List<String>>? validationErrors;

    if (data is Map) {
      final serverMessage = data['message']?.toString().trim();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        message = serverMessage;
      }
      if (data['errors'] is Map) {
        validationErrors = <String, List<String>>{};
        (data['errors'] as Map).forEach((k, v) {
          if (v is List) {
            validationErrors!['$k'] = v.map((item) => '$item').toList();
          } else if (v != null) {
            validationErrors!['$k'] = ['$v'];
          }
        });
        if (validationErrors.isNotEmpty &&
            validationErrors.values.first.isNotEmpty) {
          message = validationErrors.values.first.first;
        }
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = appL10n.bugReportTimeoutError;
    } else if (e.type == DioExceptionType.connectionError) {
      message = appL10n.bugReportServerUnreachableError;
    }

    return BugReportApiException(
      message: message,
      statusCode: status,
      retryAfterSeconds: retryAfter,
      validationErrors: validationErrors,
    );
  }
}
