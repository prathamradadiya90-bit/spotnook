import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/discovery/domain/entities/place.dart';
import '../utils/formatters.dart';

/// Service facilitating native external interactions:
/// Turn-by-turn navigation, system phone dialer, external browser, and system share dialog.
class NavigationService {
  const NavigationService();

  /// Launches external navigation apps (Google Maps, Waze, etc.) to navigate to a place.
  Future<bool> launchDirections({
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    // On Web, geo: URIs are unsupported by browsers; directly launch Google Maps web directions.
    if (kIsWeb) {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
      return false;
    }

    final encodedName = Uri.encodeComponent(placeName ?? 'Destination');
    // Primary Android / Mobile geo: URI intent
    final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($encodedName)');

    if (await canLaunchUrl(geoUri)) {
      return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }

    // Fallback: Google Maps web URL
    if (await canLaunchUrl(googleMapsUrl)) {
      return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Opens the phone dialer safely without requiring CALL_PHONE runtime permission.
  Future<bool> launchDialer(String rawPhone) async {
    if (!Formatters.isValidPhoneNumber(rawPhone)) return false;
    final cleanPhone = Formatters.cleanPhoneNumber(rawPhone);

    final telUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(telUri)) {
      return await launchUrl(telUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens an external website URL securely (strictly HTTP/HTTPS only).
  Future<bool> launchWebsite(String rawUrl) async {
    final sanitized = Formatters.sanitizeHttpUrl(rawUrl);
    if (sanitized == null) return false;

    final uri = Uri.parse(sanitized);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Shares a place with a beautifully formatted message and map link.
  /// [sharePositionOrigin] provides bounding coordinates for iPad and Web popover dialogs.
  Future<void> sharePlace(Place place, {Rect? sharePositionOrigin}) async {
    final buffer = StringBuffer();
    buffer.writeln('📍 Discover ${place.name} on Spotnook!');
    buffer.writeln('Category: ${place.category.name}');
    if (place.formattedAddress.isNotEmpty) {
      buffer.writeln('Address: ${place.formattedAddress}');
    }
    if (place.rating != null) {
      buffer.writeln('Rating: ★ ${place.rating!.toStringAsFixed(1)}');
    }
    buffer.writeln('Map Location: https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}');

    await Share.share(
      buffer.toString(),
      subject: 'Explore ${place.name}',
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

