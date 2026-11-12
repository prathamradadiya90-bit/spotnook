import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// User-submitted rating record.
class UserRatingRecord {
  final String placeId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const UserRatingRecord({
    required this.placeId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserRatingRecord.fromJson(Map<String, dynamic> json) => UserRatingRecord(
        placeId: json['placeId'] as String,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// State notifier managing user-submitted venue ratings.
class UserRatingsNotifier extends StateNotifier<Map<String, UserRatingRecord>> {
  final SharedPreferences _prefs;
  static const String _storageKey = 'spot_finder_user_ratings_v1';

  UserRatingsNotifier(this._prefs) : super({}) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    try {
      final raw = _prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final map = <String, UserRatingRecord>{};
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            map[entry.key] = UserRatingRecord.fromJson(entry.value as Map<String, dynamic>);
          }
        }
        state = map;
      }
    } catch (_) {
      state = {};
    }
  }

  Future<void> _saveToStorage() async {
    final serialized = <String, dynamic>{};
    for (final entry in state.entries) {
      serialized[entry.key] = entry.value.toJson();
    }
    await _prefs.setString(_storageKey, jsonEncode(serialized));
  }

  /// Submits or updates rating for a venue.
  Future<void> submitRating({
    required String placeId,
    required double rating,
    String? comment,
  }) async {
    final record = UserRatingRecord(
      placeId: placeId,
      rating: rating,
      comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
      createdAt: DateTime.now(),
    );

    state = {
      ...state,
      placeId: record,
    };

    await _saveToStorage();
  }

  /// Removes rating for a venue.
  Future<void> removeRating(String placeId) async {
    if (!state.containsKey(placeId)) return;
    final updated = Map<String, UserRatingRecord>.from(state)..remove(placeId);
    state = updated;
    await _saveToStorage();
  }

  /// Completely clears all user ratings from state and persistent storage.
  Future<void> clearAll() async {
    state = {};
    await _prefs.remove(_storageKey);
  }
}

/// Provider exposing user ratings map keyed by placeId.
final userRatingsProvider = StateNotifierProvider<UserRatingsNotifier, Map<String, UserRatingRecord>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserRatingsNotifier(prefs);
});

