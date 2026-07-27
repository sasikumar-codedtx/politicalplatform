import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Small disk cache for list responses.
///
/// Screens read the cached copy first so they paint immediately after a cold
/// start, then a background refresh replaces it for next time. Nothing here
/// blocks the UI on the network.
class LocalCache {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _p() async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Cached value, or null when nothing is stored (or [maxAge] has passed).
  static Future<dynamic> read(String key, {Duration? maxAge}) async {
    final raw = (await _p()).getString('cache_$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (maxAge != null) {
        final at = DateTime.fromMillisecondsSinceEpoch(map['t'] as int);
        if (DateTime.now().difference(at) > maxAge) return null;
      }
      return map['v'];
    } catch (_) {
      return null;
    }
  }

  /// Cached value plus when it was written, so callers can decide whether a
  /// refresh is worth a network call. Null when nothing is stored.
  static Future<({dynamic value, DateTime at})?> readEntry(String key) async {
    final raw = (await _p()).getString('cache_$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        value: map['v'],
        at: DateTime.fromMillisecondsSinceEpoch(map['t'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String key, Object? value) async {
    if (value == null) return;
    await (await _p()).setString(
      'cache_$key',
      jsonEncode({'t': DateTime.now().millisecondsSinceEpoch, 'v': value}),
    );
  }

  static Future<void> invalidate(String key) async =>
      (await _p()).remove('cache_$key');
}
