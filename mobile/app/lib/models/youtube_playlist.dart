class YouTubePlaylist {
  final String playlistId;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String publishedAt;
  final int videoCount;

  const YouTubePlaylist({
    required this.playlistId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
    required this.videoCount,
  });

  factory YouTubePlaylist.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final thumbnails =
        snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final thumb =
        (thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'])
            as Map<String, dynamic>?;
    final contentDetails =
        json['contentDetails'] as Map<String, dynamic>?;

    return YouTubePlaylist(
      playlistId: json['id'] as String,
      title: snippet['title'] as String,
      thumbnailUrl: thumb?['url'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      publishedAt: snippet['publishedAt'] as String? ?? '',
      videoCount:
          int.tryParse(contentDetails?['itemCount']?.toString() ?? '0') ?? 0,
    );
  }

  String get formattedDate {
    if (publishedAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(publishedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      return 'Today';
    } catch (_) {
      return '';
    }
  }
}
