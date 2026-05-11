class ManifestoPlan {
  final String id;
  final String year;
  final String title;
  final String description;
  final String timeline;
  final String budget;
  final String category;
  final String imageAsset;
  final List<String> bullets;

  const ManifestoPlan({
    required this.id,
    required this.year,
    required this.title,
    required this.description,
    required this.timeline,
    required this.budget,
    required this.category,
    this.imageAsset = 'assets/images/plan_water.png',
    this.bullets = const [],
  });
}

class ManifestoVision {
  final String title;
  final String description;
  final String targetYear;

  const ManifestoVision({required this.title, required this.description, this.targetYear = 'By 2030'});
}
