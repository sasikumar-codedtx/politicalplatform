import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/news_item.dart';
import '../services/content_service.dart';
import 'news_detail_screen.dart';

// ─── Category filter list ─────────────────────────────────────────────────────
const _kCategories = ['All', 'Party', 'Event', 'Policy', 'Agriculture'];

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsItem> _allNews = [];
  bool _loading = true;
  String _activeCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final news = await ContentService.getNews();
    if (mounted) setState(() { _allNews = news; _loading = false; });
  }

  List<NewsItem> get _filtered {
    var list = _allNews;
    if (_activeCategory != 'All') {
      list = list.where((n) => n.category == _activeCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.summary.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── Hero banner ──────────────────────────────────────────
            _NewsBanner(topPad: topPad),

            // ── Search + filter + list ────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFE40101)))
                  : _NewsBody(
                      news: _filtered,
                      categories: _kCategories,
                      activeCategory: _activeCategory,
                      searchQuery: _searchQuery,
                      onCategoryChanged: (c) =>
                          setState(() => _activeCategory = c),
                      onSearchChanged: (q) =>
                          setState(() => _searchQuery = q),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner (TVK flag bg + title) ───────────────────────────────────────

class _NewsBanner extends StatelessWidget {
  final double topPad;
  const _NewsBanner({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topPad + 160,
      child: Stack(
        children: [
          // TVK flag background
          Positioned.fill(
            child: Image.asset(
              'assets/images/tvk_flag.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D0A0A), Color(0xFF8B1010)],
                  ),
                ),
              ),
            ),
          ),

          // Dark overlay top→bottom
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),

          // Title block
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                  ).createShader(bounds),
                  child: Text(
                    "TVK's NEWS",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay informed with real-time news, announcements, and progress from TVK.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search + filter + scrollable list ───────────────────────────────────────

class _NewsBody extends StatelessWidget {
  final List<NewsItem> news;
  final List<String> categories;
  final String activeCategory;
  final String searchQuery;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  const _NewsBody({
    required this.news,
    required this.categories,
    required this.activeCategory,
    required this.searchQuery,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDEDEDE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x29000000),
                      blurRadius: 1.5,
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: onSearchChanged,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: const Color(0xFF242424)),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF242424).withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF888888), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Category filter chips
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEBEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: categories.map((cat) {
                    final isActive = cat == activeCategory;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onCategoryChanged(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 34,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFE40101)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF242424),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // News list
        Expanded(
          child: news.isEmpty
              ? Center(
                  child: Text(
                    'No news found',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF888888)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: news.length,
                  separatorBuilder: (context, i) => const Divider(
                      height: 20, thickness: 0.5, color: Color(0xFFEEEEEE)),
                  itemBuilder: (context, i) => _NewsCard(
                    item: news[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailScreen(item: news[i]),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── News card ────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;
  const _NewsCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 96,
              height: 96,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _ThumbPlaceholder(item),
                    )
                  : _ThumbPlaceholder(item),
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF242424),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.share_outlined,
                        size: 16, color: Color(0xFF888888)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF242424),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                // Date + time row
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(
                      item.date,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF242424).withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF242424).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Gradient placeholder thumbnail when no imageUrl
class _ThumbPlaceholder extends StatelessWidget {
  final NewsItem item;
  const _ThumbPlaceholder(this.item);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B1010), Color(0xFFE40101)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        item.category[0],
        style: GoogleFonts.bebasNeue(
          fontSize: 36,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
