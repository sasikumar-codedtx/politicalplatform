import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/news_item.dart';
import '../models/event.dart';
import '../models/short_video.dart';
import '../models/poll.dart';
import '../viewmodels/home_viewmodel.dart';
import 'news_screen.dart';
import 'leader_screen.dart';
import 'manifesto_screen.dart';
import 'chat_list_screen.dart';
import 'events_screen.dart';
import 'polls_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    if (vm.loading) {
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
            _HeroArea(),
            const SizedBox(height: 20),
            // Latest Updates
            if (vm.latestNews.isNotEmpty) ...[
              _SectionHeader(
                label: 'Latest Updates',
                onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LatestUpdatesCard(news: vm.latestNews),
              ),
              const SizedBox(height: 20),
            ],
            // Know your leaders
            _SectionHeader(
              label: 'Know your leaders',
              onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderScreen())),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _LeadersGrid(),
            ),
            const SizedBox(height: 20),
            // TVK's Manifesto
            _SectionHeader(
              label: "TVK's Manifesto",
              onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManifestoScreen())),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ManifestoBanner(),
            ),
            const SizedBox(height: 20),
            // TVK Shorts
            if (vm.shorts.isNotEmpty) ...[
              const _SectionHeader(label: 'TVK Shorts'),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ShortsRow(shorts: vm.shorts),
              ),
              const SizedBox(height: 20),
            ],
            // Daily Polls
            if (vm.dailyPoll != null) ...[
              _SectionHeader(
                label: 'Daily Polls',
                onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen())),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PollCard(poll: vm.dailyPoll!, onVote: (id) => context.read<HomeViewModel>().vote(id)),
              ),
              const SizedBox(height: 20),
            ],
            // Nearby Events
            if (vm.upcomingEvents.isNotEmpty) ...[
              _SectionHeader(
                label: 'Nearby Events & Rallies',
                onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EventsList(events: vm.upcomingEvents),
              ),
              const SizedBox(height: 20),
            ],
            // Live Streaming
            const _SectionHeader(label: 'Live Streaming'),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _LiveStreamCard(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 680 + topPad,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dark red gradient background (replaces pure black)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B0000), Color(0xFF2D0000)],
              ),
            ),
          ),
          // Red gradient circle decoration (Ellipse 2389: x:-88 y:-170 w:565 h:770)
          Positioned(
            left: -88,
            top: -170 + topPad,
            child: Container(
              width: 565,
              height: 770,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xBBCC0000), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Leader photo (right side, tall)
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 580 + topPad,
              width: 260,
              child: const Icon(Icons.person_rounded, size: 160, color: Color(0x22FFFFFF)),
            ),
          ),
          // App bar: logo left + icons right (at y:62 from screen top)
          Positioned(
            top: 62 + topPad,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // TVK Logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFE40101), size: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  'TVK',
                  style: GoogleFonts.bebasNeue(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                // Language icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                  ),
                  child: const Icon(Icons.language_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                // User avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE40101).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFFE40101).withValues(alpha: 0.4), width: 1),
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFFE40101), size: 22),
                ),
              ],
            ),
          ),
          // Ask CM button (from hero bottom-left area)
          Positioned(
            left: 16,
            bottom: 280,
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Ask CM',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // JOIN TVK card (x:203 y:403 w:171 h:253)
          Positioned(
            right: 16,
            top: 403 + topPad,
            child: _JoinTvkCard(),
          ),
          // Community Wall card (x:16 y:529 w:170 h:127)
          Positioned(
            left: 16,
            top: 529 + topPad,
            child: const _CommunityWallCard(),
          ),
        ],
      ),
    );
  }
}

