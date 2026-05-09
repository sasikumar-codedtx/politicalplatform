class Poll {
  final String id;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  String? selectedOptionId;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.totalVotes,
    this.selectedOptionId,
  });
}

class PollOption {
  final String id;
  final String text;
  final int votes;

  const PollOption({
    required this.id,
    required this.text,
    required this.votes,
  });

  double percentage(int total) => total == 0 ? 0 : votes / total;
}
