import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/news_item.dart';
import '../models/event.dart';
import '../models/short_video.dart';
import '../models/poll.dart';
import '../models/youtube_video.dart';
import '../viewmodels/home_viewmodel.dart';
import '../services/youtube_service.dart';
import 'news_screen.dart';
import 'leader_screen.dart';
import 'manifesto_screen.dart';
import 'chat_list_screen.dart';
import 'events_screen.dart';
import 'polls_screen.dart';
import 'profile_screen.dart';
import 'fan_page_screen.dart';
import 'video_player_screen.dart';
import 'youtube_hub_screen.dart';
import 'shorts_reel_screen.dart';

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

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _liveBannerShown = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    // Show the live popup once, as soon as liveBanner arrives.
    if (vm.liveBanner != null && !_liveBannerShown) {
      _liveBannerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLiveBanner(context, vm.liveBanner!);
      });
    }

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
            // Campaign Toolkit
            const _SectionHeader(label: 'Campaign Toolkit'),
            const SizedBox(height: 12),
            const _CampaignToolkitRow(),
            const SizedBox(height: 20),
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
            // TVK Shorts — horizontal row from YouTube
            _SectionHeader(
              label: 'TVK Shorts',
              onMore: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const YoutubeHubScreen(initialTab: 2),
              )),
            ),
            const SizedBox(height: 12),
            if (vm.recentShorts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ShortsRow(shorts: vm.shorts),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vm.recentShorts.length,
                  itemBuilder: (context, index) => _YTShortCard(
                    video: vm.recentShorts[index],
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ShortsReelScreen(
                        videos: vm.recentShorts,
                        initialIndex: index,
                      ),
                    )),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // TVK Television
            const _SectionHeader(label: 'TVK Television'),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TVKTVCard(),
            ),
            const SizedBox(height: 20),
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
            // Social Justice
            const _SocialJusticeSection(),
            const SizedBox(height: 20),
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
            // TVK Videos
            _SectionHeader(
              label: 'TVK Videos',
              onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
            ),
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

// ─── Live banner popup ────────────────────────────────────────────────────────

void _showLiveBanner(BuildContext context, YouTubeVideo video) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => _LiveBannerDialog(video: video),
  );
}

class _LiveBannerDialog extends StatelessWidget {
  final YouTubeVideo video;
  const _LiveBannerDialog({required this.video});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Thumbnail with LIVE badge ──────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => Container(
                      color: const Color(0xFF1A0000),
                      child: const Icon(Icons.live_tv_rounded, color: Colors.white38, size: 48),
                    ),
                  ),
                ),
                // Dark overlay
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
                // LIVE badge top-left
                Positioned(
                  top: 12,
                  left: 12,
                  child: _PulsingLiveBadge(),
                ),
                // Close button top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                // Play icon center
                const Center(
                  child: Icon(Icons.play_circle_filled_rounded, size: 56, color: Colors.white70),
                ),
              ],
            ),
            // ── Info + actions ─────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Stream',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE40101),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.channelTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Watch Now button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(video: video),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE40101),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Watch Live Now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Skip button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
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

class _PulsingLiveBadge extends StatefulWidget {
  @override
  State<_PulsingLiveBadge> createState() => _PulsingLiveBadgeState();
}

