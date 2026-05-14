import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import '../models/youtube_video.dart';
import '../models/youtube_playlist.dart';

class YouTubeService {
  static const _base = 'https://www.googleapis.com/youtube/v3';

  // Cached channel ID resolved from the handle once per session.
  static String? _channelId;

  static Future<String?> _getChannelId() async {
    if (_channelId != null) return _channelId;
    try {
      final uri = Uri.parse(
        '$_base/channels?part=id'
        '&forHandle=${Secrets.youtubeChannelHandle}'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) return null;
      _channelId = (items.first as Map<String, dynamic>)['id'] as String;
      return _channelId;
    } catch (_) {
      return null;
    }
  }

  /// Live stream, or null if the channel is not currently live.
  static Future<YouTubeVideo?> getLiveStream() async {
    try {
      final channelId = await _getChannelId();
      if (channelId == null) return null;
      final uri = Uri.parse(
        '$_base/search?part=snippet'
        '&channelId=$channelId'
        '&eventType=live'
        '&type=video'
        '&maxResults=1'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) return null;
      return YouTubeVideo.fromSearchJson(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Next scheduled live stream, or null.
  static Future<YouTubeVideo?> getUpcomingLive() async {
    try {
      final channelId = await _getChannelId();
      if (channelId == null) return null;
      final uri = Uri.parse(
        '$_base/search?part=snippet'
        '&channelId=$channelId'
        '&eventType=upcoming'
        '&type=video'
        '&maxResults=1'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      if (items.isEmpty) return null;
      return YouTubeVideo.fromSearchJson(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Most recent videos from the channel (not filtered by duration).
  static Future<List<YouTubeVideo>> getVideos({int count = 20}) async {
    try {
      final channelId = await _getChannelId();
      if (channelId == null) return [];
      final uri = Uri.parse(
        '$_base/search?part=snippet'
        '&channelId=$channelId'
        '&type=video'
        '&order=date'
        '&maxResults=$count'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => YouTubeVideo.fromSearchJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Alias used by ShortsScreen and HomeViewModel.
  static Future<List<YouTubeVideo>> getRecentVideos({int count = 12}) =>
      getVideos(count: count);

  /// Short-form videos (< 4 minutes, #shorts keyword) from the channel.
  static Future<List<YouTubeVideo>> getShorts({int count = 20}) async {
    try {
      final channelId = await _getChannelId();
      if (channelId == null) return [];
      final uri = Uri.parse(
        '$_base/search?part=snippet'
        '&channelId=$channelId'
        '&type=video'
        '&videoDuration=short'
        '&q=%23shorts'
        '&order=date'
        '&maxResults=$count'
        '&key=${Secrets.youtubeApiKey}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        // ignore: avoid_print
        print('[YouTubeService] getShorts ${res.statusCode}: '
            '${res.body.substring(0, res.body.length.clamp(0, 200))}');
        return [];
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map(
            (e) => YouTubeVideo.fromSearchJson(
              e as Map<String, dynamic>,
              isShort: true,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Public playlists for the channel.
  static Future<List<YouTubePlaylist>> getPlaylists({
    int maxResults = 20,
  }) async {
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
      return items
          .map((e) => YouTubePlaylist.fromJson(e as Map<String, dynamic>))
          .toList();
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
