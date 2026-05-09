import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../models/poll.dart';
import '../models/short_video.dart';
import '../models/event.dart';
import '../services/content_service.dart';
import '../services/poll_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<NewsItem> latestNews = [];
  List<ShortVideo> shorts = [];
  List<PartyEvent> upcomingEvents = [];
  Poll? dailyPoll;
  bool loading = true;
  bool isLive = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final results = await Future.wait([
      ContentService.getNews(),
      ContentService.getShorts(),
      ContentService.getEvents(),
      PollService.getDailyPoll(),
    ]);

    latestNews = (results[0] as List<NewsItem>).take(4).toList();
    shorts = (results[1] as List<ShortVideo>).take(4).toList();
    upcomingEvents = (results[2] as List<PartyEvent>).take(3).toList();
    dailyPoll = results[3] as Poll;
    loading = false;
    notifyListeners();
  }

  Future<void> vote(String optionId) async {
    if (dailyPoll == null || dailyPoll!.selectedOptionId != null) return;
    dailyPoll = await PollService.vote(dailyPoll!.id, optionId);
    notifyListeners();
  }
}
