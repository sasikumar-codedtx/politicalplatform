class Leader {
  final String id;
  final String name;
  final String role;
  final String location;
  final String bio;
  final String careerSummary;
  final List<LeaderAchievement> achievements;

  const Leader({
    required this.id,
    required this.name,
    required this.role,
    required this.location,
    required this.bio,
    required this.careerSummary,
    required this.achievements,
  });
}

class LeaderAchievement {
  final String year;
  final String title;
  final String description;

  const LeaderAchievement({
    required this.year,
    required this.title,
    required this.description,
  });
}
