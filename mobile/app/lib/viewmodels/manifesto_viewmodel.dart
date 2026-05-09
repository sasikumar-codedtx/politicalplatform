import 'package:flutter/foundation.dart';
import '../models/manifesto_plan.dart';
import '../services/content_service.dart';

class ManifestoViewModel extends ChangeNotifier {
  List<ManifestoPlan> plans = [];
  List<ManifestoVision> visions = [];
  String selectedYear = '';
  List<ManifestoPlan> get plansForYear =>
      selectedYear.isEmpty ? plans : plans.where((p) => p.year == selectedYear).toList();
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final results = await Future.wait([
      ContentService.getManifestoPlans(),
      ContentService.getManifestoVisions(),
    ]);
    plans = results[0] as List<ManifestoPlan>;
    visions = results[1] as List<ManifestoVision>;
    if (plans.isNotEmpty) selectedYear = plans.first.year;
    loading = false;
    notifyListeners();
  }

  void selectYear(String year) {
    selectedYear = year;
    notifyListeners();
  }
}
