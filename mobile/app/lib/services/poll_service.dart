import '../config/app_config.dart';
import '../models/poll.dart';

class PollService {
  static Future<Poll> getDailyPoll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return AppConfig.flavorName == 'tn-tvk' ? _tvkPoll : _incPoll;
  }

  static Future<Poll> vote(String pollId, String optionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final poll = await getDailyPoll();
    poll.selectedOptionId = optionId;
    return poll;
  }

  static final Poll _tvkPoll = Poll(
    id: 'tvk-daily-1',
    question: 'Which TVK scheme should be prioritised in 2026?',
    totalVotes: 48320,
    options: [
      PollOption(id: 'a', text: 'Clean Water for Villages', votes: 18200),
      PollOption(id: 'b', text: 'Digital Classrooms', votes: 12100),
      PollOption(id: 'c', text: 'Youth Employment', votes: 10500),
      PollOption(id: 'd', text: 'Farmer Income Guarantee', votes: 7520),
    ],
  );

  static final Poll _incPoll = Poll(
    id: 'inc-daily-1',
    question: 'Which Nyay Patra pillar matters most to you?',
    totalVotes: 92450,
    options: [
      PollOption(id: 'a', text: 'Kisan Nyay', votes: 31200),
      PollOption(id: 'b', text: 'Yuva Nyay', votes: 28400),
      PollOption(id: 'c', text: 'Nari Nyay', votes: 19800),
      PollOption(id: 'd', text: 'Hissedari Nyay', votes: 13050),
    ],
  );
}
