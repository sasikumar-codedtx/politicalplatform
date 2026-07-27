import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../models/poll.dart';
import '../models/event.dart';
import '../models/youtube_video.dart';
import '../services/content_service.dart';
import '../services/agent_service.dart';
import '../services/youtube_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<NewsItem> latestNews = [];
  List<PartyEvent> upcomingEvents = [];
  Poll? dailyPoll;
  List<YouTubeVideo> recentShorts = [];
  YouTubeVideo? liveBanner;
  bool loading = true;

  Future<void> load() async {
    // Each source is cache-first and fills its section independently — the
    // page is NEVER gated behind a single Future.wait, so a slow/failed call
    // (e.g. the YouTube merge inside getNews on a first run) can't hold the
    // whole screen on a spinner.
    ContentService.getNews().then((news) {
      latestNews = news.take(4).toList();
      loading = false;
      notifyListeners();
    });
    ContentService.getEvents().then((events) {
      upcomingEvents = events.take(3).toList();
      notifyListeners();
    });
    AgentService.listPolls().then((polls) {
      dailyPoll = _mapDailyPoll(polls);
      notifyListeners();
    });
    _loadYouTubeShorts();
    _checkLiveBanner();

    // Safety net: reveal the page quickly even if the first content call is
    // slow. Cached runs flip `loading` in a few ms; this only matters on a
    // cold first launch with an empty cache.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (loading) {
        loading = false;
        notifyListeners();
      }
    });
  }

  // The Home daily-poll card shows the most recent community poll from the
  // real backend (same source as the Polls screen). Returns null when there
  // are no polls yet, which hides the card.
  Poll? _mapDailyPoll(List<Map<String, dynamic>> polls) {
    if (polls.isEmpty) return null;
    final p = polls.first;
    final options = ((p['options'] as List?) ?? const []).cast<String>();
    final myVote = p['my_vote'] as int?;
    return Poll(
      id: (p['id'] as int).toString(),
      question: p['question'] as String? ?? '',
      options: [
        for (var i = 0; i < options.length; i++)
          PollOption(id: '$i', text: options[i], votes: 0),
      ],
      totalVotes: (p['responses'] as int?) ?? 0,
      selectedOptionId: myVote?.toString(),
    );
  }

  Future<void> _loadYouTubeShorts() async {
    final videos = await YouTubeService.getShorts(count: 10);
    recentShorts = videos;
    notifyListeners();
  }

  Future<void> _checkLiveBanner() async {
    final live = await YouTubeService.getLiveStream();
    if (live != null) {
      liveBanner = live;
      notifyListeners();
    }
  }

  Future<void> vote(String optionId) async {
    final poll = dailyPoll;
    if (poll == null || poll.selectedOptionId != null) return;
    final pollId = int.tryParse(poll.id);
    final optionIndex = int.tryParse(optionId);
    if (pollId == null || optionIndex == null) return;

    final ok = await AgentService.votePoll(pollId, optionIndex);
    if (!ok) return;
    dailyPoll = Poll(
      id: poll.id,
      question: poll.question,
      options: poll.options,
      totalVotes: poll.totalVotes + 1,
      selectedOptionId: optionId,
    );
    notifyListeners();
  }
}
