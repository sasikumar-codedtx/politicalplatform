import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../services/content_service.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import 'video_player_screen.dart';

// ─── Campaign Toolkit Detail Screen ───────────────────────────────────────────
// Figma: 1328-3063 (Posters), 1328-3127 (Media/Audios), 1328-3084 (Media/Videos),
//        1328-3206 (Slogans), 1328-3284 (Hashtags)

class CampaignToolkitDetailScreen extends StatefulWidget {
  final String type; // 'Posters' | 'Media' | 'Slogans' | 'Hashtags'
  final List<Color> gradientColors;

  const CampaignToolkitDetailScreen({
    super.key,
    required this.type,
    required this.gradientColors,
  });

  @override
  State<CampaignToolkitDetailScreen> createState() =>
      _CampaignToolkitDetailScreenState();
}

class _CampaignToolkitDetailScreenState
    extends State<CampaignToolkitDetailScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            _Header(
              topPad: topPad,
              type: widget.type,
              onSearchChanged: (q) => setState(() => _query = q.trim()),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.type) {
      case 'Media':
        return _MediaBody(query: _query);
      case 'Slogans':
        return const _SlogansBody();
      case 'Hashtags':
        return const _HashtagsBody();
      default:
        return const _PostersBody();
    }
  }
}

// ─── Shared header ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  final String type;
  final ValueChanged<String> onSearchChanged;

  const _Header({
    required this.topPad,
    required this.type,
    required this.onSearchChanged,
  });

  String get _subtitle {
    switch (type) {
      case 'Media':    return 'Explore our members contents';
      case 'Slogans':  return 'Explore our members Slogans';
      case 'Hashtags': return 'Explore our members Hashtags';
      default:         return 'Explore our members posts';
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerH = topPad + 216.0;

    return Container(
      color: AppColors.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Banner with flag + gradient ──────────────────────────────────
          SizedBox(
            height: headerH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // TVK flag background
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/tvk_flag.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B0000), Color(0xFF4A0000)],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom-to-top black fade (Figma: from 16% → transparent)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  height: headerH * 0.84,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: topPad + 24,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
                // Title block
                Positioned(
                  left: 16, bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                        ).createShader(b),
                        child: Text(
                          'TVK ${type.toUpperCase()}',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 34,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Text(
                        _subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar — Media only ──────────────────────────────────────
          if (type == 'Media')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDEDEDE), width: 2),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search_rounded,
                        size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: onSearchChanged,
                        textAlignVertical: TextAlignVertical.center,
                        cursorColor: const Color(0xFFE40101),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          // Null every border state — otherwise the app theme's
                          // red focusedBorder draws a box inside this one.
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          hintText: 'Search',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── POSTERS BODY — staggered 2-col masonry grid ──────────────────────────────

class _PostersBody extends StatefulWidget {
  const _PostersBody();

  @override
  State<_PostersBody> createState() => _PostersBodyState();
}

class _PostersBodyState extends State<_PostersBody> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() {
    super.initState();
    ContentService.getToolkit('Posters').then((v) {
      if (mounted) setState(() => _items = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    // Admin-published posters take over when present; otherwise the built-in
    // Figma masonry below is shown so the screen is never empty.
    if (items != null && items.isNotEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final url = items[i]['image_url'] as String? ?? '';
          final gallery = [
            for (final m in items)
              _PosterImg(url: m['image_url'] as String? ?? ''),
          ];
          return GestureDetector(
            onTap: () => _openGallery(context, gallery, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(color: AppColors.surfaceAlt),
              ),
            ),
          );
        },
      );
    }
    return const _StaticPostersBody();
  }
}

class _StaticPostersBody extends StatelessWidget {
  const _StaticPostersBody();

  // Left column: 3 cards, all 264px tall (matches Figma Thalapathy5/1/7)
  static const _leftItems = [
    ('assets/images/campaign1.png',   264.0),
    ('assets/images/campaign_2.png',  264.0),
    ('assets/images/campaign2.png',   264.0),
  ];
  // Right column: 4 cards, alternating shorter/taller (Figma Thalapathy2/4/6/8)
  static const _rightItems = [
    ('assets/images/campaign2.png',   169.0),
    ('assets/images/campaign1.png',   264.0),
    ('assets/images/campaign_2.png',  169.0),
    ('assets/images/campaign2.png',   174.0),
  ];

  @override
  Widget build(BuildContext context) {
    // Combined gallery list (left column then right) so the fullscreen swipe
    // can page through every poster.
    final all = [..._leftItems, ..._rightItems];
    final gallery = [for (final it in all) _PosterImg(asset: it.$1)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column — all 264px (Figma: Thalapathy5/1/7)
            Expanded(
              child: Column(
                children: List.generate(_leftItems.length, (i) => Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _leftItems.length - 1 ? 10 : 0,
                  ),
                  child: _PosterCard(
                    asset: _leftItems[i].$1,
                    height: _leftItems[i].$2,
                    gallery: gallery,
                    galleryIndex: i,
                  ),
                )),
              ),
            ),
            const SizedBox(width: 10),
            // Right column — staggered heights, no vertical offset (Figma: Thalapathy2/4/6/8)
            Expanded(
              child: Column(
                children: List.generate(_rightItems.length, (i) => Padding(
                  padding: EdgeInsets.only(
                    bottom: i < _rightItems.length - 1 ? 10 : 0,
                  ),
                  child: _PosterCard(
                    asset: _rightItems[i].$1,
                    height: _rightItems[i].$2,
                    gallery: gallery,
                    galleryIndex: _leftItems.length + i,
                  ),
                )),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  final String asset;
  final double height;
  final List<_PosterImg> gallery;
  final int galleryIndex;
  const _PosterCard({
    required this.asset,
    required this.height,
    required this.gallery,
    required this.galleryIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openGallery(context, gallery, galleryIndex),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: height,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => Container(
              color: AppColors.surfaceAlt,
            ),
          ),
        ),
      ),
    );
  }
}

