import 'dart:async';

/// Global rate limiter enforcing OpenStreetMap Nominatim's strict usage policy:
/// Maximum 1 request per second across the entire application.
class NominatimRateLimiter {
  NominatimRateLimiter._();
  static final NominatimRateLimiter instance = NominatimRateLimiter._();

  DateTime? _lastExecutionTime;
  Future<void>? _activeQueue;
  static const Duration minInterval = Duration(milliseconds: 1050); // slight buffer over 1000ms

  /// Schedules [task] to run only after the mandatory 1-second delay from the previous request.
  Future<T> schedule<T>(Future<T> Function() task) {
    final completer = Completer<T>();

    // Chain the task onto the current queue to guarantee serial execution
    final previousQueue = _activeQueue ?? Future.value();
    _activeQueue = previousQueue.then((_) async {
      final now = DateTime.now();
      if (_lastExecutionTime != null) {
        final elapsed = now.difference(_lastExecutionTime!);
        if (elapsed < minInterval) {
          final waitDuration = minInterval - elapsed;
          await Future.delayed(waitDuration);
        }
      }

      try {
        final result = await task();
        _lastExecutionTime = DateTime.now();
        completer.complete(result);
      } catch (e, st) {
        _lastExecutionTime = DateTime.now();
        completer.completeError(e, st);
      }
    });

    return completer.future;
  }
}

