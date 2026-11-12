import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_constants.dart';
import 'dio_retry_interceptor.dart';
import 'network_exceptions.dart';

/// Pre-configured, hardened Dio HTTP client for external API communication.
/// Security features:
/// - Enforces HTTPS scheme only (disallows insecure HTTP).
/// - Enforces 5MB response size limit to prevent memory exhaustion / DoS attacks.
/// - Automatically redacts API keys and sensitive tokens from logs.
/// - Exponential backoff retry interceptor for transient faults.
class DioClient {
  late final Dio dio;

  /// Max allowable response size: 5 Megabytes
  static const int maxResponseSizeBytes = 5 * 1024 * 1024;

  DioClient() {
    dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          if (!kIsWeb) 'User-Agent': ApiConstants.appUserAgent,
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Security & HTTPS Enforcement Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          // HTTPS Only Enforcement (allow loopback for local development/testing)
          final uri = options.uri;
          final isLoopback = uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
          if (uri.hasScheme && uri.scheme.toLowerCase() != 'https' && !isLoopback) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: const SecurityException('Insecure HTTP disallowed. All requests must use HTTPS.'),
                type: DioExceptionType.unknown,
              ),
            );
          }

          // Redact keys in debug logs
          if (kDebugMode) {
            final sanitizedUrl = redactSensitiveUrl(options.uri.toString());
            debugPrint('[HTTP Request] ${options.method} $sanitizedUrl');
          }

          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          // Response size validation
          final contentLength = response.headers.value(Headers.contentLengthHeader);
          if (contentLength != null) {
            final length = int.tryParse(contentLength) ?? 0;
            if (length > maxResponseSizeBytes) {
              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  error: const ServerException('Response size exceeded safe limit (5MB).', 413),
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          }

          // In-memory data size check
          final data = response.data;
          if (data is String && data.length > maxResponseSizeBytes) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                error: const ServerException('Response body exceeded safe limit (5MB).', 413),
                type: DioExceptionType.badResponse,
              ),
            );
          }

          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          final mappedException = _mapDioError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mappedException,
            ),
          );
        },
      ),
    );

    // 2. Exponential Backoff Retry Interceptor
    dio.interceptors.add(DioRetryInterceptor(dio: dio));
  }

  /// Sanitizes sensitive parameters (e.g. key=AIzaSy...) from URL strings for logging.
  static String redactSensitiveUrl(String rawUrl) {
    return rawUrl.replaceAllMapped(
      RegExp(r'([?&](?:key|api_key|token|access_token)=)[^&]+', caseSensitive: false),
      (match) => '${match.group(1)}[REDACTED]',
    );
  }

  static AppException _mapDioError(DioException error) {
    if (error.error is AppException) {
      return error.error as AppException;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 429) {
          return const RateLimitException();
        } else if (status == 401 || status == 403) {
          return UnauthorizedException('Access denied ($status). Check API permissions.', status);
        } else if (status == 404) {
          return const NotFoundException();
        } else if (status != null && status >= 500) {
          return ServerException('Server error ($status). Please try again.', status);
        }
        return ServerException('Request failed with status $status.', status);
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled.');
      default:
        return NetworkException(error.message ?? 'An unexpected network error occurred.');
    }
  }
}