class _PulsingLiveBadgeState extends State<_PulsingLiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE40101),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'LIVE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
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
      height: 700 + topPad,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(color: const Color(0xFFF5F5F5)),
          Positioned(
            left: -88,
            top: -170,
            child: Container(
              width: 565,
              height: 770,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFFFE4BA),
                    Color(0xFFFFF4E0),
                    Color(0x00FFF4E0),
                  ],
                  stops: [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: -90,
            top: 251,
            child: Container(
              width: 567,
              height: 162,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFBF5E).withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            left: -71,
            top: 369,
            child: Container(
              width: 701,
              height: 333,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE9501B).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 129 + topPad,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
          Positioned(
            right: -6,
            top: topPad - 12,
            width: 346,
            height: 615,
            child: Image.asset(
              'assets/images/vijay_home_hero.png',
              fit: BoxFit.contain,
              alignment: Alignment.topRight,
              errorBuilder: (ctx, e, s) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            top: 62 + topPad,
            left: 16,
            right: 16,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/tvk_flag.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'TVK',
                  style: GoogleFonts.bebasNeue(
                    color: const Color(0xFF161616),
                    fontSize: 28,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFF1A1A1A), size: 18),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFFE9501B), size: 20),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: topPad + 163,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'தமிழக வெற்றிக் கழகம்',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 42,
                    color: const Color(0xFF151515),
                    height: 1.0,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'பிறப்பொக்கும் எல்லா உயிர்க்கும்',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D5D5D),
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9501B),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE9501B).withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
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
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 403 + topPad,
            child: _JoinTvkCard(),
          ),
          Positioned(
            left: 16,
            top: 351 + topPad,
            child: const _SocialJusticeHeroCard(),
          ),
          Positioned(
            left: 16,
            top: 529 + topPad,
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FanPageScreen())),
              child: const _CommunityWallCard(),
            ),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 171,
        height: 253,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD568), Color(0xFFF7B234)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCC8B17).withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -56,
              left: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 24,
              right: 16,
              height: 200,
              child: Image.asset(
                'assets/images/vijay_hero.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned(
              top: 8,
              left: 27,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Join',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 36,
                      color: const Color(0xFF171717),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TVK',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 54,
                      color: const Color(0xFFE9501B),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9501B),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 170,
        height: 127,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Container(color: const Color(0xFFF6A623)),
            ..._buildTiles(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Community wall',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 30,
                      color: Colors.white,
                      letterSpacing: 0.8,
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

  List<Widget> _buildTiles() {
    const specs = [
      (-34.0, 48.0),
      (-2.0, 24.0),
      (30.0, 0.0),
      (62.0, 22.0),
      (94.0, 48.0),
      (18.0, 78.0),
      (50.0, 54.0),
      (82.0, 78.0),
    ];
    return specs
        .map(
          (s) => Positioned(
            left: s.$1,
            top: s.$2,
            child: Transform.rotate(
              angle: -0.52,
              child: Container(
                width: 66,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

class _SocialJusticeHeroCard extends StatelessWidget {
  const _SocialJusticeHeroCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 158,
      height: 162,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: 16,
            child: _justiceLayer(
              width: 122,
              height: 128,
              image: 'assets/images/highlight1.png',
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: _justiceLayer(
              width: 142,
              height: 148,
              image: 'assets/images/highlight2.png',
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _justiceLayer(
              width: 158,
              height: 162,
              image: 'assets/images/highlight3.png',
              isFront: true,
            ),
          ),
          Positioned(
            left: 3,
            top: 64,
            child: _arrowCircle(icon: Icons.arrow_back_ios_new_rounded),
          ),
          Positioned(
            right: -1,
            top: 64,
            child: _arrowCircle(icon: Icons.arrow_forward_ios_rounded),
          ),
        ],
      ),
    );
  }

  Widget _justiceLayer({
    required double width,
    required double height,
    required String image,
    bool isFront = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFFF0A93C)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF7B2B18).withValues(alpha: 0.55),
                    const Color(0xFF7B2B18).withValues(alpha: 0.78),
                  ],
                  stops: const [0.35, 0.72, 1.0],
                ),
              ),
            ),
            if (isFront)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '01',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 28,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Social Justice',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Promoting social justice for equal, inclusive opportunities.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _arrowCircle({required IconData icon}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 14, color: const Color(0xFF6C6C6C)),
    );
  }
}

// ─── Social Justice Section ───────────────────────────────────────────────────

class _SocialJusticeSection extends StatefulWidget {
  const _SocialJusticeSection();

  @override
  State<_SocialJusticeSection> createState() => _SocialJusticeSectionState();
}

