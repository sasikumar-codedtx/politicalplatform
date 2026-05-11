import 'package:shared_preferences/shared_preferences.dart';

/// Stores per-video likes locally. No Google login required.
class VideoLikeService {
  static const _prefix = 'video_like_';

  static Future<bool> isLiked(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$videoId') ?? false;
  }

  static Future<bool> toggleLike(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool('$_prefix$videoId') ?? false;
    final next = !current;
    await prefs.setBool('$_prefix$videoId', next);
    return next;
  }
}