class _JoinTvkCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 171,
        height: 253,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            // Semi-circle bg at bottom
            Positioned(
              bottom: -1,
              left: (171 - 142) / 2,
              child: Container(
                width: 142,
                height: 107,
                decoration: const BoxDecoration(
                  color: Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
            ),
            // Leader photo placeholder
            Positioned(
              bottom: 0,
              left: 23,
              child: Container(
                width: 122,
                height: 180,
                alignment: Alignment.bottomCenter,
                child: const Icon(Icons.person_rounded, size: 120, color: Color(0x44FFFFFF)),
              ),
            ),
            // "Join" + "TVK" text at top
            Positioned(
              top: 21,
              left: 27,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Join',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 36,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TVK',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 54,
                      color: const Color(0xFFE40101),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            // "Join Now" button centered at top:72
            Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Join Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityWallCard extends StatelessWidget {
  const _CommunityWallCard();

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFE53935), const Color(0xFFE91E63),
      const Color(0xFF9C27B0), const Color(0xFF3F51B5),
      const Color(0xFF2196F3), const Color(0xFF009688),
      const Color(0xFF4CAF50), const Color(0xFFFF9800),
      const Color(0xFFFF5722), const Color(0xFF795548),
      const Color(0xFF607D8B), const Color(0xFF009688),
    ];

    return Container(
      width: 170,
      height: 127,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Stack(
        children: [
          // Colorful grid background
          Wrap(
            children: List.generate(12, (i) => Container(
              width: 28,
              height: 42,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: colors[i % colors.length].withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0.3)],
              ),
            ),
          ),
          // Text
          const Positioned(
            bottom: 12,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.people_rounded, color: Colors.white, size: 18),
                SizedBox(height: 4),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 8,
            child: Text(
              'Community wall',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback? onMore;
  const _SectionHeader({required this.label, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Text(
                'See More',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE40101),
                  height: 18 / 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Latest Updates ───────────────────────────────────────────────────────────

class _LatestUpdatesCard extends StatefulWidget {
  final List<NewsItem> news;
  const _LatestUpdatesCard({required this.news});

  @override
  State<_LatestUpdatesCard> createState() => _LatestUpdatesCardState();
}

class _LatestUpdatesCardState extends State<_LatestUpdatesCard> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full-width card — 284px, bg with gradient overlay
        GestureDetector(
          onTap: () {},
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: 284,
              child: Stack(
                children: [
                  // Image placeholder (full bleed)
                  Container(color: const Color(0xFF1A1A1A)),
                  const Center(
                    child: Icon(Icons.image_outlined, size: 60, color: Color(0x22FFFFFF)),
                  ),
                  // Gradient overlay at bottom: h:154px transparent → rgba(0,0,0,0.8)
                  const Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: SizedBox(
                      height: 154,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCCFF0000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: SizedBox(
                      height: 154,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Title + description at left:16 top:160
                  Positioned(
                    left: 16,
                    top: 160,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.news[_page].title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.news[_page].summary,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // "See Details" button at left:16 top:234
                  Positioned(
                    left: 16,
                    top: 234,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'See Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.news.length.clamp(0, 4), (i) {
            final isActive = i == _page;
            return GestureDetector(
              onTap: () => setState(() => _page = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: isActive ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE40101) : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Know Your Leaders ────────────────────────────────────────────────────────

class _LeadersGrid extends StatelessWidget {
  const _LeadersGrid();

  static const _leaders = [
    ('Vijay', 'President'),
    ('N. Anand', 'General Secretary'),
    ('K. G. Arunraj', 'Propaganda & Policy\nGeneral Secretary'),
    ('Aadhav Arjuna', 'E.C.M\nGeneral Secretary'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _LeaderCard(name: _leaders[0].$1, role: _leaders[0].$2)),
          const SizedBox(width: 16),
          Expanded(child: _LeaderCard(name: _leaders[1].$1, role: _leaders[1].$2)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _LeaderCard(name: _leaders[2].$1, role: _leaders[2].$2)),
          const SizedBox(width: 16),
          Expanded(child: _LeaderCard(name: _leaders[3].$1, role: _leaders[3].$2)),
        ]),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final String name;
  final String role;
  const _LeaderCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Leader photo placeholder
          Positioned(
            left: -9,
            top: 43,
            child: SizedBox(
              width: 114,
              height: 115,
              child: Icon(Icons.person_rounded, size: 80, color: Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          // Name + role at left:13 top:11
          Positioned(
            left: 13,
            top: 11,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  role,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // Arrow icon at right:15 bottom:17
          const Positioned(
            right: 15,
            bottom: 17,
            child: Icon(Icons.arrow_outward_rounded, size: 20, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }
}

// ─── TVK's Manifesto ─────────────────────────────────────────────────────────

class _ManifestoBanner extends StatelessWidget {
  const _ManifestoBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF880000), Color(0xFF330000)],
          ),
        ),
        child: Stack(
          children: [
            // Leader photo placeholder (right side)
            Positioned(
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: 120,
                height: 150,
                child: Icon(Icons.person_rounded, size: 100, color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                    ).createShader(bounds),
                    child: Text(
                      "TVK'S MANIFESTO",
                      style: GoogleFonts.bebasNeue(
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our plans, goals & achievements\nfor Tamil Nadu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManifestoScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'See Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

// ─── TVK Shorts Row ───────────────────────────────────────────────────────────

class _ShortsRow extends StatelessWidget {
  final List<ShortVideo> shorts;
  const _ShortsRow({required this.shorts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ShortMiniCard(video: shorts.isNotEmpty ? shorts[0] : null)),
        const SizedBox(width: 16),
        Expanded(child: _ShortMiniCard(video: shorts.length > 1 ? shorts[1] : null)),
      ],
    );
  }
}

class _ShortMiniCard extends StatelessWidget {
  final ShortVideo? video;
  const _ShortMiniCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 160,
        color: const Color(0xFFEEEEEE),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Red play button — 42px circle, bg-[#e40101]
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFE40101),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Poll Card ────────────────────────────────────────────────────────────────

class _PollCard extends StatelessWidget {
  final Poll poll;
  final ValueChanged<String> onVote;
  const _PollCard({required this.poll, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final voted = poll.selectedOptionId != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
              letterSpacing: 0.2,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 16),
          ...poll.options.take(4).map((opt) {
            final isSelected = poll.selectedOptionId == opt.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: voted ? null : () => onVote(opt.id),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2665BE) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected ? null : Border.all(color: const Color(0xFF2665BE), width: 1),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          opt.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: voted ? null : () {},
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: voted ? Colors.transparent : const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(6),
                border: voted ? Border.all(color: const Color(0xFFEEEEEE), width: 1) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                'Submit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: voted ? const Color(0xFF1A1A1A) : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${poll.totalVotes} responses | 2 Days left',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black38,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Events List ──────────────────────────────────────────────────────────────

class _EventsList extends StatelessWidget {
  final List<PartyEvent> events;
  const _EventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _EventCard(event: e),
      )).toList(),
    );
  }
}

class _EventCard extends StatelessWidget {
  final PartyEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 100,
        color: Colors.white,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [const Color(0xFFE40101).withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date box
                  Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE40101),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.date.split(',')[0].split(' ')[1],
                          style: GoogleFonts.bebasNeue(fontSize: 22, color: Colors.white),
                        ),
                        Text(
                          event.date.split(' ')[0].substring(0, 3).toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text(
                              event.location,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time_rounded, size: 12, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text(
                              event.time,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ─── Live Stream Card ─────────────────────────────────────────────────────────

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 180,
        color: Colors.white,
        child: Stack(
          children: [
            // Background gradient — dark red, works as a design element
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF440000), Color(0xFF1A0000)],
                ),
              ),
            ),
            // LIVE badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Viewers
            Positioned(
              top: 12,
              right: 12,
              child: Text(
                '2.5k Watching',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            // Play button
            const Center(
              child: Icon(Icons.play_circle_filled_rounded, size: 56, color: Colors.white),
            ),
            // Join Live button
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Join Live',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
