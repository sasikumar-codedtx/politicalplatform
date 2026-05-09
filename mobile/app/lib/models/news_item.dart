class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String date;
  final String time;
  final String? imageUrl;

  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.date,
    required this.time,
    this.imageUrl,
  });
}