// One gallery image — a network url OR a bundled asset.
class _PosterImg {
  final String? url;
  final String? asset;
  const _PosterImg({this.url, this.asset});
}

// Opens the posters full-screen as a swipeable gallery: swipe left → next,
// swipe right → previous. Each page is zoomable.
void _openGallery(BuildContext context, List<_PosterImg> images, int index) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => _PosterGallery(images: images, initialIndex: index),
  ));
}

class _PosterGallery extends StatefulWidget {
  final List<_PosterImg> images;
  final int initialIndex;
  const _PosterGallery({required this.images, required this.initialIndex});

  @override
  State<_PosterGallery> createState() => _PosterGalleryState();
}

class _PosterGalleryState extends State<_PosterGallery> {
  late final PageController _pc = PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final img = widget.images[i];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: img.url != null
                      ? Image.network(img.url!, fit: BoxFit.contain,
                          errorBuilder: (_, e, s) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white38, size: 60))
                      : Image.asset(img.asset!, fit: BoxFit.contain),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_current + 1} / ${widget.images.length}',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Copies text to the clipboard and confirms — works on mobile and desktop/Mac
// (the copy itself always worked; there was just no feedback).
void _copy(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied to clipboard', style: GoogleFonts.plusJakartaSans()),
      backgroundColor: const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ),
  );
}

// ─── MEDIA BODY — Audios list + Videos list ───────────────────────────────────

class _MediaBody extends StatefulWidget {
  final String query;
  const _MediaBody({this.query = ''});

  @override
  State<_MediaBody> createState() => _MediaBodyState();
}

