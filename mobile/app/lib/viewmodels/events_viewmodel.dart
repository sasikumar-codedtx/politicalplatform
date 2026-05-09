import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/content_service.dart';

class EventsViewModel extends ChangeNotifier {
  List<PartyEvent> events = [];
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    events = await ContentService.getEvents();
    loading = false;
    notifyListeners();
  }
}
