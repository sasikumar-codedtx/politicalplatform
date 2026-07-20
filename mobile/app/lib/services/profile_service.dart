import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'agent_service.dart';

/// User profile, backed by the server and keyed to the logged-in Firebase
/// user. The same login shows the same photo/name/city on every device.
///
/// Exposed as ValueNotifiers so the avatar/name update live everywhere
/// (profile page, chat header, member ID, bottom-nav icon). On logout the
/// data is cleared so nothing leaks to the next user on the same phone.
class ProfileService {
  static const _defaultCity = 'Chennai, Tamil Nadu.';

  static final ValueNotifier<String?> avatar = ValueNotifier<String?>(null);
  static final ValueNotifier<String> displayName = ValueNotifier<String>('Member');
  static final ValueNotifier<String> city = ValueNotifier<String>(_defaultCity);

  static bool _wired = false;
  static String? _uid;

  /// Call once at app start. Subscribes to auth changes: loads the profile on
  /// login, clears it on logout.
  static void init() {
    if (_wired) return;
    _wired = true;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _clear();
      } else if (user.uid != _uid) {
        load();
      }
    });
    // Cover the already-logged-in-at-launch case.
    if (FirebaseAuth.instance.currentUser != null) load();
  }

  /// Refresh the current user's profile from the server. No-op (clears) when
  /// logged out.
  static Future<void> load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _clear();
      return;
    }
    _uid = user.uid;
    final uid = user.uid;

    // Fetch profile + avatar concurrently instead of one-then-the-other.
    final profileF = AgentService.getProfile();
    final avatarF = AgentService.downloadAvatar();
    final profile = await profileF;
    final bytes = await avatarF;
    if (_uid != uid) return; // superseded by a newer login/logout
    if (profile != null) {
      final name = (profile['name'] as String? ?? '').trim();
      final c = (profile['city'] as String? ?? '').trim();
      displayName.value = name.isNotEmpty ? name : 'Member';
      city.value = c.isNotEmpty ? c : _defaultCity;
    }
    avatar.value = bytes != null ? await _writeAvatar(uid, bytes) : null;
  }

  static Future<void> saveAvatar(File src) async {
    final uid = _uid;
    if (uid == null) return;
    final ok = await AgentService.uploadAvatar(src);
    if (!ok) return;
    avatar.value = await _writeAvatar(uid, await src.readAsBytes());
  }

  static bool get _loggedIn => FirebaseAuth.instance.currentUser != null;

  static Future<bool> saveName(String value) async {
    final v = value.trim();
    if (v.isEmpty || !_loggedIn) return false;
    final prev = displayName.value;
    displayName.value = v; // optimistic — UI updates instantly
    final ok = await AgentService.updateProfile(name: v);
    if (!ok) displayName.value = prev; // revert if the server rejected
    return ok;
  }

  static Future<bool> saveCity(String value) async {
    final v = value.trim();
    if (v.isEmpty || !_loggedIn) return false;
    final prev = city.value;
    city.value = v; // optimistic
    final ok = await AgentService.updateProfile(city: v);
    if (!ok) city.value = prev;
    return ok;
  }

  static void _clear() {
    _uid = null;
    avatar.value = null;
    displayName.value = 'Member';
    city.value = _defaultCity;
  }

  // Write avatar bytes to a per-user file with a fresh name each time so the
  // image cache never serves a stale copy (FileImage is keyed on path).
  static String? _lastAvatarPath;
  static Future<String> _writeAvatar(String uid, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeUid = uid.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final dest = File('${dir.path}/pfp_${safeUid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await dest.writeAsBytes(bytes, flush: true);
    final old = _lastAvatarPath;
    _lastAvatarPath = dest.path;
    if (old != null && old != dest.path) {
      try { await File(old).delete(); } catch (_) {}
    }
    return dest.path;
  }
}
