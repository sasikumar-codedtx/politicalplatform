import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../models/news_item.dart';
import '../models/youtube_video.dart';
import '../services/content_service.dart';
import 'news_detail_screen.dart';
import 'video_player_screen.dart';

// A news item sourced from YouTube plays in the video player; a CMS article
// opens the detail screen.
void openNewsItem(BuildContext context, NewsItem item) {
  if (item.isVideo) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VideoPlayerScreen(
        video: YouTubeVideo(
          videoId: item.videoId!,
          title: item.title,
          thumbnailUrl: item.imageUrl ?? '',
          channelTitle: item.summary,
          publishedAt: '',
        ),
      ),
    ));
  } else {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NewsDetailScreen(item: item),
    ));
  }
}

// ─── Filter constants ─────────────────────────────────────────────────────────
const _kCategories = ['All', 'Party', 'Event', 'Policy', 'Agriculture'];

const _kDistricts = [
  'All Districts', 'Chennai', 'Coimbatore', 'Madurai', 'Salem',
  'Tiruvallur', 'Vellore', 'Erode', 'Tirunelveli', 'Thanjavur',
  'Tiruchirappalli', 'Kanchipuram', 'Namakkal',
];

const _kVerticals = [
  'All Sectors', 'Education', 'Child Care', 'PWD', 'Health',
  'Agriculture', 'Youth', 'Women', 'Infrastructure', 'Employment',
];

