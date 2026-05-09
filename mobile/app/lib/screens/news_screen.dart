import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/news_item.dart';
import '../viewmodels/news_viewmodel.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsViewModel()..load(),
      child: const _NewsView(),
    );
  }
}

class _NewsView extends StatelessWidget {
  const _NewsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewsViewModel>();
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final surface = Color(f.surfaceColor);
    final border = Color(f.borderColor);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            floating: true,
            snap: true,
            pinned: true,
            elevation: 0,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: _TvkBanner(
                title: "TVK'S NEWS",
                subtitle: 'STAY INFORMED WITH REAL-TIME NEWS, ANNOUNCEMENTS,\nAND PROGRESS FROM TVK.',
                primary: primary,
              ),
              collapseMode: CollapseMode.pin,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(color: const Color(0xFF666666), fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF666666), size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            isDense: true,
                          ),
                          onChanged: (v) => context.read<NewsViewModel>().search(v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF888888), size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: CustomScrollView(
          slivers: [
            // Category chips
            SliverToBoxAdapter(
              child: vm.loading
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        itemCount: vm.categories.length,
                        itemBuilder: (context, i) {
                          final cat = vm.categories[i];
                          final isSelected = vm.selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => context.read<NewsViewModel>().selectCategory(cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? primary : surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSelected ? primary : border),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  color: isSelected ? Colors.white : const Color(0xFF888888),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (vm.loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (vm.filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text('No news found', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14)),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _NewsCard(item: vm.filtered[i], primary: primary, surface: surface, border: border),
                  childCount: vm.filtered.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Shared TVK golden banner widget — used across all tab screens
class _TvkBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primary;
  const _TvkBanner({required this.title, required this.subtitle, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC49A00), Color(0xFF7D1400)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emblem area
          Expanded(
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 34),
              ),
            ),
          ),
          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              color: primary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final Color primary;
  final Color surface;
  final Color border;

  const _NewsCard({required this.item, required this.primary, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left thumbnail
          Container(
            width: 100,
            height: 78,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.article_rounded, color: primary.withValues(alpha: 0.4), size: 32),
          ),
          const SizedBox(width: 12),
          // Right content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.summary,
                  style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 12, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Color(0xFF666666), size: 11),
                    const SizedBox(width: 3),
                    Text(item.date, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 11)),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded, color: Color(0xFF666666), size: 11),
                    const SizedBox(width: 3),
                    Text(item.time, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 11)),
                    const Spacer(),
                    const Icon(Icons.share_outlined, color: Color(0xFF666666), size: 16),
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
