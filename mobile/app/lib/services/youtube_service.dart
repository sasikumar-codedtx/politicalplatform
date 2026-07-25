import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secrets.dart';
import '../models/youtube_video.dart';
import '../models/youtube_playlist.dart';
import 'local_cache.dart';

class _CacheEntry {
  final dynamic value;
  final DateTime at;
  const _CacheEntry(this.value, this.at);
}

class YouTubeService {
  static const _base = 'https://www.googleapis.com/youtube/v3';

  // Every `search` call costs 100 quota units, and the app asks for the same
  // data from several places (Home live card + Home view model, shorts on Home
  // and again in the hub). These short-lived memos collapse those into one
  // real request; live status still refreshes every minute.
  static const _liveTtl = Duration(seconds: 60);
  static const _listTtl = Duration(minutes: 5);
  // How stale the on-disk copy may get before a background refresh is worth a
  // quota unit. Uploads change a few times a day at most.
  static const _diskTtl = Duration(hours: 3);
  static final Map<String, _CacheEntry> _memo = {};

  static Future<T> _cached<T>(
    String key,
    Duration ttl,
    Future<T> Function() fetch,
  ) async {
    final hit = _memo[key];
    if (hit != null && DateTime.now().difference(hit.at) < ttl) {
      return hit.value as T;
    }
    final value = await fetch();
    _memo[key] = _CacheEntry(value, DateTime.now());
    return value;
  }

  /// Video lists, served from disk instantly on a cold start and refreshed in
  /// the background. A first run (nothing cached) still waits for the network.
  static Future<List<YouTubeVideo>> _cachedList(
    String key,
    Future<List<YouTubeVideo>> Function() fetch,
  ) async {
    final hit = _memo[key];
    if (hit != null && DateTime.now().difference(hit.at) < _listTtl) {
      return hit.value as List<YouTubeVideo>;
    }

    final stored = await LocalCache.readEntry('yt_$key');
    final value = stored?.value;
    if (value is List && value.isNotEmpty) {
      final videos = value
          .map((e) => YouTubeVideo.fromJson(e as Map<String, dynamic>))
          .toList();
      _memo[key] = _CacheEntry(videos, DateTime.now());
      // Only spend quota when the stored copy is actually old. A failed
      // refresh (429, offline) leaves the cached list in place.
      if (DateTime.now().difference(stored!.at) > _diskTtl) {
        unawaited(_refreshList(key, fetch));
      }
      return videos;
    }

    final fresh = await fetch();
    // An empty result means the call failed (quota, offline) — don't cache it
    // or the tab stays blank for the whole TTL.
    if (fresh.isNotEmpty) _store(key, fresh);
    return fresh;
  }

  static Future<void> _refreshList(
    String key,
    Future<List<YouTubeVideo>> Function() fetch,
  ) async {
    final fresh = await fetch();
    if (fresh.isNotEmpty) _store(key, fresh);
  }

  static void _store(String key, List<YouTubeVideo> videos) {
    _memo[key] = _CacheEntry(videos, DateTime.now());
    unawaited(
        LocalCache.write('yt_$key', videos.map((v) => v.toJson()).toList()));
  }