const _kMinistries = [
  'All Ministries', 'Finance', 'Education', 'Health', 'Agriculture',
  'Revenue', 'Infrastructure', 'Social Welfare', 'IT & Digital',
];

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
  String _activeDistrict = 'All Districts';
  String _activeVertical = 'All Sectors';
  String _activeMinistry = 'All Ministries';

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

  bool get _hasActiveAdvancedFilter =>
      _activeDistrict != 'All Districts' ||
      _activeVertical != 'All Sectors' ||
      _activeMinistry != 'All Ministries';

  void _openFilterSheet() {
    // Local copies so changes only apply on "Apply"
    String tmpDistrict = _activeDistrict;
    String tmpVertical = _activeVertical;
    String tmpMinistry = _activeMinistry;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          bool hasActive = tmpDistrict != 'All Districts' ||
              tmpVertical != 'All Sectors' ||
              tmpMinistry != 'All Ministries';

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (_, scrollCtrl) => Column(
              children: [
                // Handle + header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(t('news.filter_title'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              )),
                          const Spacer(),
                          if (hasActive)
                            GestureDetector(
                              onTap: () => setSheetState(() {
                                tmpDistrict = 'All Districts';
                                tmpVertical = 'All Sectors';
                                tmpMinistry = 'All Ministries';
                              }),
                              child: Text(t('news.clear_all'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE40101),
                                  )),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border),

                // Active filter chips
                if (hasActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (tmpDistrict != 'All Districts')
                          _ActiveChip(
                            label: tmpDistrict,
                            onRemove: () => setSheetState(
                                () => tmpDistrict = 'All Districts'),
                          ),
                        if (tmpVertical != 'All Sectors')
                          _ActiveChip(
                            label: tmpVertical,
                            onRemove: () => setSheetState(
                                () => tmpVertical = 'All Sectors'),
                          ),
                        if (tmpMinistry != 'All Ministries')
                          _ActiveChip(
                            label: tmpMinistry,
                            onRemove: () => setSheetState(
                                () => tmpMinistry = 'All Ministries'),
                          ),
                      ],
                    ),
                  ),

                // Scrollable filter sections
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      _SheetFilterSection(
                        title: t('news.section_district'),
                        options: _kDistricts,
                        active: tmpDistrict,
                        onSelect: (v) => setSheetState(() => tmpDistrict = v),
                      ),
                      const SizedBox(height: 20),
                      _SheetFilterSection(
                        title: t('news.section_sector'),
                        options: _kVerticals,
                        active: tmpVertical,
                        onSelect: (v) => setSheetState(() => tmpVertical = v),
                      ),
                      const SizedBox(height: 20),
                      _SheetFilterSection(
                        title: t('news.section_ministry'),
                        options: _kMinistries,
                        active: tmpMinistry,
                        onSelect: (v) => setSheetState(() => tmpMinistry = v),
                      ),
                    ],
                  ),
                ),

                // Apply button
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16,
                      16 + MediaQuery.of(ctx).padding.bottom),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeDistrict = tmpDistrict;
                        _activeVertical = tmpVertical;
                        _activeMinistry = tmpMinistry;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(t('news.apply_filters'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _NewsBanner(topPad: topPad),
                ),
              ],
              body: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE40101)))
                  : _NewsBody(
                      news: _filtered,
                      categories: _kCategories,
                      activeCategory: _activeCategory,
                      searchQuery: _searchQuery,
                      hasActiveAdvancedFilter: _hasActiveAdvancedFilter,
                      onCategoryChanged: (c) =>
                          setState(() => _activeCategory = c),
                      onSearchChanged: (q) =>
                          setState(() => _searchQuery = q),
                      onOpenFilters: _openFilterSheet,
                    ),
            ),
            // Sticky back button — only when pushed (not the News tab root);
            // pinned above the scroll so it never scrolls away.
            Builder(
              builder: (ctx) {
                if (!Navigator.canPop(ctx)) return const SizedBox.shrink();
                return Positioned(
                  top: topPad + 14,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                );
              },
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
      width: double.infinity,
      height: topPad + 190,
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
                    t('news.title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bebasNeue(
                      fontSize: LocaleController.isTamil ? 24 : 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t('news.subtitle'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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

// ─── Search + filter + scrollable list ───────────────────────────────────────

class _NewsBody extends StatelessWidget {
  final List<NewsItem> news;
  final List<String> categories;
  final String activeCategory;
  final String searchQuery;
  final bool hasActiveAdvancedFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;

  const _NewsBody({
    required this.news,
    required this.categories,
    required this.activeCategory,
    required this.searchQuery,
    required this.hasActiveAdvancedFilter,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar + filter toggle
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
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
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: t('news.search_hint'),
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary.withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppColors.textMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter button → opens bottom sheet
                  GestureDetector(
                    onTap: onOpenFilters,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasActiveAdvancedFilter
                            ? const Color(0xFFE40101)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasActiveAdvancedFilter
                              ? const Color(0xFFE40101)
                              : AppColors.border,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x18000000), blurRadius: 4),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: hasActiveAdvancedFilter
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          if (hasActiveAdvancedFilter)
                            Positioned(
                              top: 6, right: 6,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Category filter chips
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cat,
                              maxLines: 1,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
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

        // ── Active filter chips row (when filters are applied) ──────────────
        if (hasActiveAdvancedFilter)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded,
                    size: 14, color: Color(0xFFE40101)),
                const SizedBox(width: 4),
                Text(t('news.filters_active'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE40101),
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: onOpenFilters,
                  child: Text(t('news.edit'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      )),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),
        // News list
        Expanded(
          child: news.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.newspaper_outlined,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        t('news.no_news'),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: news.length,
                  separatorBuilder: (context, i) => Divider(
                      height: 20, thickness: 0.5, color: AppColors.border),
                  itemBuilder: (context, i) => _NewsCard(
                    item: news[i],
                    onTap: () => openNewsItem(context, news[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Bottom-sheet: active filter chip with remove ────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE40101).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE40101).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE40101),
              )),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFFE40101)),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom-sheet: section with wrap of filter chips ─────────────────────────

class _SheetFilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final String active;
  final ValueChanged<String> onSelect;

  const _SheetFilterSection({
    required this.title,
    required this.options,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isActive = opt == active;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE40101)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFE40101)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
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
          // Thumbnail (with a play badge when the item is a video)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => _ThumbPlaceholder(item),
                        )
                      : _ThumbPlaceholder(item),
                  if (item.isVideo)
                    const Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 34),
                    ),
                ],
              ),
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
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.share_outlined,
                        size: 16, color: AppColors.textMuted),
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
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                // Date + time row
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      item.time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
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
