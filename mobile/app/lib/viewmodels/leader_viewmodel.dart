import 'package:flutter/foundation.dart';
import '../models/leader.dart';
import '../models/short_video.dart';
import '../services/content_service.dart';

class LeaderViewModel extends ChangeNotifier {
  Leader? leader;
  List<ShortVideo> media = [];
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final results = await Future.wait([
      ContentService.getLeader(),
      ContentService.getShorts(),
    ]);
    leader = results[0] as Leader;
    media = results[1] as List<ShortVideo>;
    loading = false;
    notifyListeners();
  }
}
