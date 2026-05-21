import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// One persistent device-id per install (random UUID, never changes).
/// Combined with the Firebase uid (or "anon"), this yields a stable
/// session id that is unique to this device + this user — no two devices
/// ever share a session id, and re-installing the app gives a fresh one.
class DeviceSession {
  static const _kDeviceIdKey = 'device_id_v1';
  static const _kSessionIdPrefix = 'current_session_v1';

  static String? _cachedDeviceId;

  static Future<String> deviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kDeviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4().replaceAll('-', '');
      await prefs.setString(_kDeviceIdKey, id);
    }
    _cachedDeviceId = id;
    return id;
  }

  static String _ownerKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null || uid.isEmpty ? 'anon' : uid;
  }

  /// Sticky session ID — one per (device, user) combination. Reused across
  /// app launches so history shows up. Call [rotate] for a fresh chat.
  static Future<String> sessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_kSessionIdPrefix}_${_ownerKey()}';
    var id = prefs.getString(key);
    if (id == null || id.isEmpty) {
      id = await _mintSessionId();
      await prefs.setString(key, id);
    }
    return id;
  }

  static Future<String> rotate() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_kSessionIdPrefix}_${_ownerKey()}';
    final id = await _mintSessionId();
    await prefs.setString(key, id);
    return id;
  }

  static Future<String> _mintSessionId() async {
    final dev = await deviceId();
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = const Uuid().v4().replaceAll('-', '').substring(0, 8);
    return 's_${dev.substring(0, 8)}_${ts}_$rand';
  }
}
