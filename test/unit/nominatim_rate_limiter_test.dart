import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/network/nominatim_rate_limiter.dart';

void main() {
  test('NominatimRateLimiter throttles rapid requests by at least 1 second', () async {
    final limiter = NominatimRateLimiter.instance;
    final timestamps = <DateTime>[];

    await Future.wait([
      limiter.schedule(() async {
        timestamps.add(DateTime.now());
        return 1;
      }),
      limiter.schedule(() async {
        timestamps.add(DateTime.now());
        return 2;
      }),
    ]);

    expect(timestamps.length, equals(2));
    final diff = timestamps[1].difference(timestamps[0]).inMilliseconds;
    expect(diff, greaterThanOrEqualTo(1000));
  });
}

