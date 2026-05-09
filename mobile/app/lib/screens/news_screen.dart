import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/news_item.dart';
import '../services/content_service.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsItem> _news = [];
  bool _loading = true;
  int _selectedCat = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final news = await ContentService.getNews();
    if (mounted) setState(() { _news = news; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE40101))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TvkHeader(
              title: "TVK's NEWS",
              subtitle: 'Stay informed with real-time news, announcements, and progress from TVK.',
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SearchBar(),
                  const SizedBox(height: 24),
                  _CategoryTabs(
                    selected: _selectedCat,
                    onSelect: (i) => setState(() => _selectedCat = i),
                  ),
                  const SizedBox(height: 24),
                  ..._news.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _NewsCard(item: item),
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvkHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _TvkHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 230 + topPad,
      child: Stack(
        children: [
          // TVK flag image
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover),
            ),
          ),
          // Gradient: transparent at top → black at bottom
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                  colors: [Colors.transparent, Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
          // Title block at bottom
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.4,
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

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.black38, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black38,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const Icon(Icons.tune_rounded, color: Colors.black54, size: 20),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  static const _labels = ['All', 'Agriculture', 'Business', 'Education'];

  const _CategoryTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final isActive = i == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              height: 34,
              margin: EdgeInsets.only(right: i < _labels.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE40101), Color(0x00E40101)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(isActive ? 8 : 6),
              ),
              alignment: Alignment.center,
              child: Text(
                _labels[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Thumbnail — 96×96 rounded-[10px]
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 96,
              height: 96,
              color: const Color(0xFFEEEEEE),
              child: const Icon(Icons.image_outlined, color: Colors.black38, size: 32),
            ),
          ),
          // Right column — 246px wide
          SizedBox(
            width: 246,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.ios_share_rounded, color: Colors.black54, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 223,
                  child: Text(
                    item.summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 17 / 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      item.date,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
