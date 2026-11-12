import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/errors/failure.dart';
import 'package:spot_finder/core/errors/result.dart';

void main() {
  group('Result<T, Failure> Tests', () {
    test('Success result folds correctly and exposes data', () {
      final Result<String, Failure> result = Result.ok('Hello World');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals('Hello World'));
      expect(result.errorOrNull, isNull);

      final folded = result.fold(
        onSuccess: (data) => 'Got: $data',
        onFailure: (err) => 'Failed: ${err.message}',
      );
      expect(folded, equals('Got: Hello World'));
    });

    test('Failure result folds correctly and exposes failure error', () {
      final Result<String, Failure> result = Result.err(const NetworkFailure('Network down'));

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, isA<NetworkFailure>());
      expect(result.errorOrNull?.message, equals('Network down'));

      final folded = result.fold(
        onSuccess: (data) => 'Got: $data',
        onFailure: (err) => 'Failed: ${err.message}',
      );
      expect(folded, equals('Failed: Network down'));
    });
  });
}

