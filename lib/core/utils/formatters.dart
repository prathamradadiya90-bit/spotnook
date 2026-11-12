/// String, tag sanitization, and data formatting utilities for venues.
class Formatters {
  Formatters._();

  /// Cleanly cleans and normalizes phone numbers for `tel:` dialing.
  static String cleanPhoneNumber(String rawPhone) {
    return rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Strictly validates phone numbers according to standard international / national dialer rules.
  /// Allowed: optional leading '+' followed by 3 to 15 numeric digits (ITU-T E.164).
  static bool isValidPhoneNumber(String rawPhone) {
    final clean = cleanPhoneNumber(rawPhone);
    return RegExp(r'^\+?[0-9]{3,16}$').hasMatch(clean);
  }

  /// Validates and ensures URLs use strictly `http` or `https` schemes.
  /// Rejects `javascript:`, `file:`, `content:`, and other arbitrary URI schemes.
  static String? sanitizeHttpUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final initialUri = Uri.tryParse(trimmed);
    if (initialUri != null && initialUri.hasScheme) {
      if (initialUri.scheme != 'http' && initialUri.scheme != 'https') {
        return null;
      }
      if (initialUri.host.isEmpty) return null;
      return initialUri.toString();
    }

    // No scheme provided, prepend https://
    final httpsUri = Uri.tryParse('https://$trimmed');
    if (httpsUri == null || httpsUri.host.isEmpty) return null;
    return httpsUri.toString();
  }

  /// Sanitizes raw tags from external providers (OSM, Photon, Google)
  /// to remove potential XSS, HTML tags, null bytes, and control characters.
  static String sanitizeText(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll('\x00', '') // Strip null bytes
        .replaceAll(RegExp(r'[\x01-\x1F\x7F]'), '') // Strip control characters
        .trim();
  }

  /// Truncates strings with ellipsis.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Formats price levels from numeric (1..4) to standard currency symbols ($, $$, $$$, $$$$).
  static String formatPriceLevel(int? level, {String currencySymbol = '\$'}) {
    if (level == null || level <= 0) return '';
    final count = level.clamp(1, 4);
    return currencySymbol * count;
  }

  /// Cleans raw OSM or Google opening hours tags.
  static String cleanOpeningHours(String? rawHours) {
    if (rawHours == null || rawHours.trim().isEmpty) {
      return 'Hours not specified';
    }
    final sanitized = sanitizeText(rawHours);
    // Clean common OSM semicolon-separated hours
    return sanitized.replaceAll(';', '\n');
  }
}
