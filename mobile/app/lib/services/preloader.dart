import 'content_service.dart';
import 'fan_post_service.dart';
import 'youtube_service.dart';

/// Warms the caches the first screens need, in parallel, at app start (while
/// the splash video plays). Every call is cache-first and swallows its own
/// errors, so this only ever makes the app faster — it never blocks startup or
/// throws. When a screen opens, its data is already in LocalCache / memo.
class Preloader {
  static bool _done = false;

  static void warm() {
    if (_done) return;
    _done = true;
    // Fire them all; don't await — startup must not wait on the network.
    ContentService.getNews();
    ContentService.getEvents();
    FanPostService.getApprovedPosts();
    YouTubeService.getVideos(count: 20);
    YouTubeService.getShorts(count: 10);
    YouTubeService.getLiveStream();
  }
}
