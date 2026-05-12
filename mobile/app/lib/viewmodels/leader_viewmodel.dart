import 'package:flutter/foundation.dart';
import '../models/leader.dart';
import '../services/content_service.dart';

class LeaderViewModel extends ChangeNotifier {
  Leader? leader;
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    leader = await ContentService.getLeader();
    loading = false;
    notifyListeners();
  }
}
