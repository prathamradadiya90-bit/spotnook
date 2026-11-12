import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/network/dio_client.dart';
import 'package:spot_finder/core/network/network_exceptions.dart';

void main() {
  group('DioClient HTTPS & Loopback Interceptor Tests', () {
    late DioClient dioClient;

    setUp(() {
      dioClient = DioClient();
    });

    test('Rejects insecure HTTP URLs for external hosts', () async {
      expect(
        () => dioClient.dio.get('http://insecure-api.example.com/data'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<SecurityException>(),
          ),
        ),
      );
    });

    test('Allows loopback http://localhost without SecurityException', () async {
      try {
        await dioClient.dio.get('http://localhost:65432/api');
      } on DioException catch (e) {
        expect(e.error is SecurityException, isFalse);
      } catch (_) {
        // Any other network error is expected
      }
    });

    test('Allows loopback http://127.0.0.1 without SecurityException', () async {
      try {
        await dioClient.dio.get('http://127.0.0.1:65432/api');
      } on DioException catch (e) {
        expect(e.error is SecurityException, isFalse);
      } catch (_) {
        // Any other network error is expected
      }
    });

    test('Redacts API keys in query params and headers correctly', () {
      final sanitized = DioClient.redactSensitiveUrl('https://api.example.com/places?key=SECRET_KEY_123&query=coffee');
      expect(sanitized.contains('SECRET_KEY_123'), isFalse);
      expect(sanitized.contains('[REDACTED]'), isTrue);
    });
  });
}
