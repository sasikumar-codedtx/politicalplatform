import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../models/poll.dart';
import '../models/event.dart';
import '../models/youtube_video.dart';
import '../services/content_service.dart';
import '../services/poll_service.dart';
import '../services/youtube_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<NewsItem> latestNews = [];
  List<PartyEvent> upcomingEvents = [];
  Poll? dailyPoll;
  List<YouTubeVideo> recentShorts = [];
  YouTubeVideo? liveBanner;
  bool loading = true;
  bool isLive = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final results = await Future.wait([
      ContentService.getNews(),
      ContentService.getEvents(),
      PollService.getDailyPoll(),
    ]);

    latestNews = (results[0] as List<NewsItem>).take(4).toList();
    upcomingEvents = (results[1] as List<PartyEvent>).take(3).toList();
    dailyPoll = results[2] as Poll;
    loading = false;
    notifyListeners();

    // Background: YouTube data (doesn't block the main render)
    _loadYouTubeShorts();
    _checkLiveBanner();
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
    if (dailyPoll == null || dailyPoll!.selectedOptionId != null) return;
    dailyPoll = await PollService.vote(dailyPoll!.id, optionId);
    notifyListeners();
  }
}
