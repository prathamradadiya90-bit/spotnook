import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio Interceptor providing exponential backoff retries for transient network/server failures.
class DioRetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;

  DioRetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final retries = (requestOptions.extra['retry_count'] as int? ?? 0);

    final shouldRetry = _isRetryable(err) && retries < maxRetries;

    if (shouldRetry) {
      final nextRetry = retries + 1;
      requestOptions.extra['retry_count'] = nextRetry;

      // Exponential backoff: 500ms, 1000ms, 2000ms (+ minor jitter)
      final backoff = (initialDelay.inMilliseconds * pow(2, retries)).toInt();
      final jitter = Random().nextInt(150);
      final delay = Duration(milliseconds: backoff + jitter);

      if (kDebugMode) {
        debugPrint('[DioRetry] Retrying request (attempt $nextRetry/$maxRetries) in ${delay.inMilliseconds}ms: ${requestOptions.path}');
      }

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        return super.onError(retryErr, handler);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _isRetryable(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    if (error.type == DioExceptionType.badResponse) {
      final status = error.response?.statusCode;
      // Retry transient server faults (Bad Gateway, Service Unavailable, Gateway Timeout)
      return status == 502 || status == 503 || status == 504;
    }

    return false;
  }
}

