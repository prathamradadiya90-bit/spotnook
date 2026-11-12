import 'package:flutter_test/flutter_test.dart';
import 'package:spot_finder/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('Clean phone numbers removes dashes, spaces, and parentheses', () {
      expect(Formatters.cleanPhoneNumber('+1 (555) 234-5678'), equals('+15552345678'));
      expect(Formatters.cleanPhoneNumber('0261-223344'), equals('0261223344'));
      expect(Formatters.cleanPhoneNumber(''), equals(''));
    });

    test('Truncates long text with ellipsis', () {
      expect(Formatters.truncate('Hello World', 5), equals('Hello...'));
      expect(Formatters.truncate('Short', 10), equals('Short'));
    });

    test('Formats price levels into dollar signs', () {
      expect(Formatters.formatPriceLevel(1), equals('\$'));
      expect(Formatters.formatPriceLevel(2), equals('\$\$'));
      expect(Formatters.formatPriceLevel(3), equals('\$\$\$'));
      expect(Formatters.formatPriceLevel(4), equals('\$\$\$\$'));
      expect(Formatters.formatPriceLevel(null), equals(''));
      expect(Formatters.formatPriceLevel(0), equals(''));
    });

    test('Validates phone numbers strictly with ITU E.164 rules', () {
      expect(Formatters.isValidPhoneNumber('+15552345678'), isTrue);
      expect(Formatters.isValidPhoneNumber('9876543210'), isTrue);
      expect(Formatters.isValidPhoneNumber('12'), isFalse); // too short
      expect(Formatters.isValidPhoneNumber('invalid-phone'), isFalse);
      expect(Formatters.isValidPhoneNumber(''), isFalse);
    });

    test('Sanitizes HTTP/HTTPS URLs and rejects unsafe schemes', () {
      expect(Formatters.sanitizeHttpUrl('https://example.com'), equals('https://example.com'));
      expect(Formatters.sanitizeHttpUrl('example.com/about'), equals('https://example.com/about'));
      expect(Formatters.sanitizeHttpUrl('http://insecure.org'), equals('http://insecure.org'));
      expect(Formatters.sanitizeHttpUrl('javascript:alert(1)'), isNull);
      expect(Formatters.sanitizeHttpUrl('file:///etc/passwd'), isNull);
      expect(Formatters.sanitizeHttpUrl(''), isNull);
    });

    test('Sanitizes text tags from external sources stripping HTML and control chars', () {
      expect(Formatters.sanitizeText('<b>Cafe</b><script>alert(1)</script>'), equals('Cafealert(1)'));
      expect(Formatters.sanitizeText('Fresh\x00 Coffee'), equals('Fresh Coffee'));
    });
  });
}

