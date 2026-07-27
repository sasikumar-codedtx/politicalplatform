class YouTubeVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String publishedAt;
  final bool isLive;
  final bool isShort;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    this.isLive = false,
    this.isShort = false,
  });

  factory YouTubeVideo.fromSearchJson(
    Map<String, dynamic> json, {
    bool isShort = false,
  }) {
    final snippet = json['snippet'] as Map<String, dynamic>;

    // Search results have `id` as a Map; playlist items may have it as a String.
    final idField = json['id'];
    final videoId =
        idField is Map ? idField['videoId'] as String : idField as String;

    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
    final thumb =
        (thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'])
            as Map<String, dynamic>;

    return YouTubeVideo(
      videoId: videoId,
      title: snippet['title'] as String,
      thumbnailUrl: thumb['url'] as String,
      channelTitle: snippet['channelTitle'] as String? ?? '',
      publishedAt: snippet['publishedAt'] as String? ?? '',
      isLive: snippet['liveBroadcastContent'] == 'live',
      isShort: isShort,
    );
  }

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'channelTitle': channelTitle,
        'publishedAt': publishedAt,
        'isLive': isLive,
        'isShort': isShort,
      };

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) => YouTubeVideo(
        videoId: json['videoId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        channelTitle: json['channelTitle'] as String? ?? '',
        publishedAt: json['publishedAt'] as String? ?? '',
        isLive: json['isLive'] as bool? ?? false,
        isShort: json['isShort'] as bool? ?? false,
      );

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  String get formattedDate {
    if (publishedAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(publishedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return '';
    }
  }
}