class _SocialJusticeSectionState extends State<_SocialJusticeSection> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  static const _leaders = [
    _LeaderInfo(
      name: 'Vijay',
      role: 'President',
      quote: 'Justice is the foundation of a prosperous Tamil Nadu.',
      photo: 'assets/images/leader_vijay.png',
    ),
    _LeaderInfo(
      name: 'N. Anand',
      role: 'General Secretary',
      quote: 'Every citizen deserves equal opportunity and dignity.',
      photo: 'assets/images/leader_anand.png',
    ),
    _LeaderInfo(
      name: 'K.G. Arunraj',
      role: 'Propaganda & Policy\nGeneral Secretary',
      quote: 'Our voice reaches every corner of Tamil Nadu.',
      photo: 'assets/images/leader_arunraj.png',
    ),
    _LeaderInfo(
      name: 'Aadhav Arjuna',
      role: 'E.C.M General Secretary',
      quote: 'Youth is the driving force of our political change.',
      photo: 'assets/images/leader_aadhav.png',
    ),
    _LeaderInfo(
      name: 'K.A. Sengottaiyan',
      role: 'Senior Leader',
      quote: 'Social justice is not a slogan — it is our commitment.',
      photo: 'assets/images/leader_vijay.png',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _next() {
    if (_currentPage < _leaders.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Social Justice Leaders',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: 0.2,
                ),
              ),
              // Arrow navigation
              Row(
                children: [
                  GestureDetector(
                    onTap: _prev,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _currentPage > 0
                            ? const Color(0xFF9F1D1F)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: _currentPage > 0 ? Colors.white : Colors.black38,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _currentPage < _leaders.length - 1
                            ? const Color(0xFF9F1D1F)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: _currentPage < _leaders.length - 1
                            ? Colors.white
                            : Colors.black38,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card PageView
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _leaders.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final leader = _leaders[index];
                return _SocialJusticeCard(leader: leader);
              },
            ),
          ),
          const SizedBox(height: 10),
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_leaders.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF9F1D1F) : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(50),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SocialJusticeCard extends StatelessWidget {
  final _LeaderInfo leader;
  const _SocialJusticeCard({required this.leader});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B0000), Color(0xFF1A0000)],
          ),
        ),
        child: Stack(
          children: [
            // Faint radial glow
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFCC0000).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Leader photo right side
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              width: 150,
              child: Image.asset(
                leader.photo,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (ctx, e, s) => const SizedBox.shrink(),
              ),
            ),
            // Right-side gradient fade for photo blend
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      const Color(0xFF1A0000).withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content left side
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "SOCIAL JUSTICE" pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE40101).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE40101).withValues(alpha: 0.4), width: 1),
                    ),
                    child: Text(
                      'SOCIAL JUSTICE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF6666),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    leader.name,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 30,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      height: 1.0,
                    ),
                  ),
                  // Role
                  Text(
                    leader.role,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quote
                  SizedBox(
                    width: 180,
                    child: Text(
                      '"${leader.quote}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class _LeaderInfo {
  final String name;
  final String role;
  final String quote;
  final String photo;
  const _LeaderInfo({required this.name, required this.role, required this.quote, required this.photo});
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
    ('Vijay', 'President', 'assets/images/leader_vijay.png'),
    ('N. Anand', 'General Secretary', 'assets/images/leader_anand.png'),
    ('K. G. Arunraj', 'Propaganda & Policy\nGeneral Secretary', 'assets/images/leader_arunraj.png'),
    ('Aadhav Arjuna', 'E.C.M\nGeneral Secretary', 'assets/images/leader_aadhav.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _LeaderCard(name: _leaders[0].$1, role: _leaders[0].$2, photo: _leaders[0].$3)),
          const SizedBox(width: 16),
          Expanded(child: _LeaderCard(name: _leaders[1].$1, role: _leaders[1].$2, photo: _leaders[1].$3)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _LeaderCard(name: _leaders[2].$1, role: _leaders[2].$2, photo: _leaders[2].$3)),
          const SizedBox(width: 16),
          Expanded(child: _LeaderCard(name: _leaders[3].$1, role: _leaders[3].$2, photo: _leaders[3].$3)),
        ]),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final String name;
  final String role;
  final String photo;
  const _LeaderCard({required this.name, required this.role, required this.photo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            // Leader photo — bottom-left, fills lower half
            Positioned(
              left: -12,
              bottom: 0,
              height: 130,
              width: 120,
              child: Image.asset(
                photo,
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
            // Name + role at top-right area
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    role,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
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
            // Leader photo (right side)
            Positioned(
              right: 0,
              bottom: 0,
              width: 130,
              height: 155,
              child: Image.asset(
                'assets/images/vijay_hero.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
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

// ─── YouTube Short Card (horizontal scroll) ───────────────────────────────────

class _YTShortCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback onTap;
  const _YTShortCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) =>
                    Container(color: const Color(0xFFEEEEEE)),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(color: const Color(0xFFEEEEEE)),
              ),
              // Gradient
              Positioned(
                bottom: 0, left: 0, right: 0, height: 70,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
              // Play button
              Center(
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                ),
              ),
              // Title
              Positioned(
                bottom: 6, left: 6, right: 6,
                child: Text(
                  video.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w500,
                    color: Colors.white, height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...poll.options.take(4).map((opt) {
            final isSelected = poll.selectedOptionId == opt.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: voted ? null : () => onVote(opt.id),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF9F1D1F) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected ? null : Border.all(color: const Color(0xFFCCCCCC), width: 1),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5E5D5D),
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
          const SizedBox(height: 8),
          GestureDetector(
            onTap: voted ? null : () {},
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: voted ? const Color(0xFFEEEEEE) : const Color(0xFF9F1D1F),
                borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${poll.totalVotes} responses',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' | ',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF888686)),
                      ),
                      TextSpan(
                        text: '02 Days left',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFFDD2D2D)),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF319C35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Get TVK Badge',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Campaign Toolkit ─────────────────────────────────────────────────────────

class _CampaignToolkitRow extends StatelessWidget {
  const _CampaignToolkitRow();

  static const _items = [
    ('assets/images/campaign1.png', 'Vikravandi Rally\nPoster Pack'),
    ('assets/images/campaign2.png', 'Villupuram\nDeclaration'),
    ('assets/images/vijay_hero.png', 'CM Vijay\nOfficial Photo'),
    ('assets/images/manifesto_banner.png', 'TVK Manifesto\n2026 Edition'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(item.$1, fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(color: const Color(0xFF2A0000))),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE40101),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.ios_share_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Share', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
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
        },
      ),
    );
  }
}

// ─── TVK Television ───────────────────────────────────────────────────────────

class _TVKTVCard extends StatelessWidget {
  const _TVKTVCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 110,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B0000), Color(0xFF2D0000)],
            ),
          ),
          child: Stack(
            children: [
              // Faint flag bg
              Positioned(
                right: -20,
                top: -10,
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset('assets/images/tvk_flag.png', width: 160, fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                      ),
                      child: const Icon(Icons.tv_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'TVK Television',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 22,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Speeches, rallies & party broadcasts',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Watch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _LiveStreamCard extends StatefulWidget {
  const _LiveStreamCard();

  @override
  State<_LiveStreamCard> createState() => _LiveStreamCardState();
}

class _LiveStreamCardState extends State<_LiveStreamCard> {
  YouTubeVideo? _liveVideo;
  YouTubeVideo? _upcomingVideo;
  YouTubeVideo? _recentVideo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLive();
  }

  Future<void> _checkLive() async {
    final live = await YouTubeService.getLiveStream();
    final upcoming = live == null ? await YouTubeService.getUpcomingLive() : null;
    final recent = live == null
        ? await YouTubeService.getVideos(count: 1).then((v) => v.isNotEmpty ? v.first : null)
        : null;
    if (mounted) setState(() { _liveVideo = live; _upcomingVideo = upcoming; _recentVideo = recent; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 130,
          color: const Color(0xFFF0F0F0),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE40101))),
        ),
      );
    }

    // Channel is LIVE
    if (_liveVideo != null) {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: _liveVideo!))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Real thumbnail as background
                Image.network(_liveVideo!.thumbnailUrl, fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF440000), Color(0xFF1A0000)]),
                      ),
                    )),
                // Dark overlay
                Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45))),
                // LIVE badge
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE40101), borderRadius: BorderRadius.circular(4)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                    ]),
                  ),
                ),
                // Play button
                const Center(child: Icon(Icons.play_circle_filled_rounded, size: 56, color: Colors.white)),
                // Title + Watch button
                Positioned(
                  bottom: 12, left: 12, right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_liveVideo!.title,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFE40101), borderRadius: BorderRadius.circular(6)),
                        child: Text('Watch Live', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Upcoming live
    if (_upcomingVideo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFE40101).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.live_tv_rounded, color: Color(0xFFE40101), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upcoming Live', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFE40101), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_upcomingVideo!.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Set a reminder', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black38)),
                  ],
                ),
              ),
              const Icon(Icons.notifications_outlined, color: Color(0xFFE40101), size: 22),
            ],
          ),
        ),
      );
    }

    // No live — show most recent video if available, else placeholder
    if (_recentVideo != null) {
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: _recentVideo!))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(_recentVideo!.thumbnailUrl, fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1A2E), Color(0xFF0D0D0D)]),
                      ),
                    )),
                Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3))),
                const Center(child: Icon(Icons.play_circle_filled_rounded, size: 56, color: Colors.white)),
                Positioned(
                  bottom: 12, left: 12, right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_recentVideo!.title,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE40101), borderRadius: BorderRadius.circular(6)),
                          child: Text('View All', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.live_tv_rounded, color: Colors.black38, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not Live Right Now', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text('Subscribe on YouTube for live notifications', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFE40101), borderRadius: BorderRadius.circular(6)),
              child: Text('View All', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