  /// Drops every memo (including the resolved channel id) — call after
  /// changing the configured channel handle.
  static Future<void> clearCache() async {
    _memo.clear();
    _channelId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_channelIdKey);
  }

  // Cached channel ID resolved from the handle. Persisted so a restart does
  // not pay the lookup again. The key includes the handle, so pointing the app
  // at a different channel never reuses the previous channel's id.
  static String? _channelId;
  static String get _channelIdKey =>
      'yt_channel_id_${Secrets.youtubeChannelHandle}';

  static Future<String?> _getChannelId() async {
    if (_channelId != null) return _channelId;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_channelIdKey);
    if (saved != null && saved.isNotEmpty) {
      _channelId = saved;
      return _channelId;
    }
    try {
      final handle = Secrets.youtubeChannelHandle;
      final uri = Uri.parse(
        '$_base/channels?part=id'
        '&forHandle=@$handle'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        // ignore: avoid_print
        print('[YouTube] _getChannelId ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) {
        // ignore: avoid_print
        print('[YouTube] _getChannelId: no channel found for handle @$handle');
        return null;
      }
      _channelId = (items.first as Map<String, dynamic>)['id'] as String;
      await prefs.setString(_channelIdKey, _channelId!);
      // ignore: avoid_print
      print('[YouTube] resolved channel ID: $_channelId');
      return _channelId;
    } catch (e) {
      // ignore: avoid_print
      print('[YouTube] _getChannelId error: $e');
      return null;
    }
  }

  // Everything below reads the channel's "uploads" playlist instead of the
  // search endpoint. search.list costs 100 quota units per call (10,000/day),
  // which the app burned through in normal use and then got 429s — empty
  // Videos/Shorts/Live tabs. playlistItems + videos cost 1 unit each.

  static String? _uploadsId;
  static String get _uploadsKey =>
      'yt_uploads_${Secrets.youtubeChannelHandle}';

  static Future<String?> _getUploadsPlaylistId() async {
    if (_uploadsId != null) return _uploadsId;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_uploadsKey);
    if (saved != null && saved.isNotEmpty) return _uploadsId = saved;
    try {
      final uri = Uri.parse(
        '$_base/channels?part=contentDetails'
        '&forHandle=@${Secrets.youtubeChannelHandle}'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final items = (jsonDecode(res.body) as Map<String, dynamic>)['items']
          as List<dynamic>? ?? [];
      if (items.isEmpty) return null;
      final id = (((items.first as Map<String, dynamic>)['contentDetails']
              as Map<String, dynamic>)['relatedPlaylists']
          as Map<String, dynamic>)['uploads'] as String?;
      if (id == null || id.isEmpty) return null;
      await prefs.setString(_uploadsKey, id);
      return _uploadsId = id;
    } catch (_) {
      return null;
    }
  }

  /// Newest uploads, newest first. Live streams appear here too.
  static Future<List<YouTubeVideo>> _fetchUploads(int count) async {
    final playlistId = await _getUploadsPlaylistId();
    if (playlistId == null) return [];
    return getPlaylistVideos(playlistId, maxResults: count);
  }

  /// contentDetails + snippet for the given ids (1 quota unit).
  static Future<Map<String, Map<String, dynamic>>> _videoDetails(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final uri = Uri.parse(
        '$_base/videos?part=contentDetails,snippet'
        '&id=${ids.take(50).join(",")}'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return {};
      final items = (jsonDecode(res.body) as Map<String, dynamic>)['items']
          as List<dynamic>? ?? [];
      return {
        for (final e in items.cast<Map<String, dynamic>>())
          e['id'] as String: e,
      };
    } catch (_) {
      return {};
    }
  }

  static int _durationSeconds(String iso) {
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(iso);
    if (m == null) return 0;
    return int.parse(m.group(1) ?? '0') * 3600 +
        int.parse(m.group(2) ?? '0') * 60 +
        int.parse(m.group(3) ?? '0');
  }

  /// Live stream, or null if the channel is not currently live.
  static Future<YouTubeVideo?> getLiveStream() =>
      _cached('live', _liveTtl, _fetchLiveStream);

  static Future<YouTubeVideo?> _fetchLiveStream() =>
      _findBroadcast('live');

  /// Next scheduled live stream, or null.
  static Future<YouTubeVideo?> getUpcomingLive() =>
      _cached('upcoming', _liveTtl, _fetchUpcomingLive);

  static Future<YouTubeVideo?> _fetchUpcomingLive() =>
      _findBroadcast('upcoming');

  /// A recent upload whose broadcast state is [state] ('live' or 'upcoming').
  static Future<YouTubeVideo?> _findBroadcast(String state) async {
    final recent = await _fetchUploads(10);
    if (recent.isEmpty) return null;
    final details = await _videoDetails([for (final v in recent) v.videoId]);
    for (final v in recent) {
      final snippet = details[v.videoId]?['snippet'] as Map<String, dynamic>?;
      if (snippet?['liveBroadcastContent'] == state) {
        return YouTubeVideo(
          videoId: v.videoId,
          title: v.title,
          thumbnailUrl: v.thumbnailUrl,
          channelTitle: v.channelTitle,
          publishedAt: v.publishedAt,
          isLive: state == 'live',
        );
      }
    }
    return null;
  }

  /// Most recent videos from the channel (not filtered by duration).
  static Future<List<YouTubeVideo>> getVideos({int count = 20}) =>
      _cachedList('videos_$count', () => _fetchUploads(count));

  /// Alias used by ShortsScreen and HomeViewModel.
  static Future<List<YouTubeVideo>> getRecentVideos({int count = 12}) =>
      getVideos(count: count);

  /// Uploads under 70 seconds — YouTube has no "is a short" API flag.
  static Future<List<YouTubeVideo>> getShorts({int count = 20}) =>
      _cachedList('shorts_$count', () => _fetchShorts(count));

  static Future<List<YouTubeVideo>> _fetchShorts(int count) async {
    final uploads = await _fetchUploads(50);
    if (uploads.isEmpty) return [];
    final details = await _videoDetails([for (final v in uploads) v.videoId]);
    final shorts = <YouTubeVideo>[];
    for (final v in uploads) {
      final content = details[v.videoId]?['contentDetails'] as Map<String, dynamic>?;
      final seconds = _durationSeconds(content?['duration'] as String? ?? '');
      if (seconds > 0 && seconds <= 70) {
        shorts.add(YouTubeVideo(
          videoId: v.videoId,
          title: v.title,
          thumbnailUrl: v.thumbnailUrl,
          channelTitle: v.channelTitle,
          publishedAt: v.publishedAt,
          isShort: true,
        ));
        if (shorts.length >= count) break;
      }
    }
    return shorts;
  }

  /// Public playlists for the channel.
  static Future<List<YouTubePlaylist>> getPlaylists({int maxResults = 20}) async {
    const key = 'playlists';
    final hit = _memo[key];
    if (hit != null && DateTime.now().difference(hit.at) < _listTtl) {
      return hit.value as List<YouTubePlaylist>;
    }
    final stored = await LocalCache.readEntry('yt_$key');
    final value = stored?.value;
    if (value is List && value.isNotEmpty) {
      final playlists = value
          .cast<Map<String, dynamic>>()
          .map(YouTubePlaylist.fromJson)
          .toList();
      _memo[key] = _CacheEntry(playlists, DateTime.now());
      if (DateTime.now().difference(stored!.at) > _diskTtl) {
        unawaited(_refreshPlaylists(key, maxResults));
      }
      return playlists;
    }
    return _refreshPlaylists(key, maxResults);
  }

  static Future<List<YouTubePlaylist>> _refreshPlaylists(
      String key, int maxResults) async {
    final raw = await _fetchPlaylistsRaw(maxResults);
    if (raw.isEmpty) return const [];
    final playlists = raw.map(YouTubePlaylist.fromJson).toList();
    _memo[key] = _CacheEntry(playlists, DateTime.now());
    unawaited(LocalCache.write('yt_$key', raw));
    return playlists;
  }

  static Future<List<Map<String, dynamic>>> _fetchPlaylistsRaw(
      int maxResults) async {
    try {
      final channelId = await _getChannelId();
      if (channelId == null) return [];
      final uri = Uri.parse(
        '$_base/playlists?part=snippet,contentDetails'
        '&channelId=$channelId'
        '&maxResults=$maxResults'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Videos inside a playlist (up to [maxResults]).
  static Future<List<YouTubeVideo>> getPlaylistVideos(
    String playlistId, {
    int maxResults = 50,
  }) async {
    try {
      final uri = Uri.parse(
        '$_base/playlistItems?part=snippet'
        '&playlistId=$playlistId'
        '&maxResults=$maxResults'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        // ignore: avoid_print
        print('[YouTubeService] getPlaylistVideos ${res.statusCode}: '
            '${res.body.substring(0, res.body.length.clamp(0, 200))}');
        return [];
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items.map((e) {
        final snippet =
            (e as Map<String, dynamic>)['snippet'] as Map<String, dynamic>;
        final thumbnails =
            snippet['thumbnails'] as Map<String, dynamic>? ?? {};
        final thumb = (thumbnails['high'] ??
                thumbnails['medium'] ??
                thumbnails['default']) as Map<String, dynamic>?;
        return YouTubeVideo(
          videoId: (snippet['resourceId']
              as Map<String, dynamic>)['videoId'] as String,
          title: snippet['title'] as String? ?? '',
          thumbnailUrl: thumb?['url'] as String? ?? '',
          channelTitle: snippet['channelTitle'] as String? ?? '',
          publishedAt: snippet['publishedAt'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Concurrent viewer count for a live video.
  static Future<String?> getLiveViewerCount(String videoId) async {
    try {
      final uri = Uri.parse(
        '$_base/videos?part=liveStreamingDetails'
        '&id=$videoId'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) return null;
      final details =
          (items.first as Map<String, dynamic>)['liveStreamingDetails']
              as Map<String, dynamic>?;
      final count = details?['concurrentViewers'] as String?;
      if (count == null) return null;
      final n = int.tryParse(count) ?? 0;
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
      return '$n';
    } catch (_) {
      return null;
    }
  }
}
