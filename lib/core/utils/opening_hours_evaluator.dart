/// Utility parsing and computing live open/closed status from OpenStreetMap `opening_hours` tags.
class OpeningHoursEvaluator {
  OpeningHoursEvaluator._();

  static const List<String> dayNames = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  /// Computes whether a venue is currently open based on its OSM opening hours string.
  /// Returns `true` if open, `false` if closed, or `null` if unspecified or unparseable.
  static bool? computeIsOpenNow(String? rawHours, {DateTime? customNow}) {
    if (rawHours == null || rawHours.trim().isEmpty) return null;
    final normalized = rawHours.trim().toLowerCase();

    // Special cases
    if (normalized == '24/7') return true;
    if (normalized == 'closed' || normalized == 'off') return false;

    final now = customNow ?? DateTime.now();
    final todayDayIdx = now.weekday - 1; // 0 = Mo, 6 = Su
    final currentMinutes = now.hour * 60 + now.minute;

    final clauses = rawHours.split(RegExp(r'[;,]'));

    for (final clause in clauses) {
      final trimmedClause = clause.trim();
      if (trimmedClause.isEmpty) continue;

      if (_clauseAppliesToDay(trimmedClause, todayDayIdx)) {
        if (trimmedClause.toLowerCase().contains('off') || trimmedClause.toLowerCase().contains('closed')) {
          return false;
        }

        final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})').firstMatch(trimmedClause);
        if (timeMatch != null) {
          final startH = int.parse(timeMatch.group(1)!);
          final startM = int.parse(timeMatch.group(2)!);
          final endH = int.parse(timeMatch.group(3)!);
          final endM = int.parse(timeMatch.group(4)!);

          final startMinutes = startH * 60 + startM;
          var endMinutes = endH * 60 + endM;
          // Handle midnight crossing like 18:00-02:00
          if (endMinutes < startMinutes) {
            endMinutes += 24 * 60;
            final effectiveCurrent = currentMinutes < startMinutes ? currentMinutes + 24 * 60 : currentMinutes;
            return effectiveCurrent >= startMinutes && effectiveCurrent <= endMinutes;
          }

          return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
        }
      }
    }

    // Default time range check if no day is specified (e.g. "09:00-21:00")
    final simpleTimeMatch = RegExp(r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$').firstMatch(rawHours.trim());
    if (simpleTimeMatch != null) {
      final startH = int.parse(simpleTimeMatch.group(1)!);
      final startM = int.parse(simpleTimeMatch.group(2)!);
      final endH = int.parse(simpleTimeMatch.group(3)!);
      final endM = int.parse(simpleTimeMatch.group(4)!);
      final startMinutes = startH * 60 + startM;
      final endMinutes = endH * 60 + endM;
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }

    return null;
  }

  static bool _clauseAppliesToDay(String clause, int todayIdx) {
    // If clause contains no day keywords, assume it applies to all days
    final containsAnyDay = dayNames.any((d) => clause.contains(d));
    if (!containsAnyDay) return true;

    // Range like "Mo-Fr"
    final rangeMatch = RegExp(r'(Mo|Tu|We|Th|Fr|Sa|Su)\s*-\s*(Mo|Tu|We|Th|Fr|Sa|Su)').firstMatch(clause);
    if (rangeMatch != null) {
      final startDay = rangeMatch.group(1)!;
      final endDay = rangeMatch.group(2)!;
      final startIdx = dayNames.indexOf(startDay);
      final endIdx = dayNames.indexOf(endDay);

      if (startIdx <= endIdx) {
        if (todayIdx >= startIdx && todayIdx <= endIdx) return true;
      } else {
        // Wraps over Sunday like Sa-Tu
        if (todayIdx >= startIdx || todayIdx <= endIdx) return true;
      }
    }

    // Specific day like "Sa"
    final todayName = dayNames[todayIdx];
    return clause.contains(todayName);
  }
}

