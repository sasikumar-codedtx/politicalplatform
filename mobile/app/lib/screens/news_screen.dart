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
    final topPad = MediaQuery.of(context).padding.top;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F6F6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF9F1D1F))),
      );
    }

    // Split news into sections based on category / order
    final speeches = _news.where((n) => n.category == 'Party' || n.category == 'Statement').take(1).toList();
    final highlights = _news.where((n) => n.category != 'Party' && n.category != 'Statement').take(2).toList();
    final tweets = _news.skip(3).take(1).toList();

    // Fallback: if filtering is sparse, use all
    final speechList = speeches.isNotEmpty ? speeches : _news.take(1).toList();
    final highlightList = highlights.isNotEmpty ? highlights : (_news.length > 1 ? _news.sublist(1, 3) : []);
    final tweetList = tweets.isNotEmpty ? tweets : (_news.length > 3 ? _news.sublist(3, 4) : []);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────
          _AppBar(topPad: topPad),
          // ── Content ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TVK Leader Speeches section
                  _SectionTitle(title: "TVK Leader Mr. Vijay's Speeches"),
                  const SizedBox(height: 12),
                  ...speechList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NewsCard(
                      item: item,
                      categoryColor: const Color(0xFF0E8412),
                      showPlayButton: true,
                    ),
                  )),
                  const SizedBox(height: 8),

                  // Today's Highlights section
                  _SectionTitle(title: "Today's Highlights"),
                  const SizedBox(height: 12),
                  ...highlightList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NewsCard(
                      item: item,
                      categoryColor: const Color(0xFF1455B3),
                      showPlayButton: true,
                    ),
                  )),
                  const SizedBox(height: 8),

                  // TVK Tweets section
                  _SectionTitle(title: 'TVK Tweets'),
                  const SizedBox(height: 12),
                  ...tweetList.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TweetCard(item: item),
                  )),
                  if (tweetList.isEmpty)
                    _TweetCard(item: NewsItem(
                      id: 'tweet1',
                      title: 'TVK President Vijay extends heartfelt gratitude',
                      summary: "TVK President Vijay extends heartfelt gratitude to supporters and well-wishers as he begins his political journey. He acknowledges the love from 'En Nenjil Kudiyirukkum Thozhargal' and promises to work for Tamil Nadu's welfare.",
                      category: 'Tweet',
                      date: 'Jun 4, 2024',
                      time: 'Just now',
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final double topPad;
  const _AppBar({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Latest News',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(Icons.translate_rounded, size: 24, color: Colors.black),
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}

// ─── News Card (Speech / Highlight style) ────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final Color categoryColor;
  final bool showPlayButton;

  const _NewsCard({
    required this.item,
    required this.categoryColor,
    this.showPlayButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: SizedBox(
                height: 166,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Placeholder image — use tvk_flag as fallback
                    Image.asset(
                      'assets/images/tvk_flag.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: const Color(0xFF1A1A1A)),
                    ),
                    // Dark overlay
                    Container(color: Colors.black.withValues(alpha: 0.50)),
                    // Play button
                    if (showPlayButton)
                      Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white30,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          item.category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Summary + Readmore
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF4A4949), height: 1.4),
                      children: [
                        TextSpan(text: '${item.summary.length > 80 ? item.summary.substring(0, 80) : item.summary}... '),
                        TextSpan(
                          text: 'Read more',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1455B3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Footer: time + likes + share
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF9D9B9B)),
                      const SizedBox(width: 4),
                      Text(
                        item.time,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF9D9B9B)),
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite_border_rounded, size: 18, color: Color(0xFF9F1D1F)),
                      const SizedBox(width: 4),
                      Text(
                        '1.2k',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF9F1D1F)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.ios_share_rounded, size: 18, color: Color(0xFF4A4949)),
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

// ─── Tweet Card ───────────────────────────────────────────────────────────────

class _TweetCard extends StatelessWidget {
  final NewsItem item;
  const _TweetCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: SizedBox(
              height: 166,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(color: const Color(0xFF716E6E))),
                  Container(color: Colors.black.withValues(alpha: 0.5)),
                  // Eye icon top-right
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.summary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Tweet Link : ',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                      TextSpan(
                        text: 'https://x.com/TVKVijayHQ/status/1754051963980070948',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF1455B3),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF1455B3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF9D9B9B)),
                    const SizedBox(width: 4),
                    Text(item.time,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF9D9B9B))),
                    const Spacer(),
                    const Icon(Icons.favorite_border_rounded, size: 18, color: Color(0xFF9F1D1F)),
                    const SizedBox(width: 4),
                    Text('1.2k',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF9F1D1F))),
                    const SizedBox(width: 12),
                    const Icon(Icons.ios_share_rounded, size: 18, color: Color(0xFF4A4949)),
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