class _MediaBodyState extends State<_MediaBody> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Merge admin-published media (first) with the channel's real YouTube videos,
  // so new items added in admin AND new uploads both appear and play.
  Future<void> _load() async {
    final results = await Future.wait([
      ContentService.getToolkit('Media'),
      YouTubeService.getVideos(count: 20),
    ]);
    final admin = results[0] as List<Map<String, dynamic>>;
    final videos = results[1] as List<YouTubeVideo>;
    final yt = videos.map((v) => {
      'title': v.title,
      'image_url': v.thumbnailUrl,
      'subtitle': v.channelTitle,
      'link_url': v.videoId,
    }).toList();
    if (mounted) setState(() => _items = [...admin, ...yt]);
  }

  void _openLink(Map<String, dynamic> item) {
    final link = (item['link_url'] as String? ?? '');
    // Accept a full YouTube URL or a bare video id.
    final id = RegExp(r'(?:v=|youtu\.be/|/)([\w-]{11})').firstMatch(link)?.group(1)
        ?? (link.length == 11 ? link : '');
    if (id.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => VideoPlayerScreen(
        video: YouTubeVideo(
          videoId: id,
          title: item['title'] as String? ?? '',
          thumbnailUrl: item['image_url'] as String? ?? '',
          channelTitle: item['subtitle'] as String? ?? '',
          publishedAt: '',
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query.toLowerCase();
    final items = q.isEmpty
        ? _items
        : _items
            ?.where((m) =>
                (m['title'] as String? ?? '').toLowerCase().contains(q) ||
                (m['subtitle'] as String? ?? '').toLowerCase().contains(q))
            .toList();
    if (items != null && items.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: items.length,
        separatorBuilder: (context, i) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => _openLink(item),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 60, height: 47,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.black12,
                  ),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(item['image_url'] as String? ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            Container(color: AppColors.surfaceAlt)),
                    Center(
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE40101), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String? ?? '',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          )),
                      if ((item['subtitle'] as String? ?? '').isNotEmpty)
                        Text(item['subtitle'] as String,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AppColors.textSecondary,
                            )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    // Still loading (nothing fetched yet).
    if (_items == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE40101), strokeWidth: 2),
      );
    }
    // Loaded but empty (or search matched nothing) — show a message, never the
    // built-in static list.
    return Center(
      child: Text(q.isNotEmpty ? 'No results found' : 'No media found',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: AppColors.textMuted)),
    );
  }
}

// ─── SLOGANS BODY ─────────────────────────────────────────────────────────────

class _SlogansBody extends StatelessWidget {
  const _SlogansBody();

  static const _slogans = [
    'பிறப்பொக்கும் எல்லா உயிர்க்கும்!',
    'என் நெஞ்சில் குடியிருக்கும்!',
    'Success is Never Ending!\nFailure is Never Final!',
    'எனக்கு உண்மையா ஒருத்தர நேசிக்க தெரியும்.\nபொய்யா ஒருத்தர வெறுக்க தெரியாது.',
    'Once a Thalapathy fan always a Thalapathy fan.',
    'வெற்றி நம்முடையது!',
    'TVK — மக்களின் கட்சி',
    'தமிழ்நாடு மாறும்!',
    'Change Starts Today!',
    'Vijay வாழ்க TVK!',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          'Best Slogans',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_slogans.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _SloganRow(text: _slogans[i]),
        )),
      ],
    );
  }
}

class _SloganRow extends StatelessWidget {
  final String text;
  const _SloganRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _copy(context, text),
            child: Icon(Icons.copy_rounded,
                size: 20, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── HASHTAGS BODY ────────────────────────────────────────────────────────────

class _HashtagsBody extends StatelessWidget {
  const _HashtagsBody();

  static const _hashtagGroups = [
    '#tvkvijay #thalapathy #thalapathyvijay #tvk #vijay #thalapathytrends #thalapathyfans #mersal #thalapathyforever #tamilactress #tamilbgm #vijayofficial #vijayofficialfans #thuppakki #tamilcinema #tamilsong #jilla #vijayismforever #vijayofficialkerela #thalapathyupdates #actorvijay #kaththi #trending #vijayfans #vijayanna #vijayforever #thalapathi #thalapathyblood #vijaymakkaliyakkam #reels',
    '#thalapathyveriyan #vijayism #tamilstatus #vijayfansclub #dhanush #leodas #goat #tamillyrics #cookwithcomali #thegreatestofalltime #instagramreels #arjundas #likeforlikes #tamilagavettrikazhagam #memes #chennaifoodie #vediomemes #mokkajokes #vijayfansmedia #tamilsongslyrics #viralmemes #bigboss #vijaythalapathy #tamillovesongs #tamilnadu',
    '#tvkvijay #thalapathy #thalapathyvijay #tvk #vijay #thalapathytrends #thalapathyfans #mersal #thalapathyforever #tamilbgm #vijayofficial #thuppakki #tamilcinema #tamilsong #vijayismforever #actorvijay #kaththi #vijayfans #vijayforever #thalapathi #vijaymakkaliyakkam #reels #tamilnadu',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          'Best Hashtags',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_hashtagGroups.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _HashtagBlock(text: _hashtagGroups[i]),
        )),
      ],
    );
  }
}

class _HashtagBlock extends StatelessWidget {
  final String text;
  const _HashtagBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Red "Copy" tab — top-left, rounded top corners
        GestureDetector(
          onTap: () => _copy(context, text),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFE40101),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              'Copy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Text block
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
