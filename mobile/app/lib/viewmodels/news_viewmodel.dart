import 'package:flutter/foundation.dart';
import '../models/news_item.dart';
import '../services/content_service.dart';

class NewsViewModel extends ChangeNotifier {
  List<NewsItem> allNews = [];
  List<NewsItem> filtered = [];
  List<String> categories = ['All'];
  String selectedCategory = 'All';
  String searchQuery = '';
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    allNews = await ContentService.getNews();
    final cats = allNews.map((n) => n.category).toSet().toList();
    categories = ['All', ...cats];
    _applyFilter();
    loading = false;
    notifyListeners();
  }

  void selectCategory(String cat) {
    selectedCategory = cat;
    _applyFilter();
    notifyListeners();
  }

  void search(String query) {
    searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    filtered = allNews.where((n) {
      final matchCat = selectedCategory == 'All' || n.category == selectedCategory;
      final matchSearch = searchQuery.isEmpty ||
          n.title.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }
}
