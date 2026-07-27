class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String date;
  final String time;
  final String? imageUrl;

  // When this item is a YouTube upload (merged into the feed), videoId is set
  // so the card plays the video instead of opening the article detail.
  final String? videoId;
  final String source; // 'cms' | 'youtube'

  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.date,
    required this.time,
    this.imageUrl,
    this.videoId,
    this.source = 'cms',
  });

  bool get isVideo => videoId != null && videoId!.isNotEmpty;
}
