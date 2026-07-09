import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
  int _mediaTab = 0; // 0=Audios 1=Videos

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Column(
          children: [
            _Header(
              topPad: topPad,
              type: widget.type,
              mediaTab: _mediaTab,
              onMediaTabChanged: (v) => setState(() => _mediaTab = v),
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
        return _MediaBody(tab: _mediaTab);
      case 'Slogans':
        return _SlogansBody();
      case 'Hashtags':
        return _HashtagsBody();
      default:
        return const _PostersBody();
    }
  }
}

// ─── Shared header ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  final String type;
  final int mediaTab;
  final ValueChanged<int> onMediaTabChanged;

  const _Header({
    required this.topPad,
    required this.type,
    required this.mediaTab,
    required this.onMediaTabChanged,
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
      color: Colors.white,
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

          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDEDEDE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 1.5,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search_rounded,
                      size: 20, color: Color(0xFF888888)),
                  const SizedBox(width: 10),
                  Text(
                    'Search',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF242424).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab row (Media only) ─────────────────────────────────────────
          if (type == 'Media') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEBEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _MediaTabBtn(
                      label: 'Audios', active: mediaTab == 0,
                      onTap: () => onMediaTabChanged(0),
                    ),
                    _MediaTabBtn(
                      label: 'Videos', active: mediaTab == 1,
                      onTap: () => onMediaTabChanged(1),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _MediaTabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MediaTabBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE40101) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? Colors.white : const Color(0xFF242424),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── POSTERS BODY — staggered 2-col masonry grid ──────────────────────────────

class _PostersBody extends StatelessWidget {
  const _PostersBody();

  static const _leftAssets = [
    'assets/images/campaign1.png',
    'assets/images/campaign_2.png',
    'assets/images/campaign1.png',
    'assets/images/campaign_2.png',
  ];
  static const _rightAssets = [
    'assets/images/campaign2.png',
    'assets/images/campaign1.png',
    'assets/images/campaign2.png',
    'assets/images/campaign_2.png',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column — tall cards
            Expanded(
              child: Column(
                children: List.generate(_leftAssets.length, (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < _leftAssets.length - 1 ? 10 : 0),
                  child: _PosterCard(asset: _leftAssets[i], height: 264),
                )),
              ),
            ),
            const SizedBox(width: 10),
            // Right column — alternating shorter/taller
            Expanded(
              child: Column(
                children: List.generate(_rightAssets.length, (i) => Padding(
                  padding: EdgeInsets.only(
                    top: i == 0 ? 90 : 0,
                    bottom: i < _rightAssets.length - 1 ? 10 : 0,
                  ),
                  child: _PosterCard(
                    asset: _rightAssets[i],
                    height: i % 2 == 0 ? 169 : 264,
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
  const _PosterCard({required this.asset, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: height,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => Container(
            color: const Color(0xFFEEEEEE),
          ),
        ),
      ),
    );
  }
}

// ─── MEDIA BODY — Audios list + Videos list ───────────────────────────────────

class _MediaBody extends StatelessWidget {
  final int tab;
  const _MediaBody({required this.tab});

  static const _audioItems = [
    ('Unga Vijay maanadu song',    '1.6M views', '8 months ago', 'assets/images/campaign1.png'),
    ('TVK Election Campaign Song', '11M views',  '1 month ago',  'assets/images/campaign2.png'),
    ('TVK : Flag Anthem',          '15M views',  '1 year ago',   'assets/images/campaign_2.png'),
    ('TVK : Ideology Song',        '5.7M views', '1 year ago',   'assets/images/campaign1.png'),
  ];

  static const _videoItems = [
    ('2nd State Conference of TVK', 'TVK Official', 'assets/images/campaign1.png'),
    ('TVK Election Campaign Film',  'TVK Official', 'assets/images/campaign2.png'),
    ('Vijay Maanadu 2025 Highlights','TVK Official', 'assets/images/campaign_2.png'),
    ('TVK Ideology Launch',         'TVK Official', 'assets/images/campaign1.png'),
  ];

  @override
  Widget build(BuildContext context) {
    if (tab == 0) {
      // Audios tab — list view with thumbnail + title + meta
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: _audioItems.length,
        separatorBuilder: (context, i) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final item = _audioItems[i];
          return Row(
            children: [
              // Thumbnail with play button overlay
              Container(
                width: 60, height: 47,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.black12,
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(item.$4, fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            Container(color: const Color(0xFFDDDDDD))),
                    Center(
                      child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE40101),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: const Color(0xFF1B1409),
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(item.$2,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, color: const Color(0xFF525252))),
                        const SizedBox(width: 6),
                        Container(
                          width: 4, height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF525252), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(item.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: const Color(0xFF525252))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert_rounded,
                  size: 20, color: Color(0xFF888888)),
            ],
          );
        },
      );
    } else {
      // Videos tab — full-width 180px video cards
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: _videoItems.length,
        separatorBuilder: (context, i) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final item = _videoItems[i];
          return _VideoCard(title: item.$1, channel: item.$2, asset: item.$3);
        },
      );
    }
  }
}

class _VideoCard extends StatelessWidget {
  final String title;
  final String channel;
  final String asset;
  const _VideoCard(
      {required this.title, required this.channel, required this.asset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(color: const Color(0xFFDDDDDD))),
            // Bottom gradient
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: 180,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.0, 0.85],
                  ),
                ),
              ),
            ),
            // Play button
            Center(
              child: Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE40101),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
            // Title bottom-left
            Positioned(
              left: 16, right: 16, bottom: 13,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SLOGANS BODY ─────────────────────────────────────────────────────────────

class _SlogansBody extends StatelessWidget {
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
            color: const Color(0xFF242424),
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
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: const Color(0xFFDEDEDE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: const Color(0xFF242424),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: text)),
            child: const Icon(Icons.copy_rounded,
                size: 20, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ─── HASHTAGS BODY ────────────────────────────────────────────────────────────

class _HashtagsBody extends StatelessWidget {
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
            color: const Color(0xFF242424),
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
          onTap: () => Clipboard.setData(ClipboardData(text: text)),
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
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            border: Border.all(color: const Color(0xFFDEDEDE)),
          ),
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, height: 1.5,
              color: const Color(0xFF242424),
            ),
          ),
        ),
      ],
    );
  }
}
