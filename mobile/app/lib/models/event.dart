class PartyEvent {
  final String id;
  final String title;
  final String location;
  final String date;
  final String time;
  final String type;
  final String description;
  final String? imageUrl;

  const PartyEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.type,
    required this.description,
    this.imageUrl,
  });
}
