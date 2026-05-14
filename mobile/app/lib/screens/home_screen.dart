import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/news_item.dart';
import '../models/event.dart';
import '../models/poll.dart';
import '../models/youtube_video.dart';
import '../viewmodels/home_viewmodel.dart';
import '../services/youtube_service.dart';
import 'news_screen.dart';
import 'news_detail_screen.dart';
import 'leader_screen.dart';
import 'manifesto_screen.dart';
import 'chat_list_screen.dart';
import 'events_screen.dart';
import 'polls_screen.dart';
import 'profile_screen.dart';
import 'video_player_screen.dart';
import 'youtube_hub_screen.dart';
// ─── Hardcoded campaign song ──────────────────────────────────────────────────
const _kCampaignSongVideoId = 'JHJmFbLeK-Y';
const _kCampaignSongTitle = 'TVK Campaign Song';
const _kCampaignSongThumb =
    'https://i.ytimg.com/vi/JHJmFbLeK-Y/hqdefault.jpg';

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

    if (vm.liveBanner != null && !_liveBannerShown) {
      _liveBannerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLiveBanner(context, vm.liveBanner!);
      });
    }

    if (vm.loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE40101)),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // white status-bar icons on dark hero
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero banner ───────────────────────────────────
              const _HeroSection(),

              // ── 2. Campaign Song — no header, card directly ───────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _CampaignSongCard(),
              ),
              const SizedBox(height: 20),

              // ── 3. Latest Updates ────────────────────────────────
              if (vm.latestNews.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Latest Updates',
                  onMore: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NewsScreen())),
                ),
                const SizedBox(height: 12),
                _LatestUpdatesHScroll(news: vm.latestNews),
                const SizedBox(height: 20),
              ],

              // ── 4. Know Your Leaders ─────────────────────────────
              _SectionHeader(
                label: 'Know your leaders',
                onMore: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LeaderScreen())),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _LeadersGrid(),
              ),
              const SizedBox(height: 20),

              // ── 5. Manifesto — cinematic, no header ───────────────
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ManifestoScreen())),
                child: const _ManifestoCinematic(),
              ),
              const SizedBox(height: 20),

              // ── 6. TVK Shorts ─────────────────────────────────────
              _SectionHeader(
                label: 'Tvk Shorts',
                onMore: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
              ),
              const SizedBox(height: 12),
              const _TvkShortsRow(),
              const SizedBox(height: 20),

              // ── 7. TVK Television ─────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _LiveStreamCard(),
              ),
              const SizedBox(height: 20),

              // ── 8. Daily Polls ────────────────────────────────────
              if (vm.dailyPoll != null) ...[
                _SectionHeader(
                  label: 'Daily Polls',
                  onMore: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PollsScreen())),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _PollsInfoCard(),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionHeader(label: "What's Today?"),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PollCard(
                    poll: vm.dailyPoll!,
                    onVote: (id) => context.read<HomeViewModel>().vote(id),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── 9. Nearby Events & Rallies ────────────────────────
              if (vm.upcomingEvents.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Nearby Events & Rallies',
                  onMore: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EventsScreen())),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EventsList(events: vm.upcomingEvents),
                ),
                const SizedBox(height: 20),
              ],

              // ── 10. Campaign Toolkit ──────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _SectionHeader(label: 'Campaign Toolkit'),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _CampaignToolkitGrid(),
              ),
              const SizedBox(height: 20),

              // ── 11. Live Streaming ────────────────────────────────
              _SectionHeader(
                label: 'Live Streaming',
                onMore: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LiveStreamBanner(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────
// Full-screen dark hero — transparent app bar overlay inside Stack.
// Figma node 1328:4546. All y-coords are absolute from screen top.
// Offset: dy = topPad - 62  (Figma status-bar baseline ≈ 62 px)

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final dy = topPad - 62.0; // device status-bar offset vs Figma baseline

    return SizedBox(
      // Hero ends just below "Join Now" button (Figma y=451) + small buffer
      height: topPad + 410,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. Dark brownish-red base gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D0A0A), Color(0xFF6B1212)],
              ),
            ),
          ),

          // 2. Social leaders background image — blur 3px, 40% opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Image.asset(
                  'assets/images/hero_bg_blur.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // 3. Red ellipses glow (Figma: Ellipse 2 — x=-182, y=0, 794×414)
          Positioned(
            left: -182,
            top: -30,
            child: Container(
              width: 794,
              height: 440,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFCC0808), Color(0x00CC0808)],
                  radius: 0.5,
                ),
              ),
            ),
          ),
          // Ellipse 3 — x=-174, y=207, 411×232
          Positioned(
            left: -174,
            top: 207 + dy,
            child: Container(
              width: 411,
              height: 232,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFE40101), Color(0x00E40101)],
                  radius: 0.6,
                ),
              ),
            ),
          ),

          // 4. Large Vijay (white shirt, pointing up) — Figma x=94, y=-155, 346×615
          Positioned(
            left: 94,
            top: -155 + dy,
            width: 346,
            height: 615,
            child: Image.asset(
              'assets/images/vijay_home_hero.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              errorBuilder: (_, e, s) => const SizedBox.shrink(),
            ),
          ),

          // 5. Wave section background (yellow-left / red-right diagonal)
          //    Figma: Group 1321314829 — x=-28.5, y=281, 439×220.5
          Positioned(
            left: -28.5,
            top: 281 + dy,
            width: 439,
            height: 220.5,
            child: CustomPaint(painter: _HeroWavePainter()),
          ),

          // 6. Small Vijay (red outfit, fist raised) — Figma x=-47, y=167, 232×349
          Positioned(
            left: -47,
            top: 167 + dy,
            width: 232,
            height: 349,
            child: Image.asset(
              'assets/images/vijay_wave.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, e, s) => const SizedBox.shrink(),
            ),
          ),

          // 7. Party name "தமிழக வெற்றிக் கழகம்" — x=17, y=193, 187×58
          Positioned(
            left: 17,
            top: 193 + dy,
            width: 187,
            child: Text(
              'தமிழக வெற்றிக் கழகம்',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.45,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // 8. Subtitle — x=17, y=259
          Positioned(
            left: 17,
            top: 259 + dy,
            child: Text(
              'பிறப்பொக்கும் எல்லா உயிர்க்கும்',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),

          // 9. "Join TVK today!" — x=245, y=379, 180×34
          Positioned(
            left: 245,
            top: 379 + dy,
            width: 180,
            height: 34,
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
                children: const [
                  TextSpan(text: 'Join '),
                  TextSpan(
                    text: 'TVK',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFCA00),
                    ),
                  ),
                  TextSpan(text: ' today!'),
                ],
              ),
            ),
          ),

          // 10. "Join Now →" button — x=245, y=424, 92×27
          Positioned(
            left: 245,
            top: 424 + dy,
            width: 92,
            height: 27,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Join Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE40101),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFFE40101), size: 14),
                  ],
                ),
              ),
            ),
          ),

          // 11. Transparent app bar overlay — always at topPad
          Positioned(
            top: topPad,
            left: 16,
            right: 16,
            height: 40,
            child: _HeroAppBar(),
          ),
        ],
      ),
    );
  }
}

// ─── Wave background painter ──────────────────────────────────────────────────
// Yellow left trapezoid + red right area, matching Figma diagonal separator.

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Yellow area: left trapezoid.  Diagonal runs (225,0)→(58,h).
    final yellow = Path()
      ..moveTo(0, 0)
      ..lineTo(225, 0)
      ..lineTo(58, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(yellow, Paint()..color = const Color(0xFFFFCA00));

    // Red area: right of the diagonal
    final red = Path()
      ..moveTo(225, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(58, size.height)
      ..close();
    canvas.drawPath(red, Paint()..color = const Color(0xFFE40101));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Hero app bar (transparent overlay, white icons) ─────────────────────────

class _HeroAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TVK logo circle — white bg
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/tvk_flag.png',
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => const Icon(Icons.flag_rounded,
                    color: Color(0xFFE40101)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // "TVK connect" text (white on dark)
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TVK',
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),
            Text(
              'connect',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.0,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Language icon — frosted glass circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.language_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        // Profile avatar
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/vijay_home_hero.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                width: 40,
                height: 40,
                color: const Color(0xFFE40101),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
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
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    video.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => Container(
                      color: const Color(0xFF1A0000),
                      child: const Icon(Icons.live_tv_rounded,
                          color: Colors.white38, size: 48),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _PulsingLiveBadge(),
                ),
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
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
                const Center(
                  child: Icon(Icons.play_circle_filled_rounded,
                      size: 56, color: Colors.white70),
                ),
              ],
            ),
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
                        fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
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
                                  color: Colors.white, shape: BoxShape.circle),
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
                  color: Colors.white, shape: BoxShape.circle),
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


// ─── Campaign Song Card ───────────────────────────────────────────────────────
// Figma 1328:9129 — white card, left: pill+title+button, right: tall Vijay photo

class _CampaignSongCard extends StatelessWidget {
  const _CampaignSongCard();

  @override
  Widget build(BuildContext context) {
    final video = const YouTubeVideo(
      videoId: _kCampaignSongVideoId,
      title: _kCampaignSongTitle,
      thumbnailUrl: _kCampaignSongThumb,
      channelTitle: 'TVK Official',
      publishedAt: '',
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 166,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // White background
              Container(color: Colors.white),
              // Right: large Vijay figure
              Positioned(
                right: 0,
                top: -30,
                bottom: -20,
                width: 200,
                child: Image.asset(
                  'assets/images/tvk_vijay_thalaiva_1.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, e, s) => Image.asset(
                    'assets/images/news_update_1.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient so left text area stays white
              Positioned(
                right: 140,
                top: 0,
                bottom: 0,
                width: 80,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.white, Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Left text content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 220, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 New pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFF6B00).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text('New',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF6B00),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TVK\nCampaign Song',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    // Watch Now button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text('Watch Now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ],
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

// ─── Section Header ───────────────────────────────────────────────────────────

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
              fontWeight: FontWeight.w700,
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

// ─── Latest Updates — Full-width PageView with dots ──────────────────────────
// Figma 1328:9138 — single card takes full width, swipeable, dots indicator

class _LatestUpdatesHScroll extends StatefulWidget {
  final List<NewsItem> news;
  const _LatestUpdatesHScroll({required this.news});

  @override
  State<_LatestUpdatesHScroll> createState() => _LatestUpdatesHScrollState();
}

class _LatestUpdatesHScrollState extends State<_LatestUpdatesHScroll> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.news.take(5).toList();
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LatestNewsCard(
                item: items[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NewsDetailScreen(item: items[index])),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE40101)
                    : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(50),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _LatestNewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback onTap;
  const _LatestNewsCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background photo
              Image.asset(
                'assets/images/news_update_1.png',
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8B6914), Color(0xFF3D2800)],
                    ),
                  ),
                ),
              ),
              // Dark gradient from bottom
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.0, 0.55, 1.0],
                    colors: [Colors.black, Color(0x88000000), Colors.transparent],
                  ),
                ),
              ),
              // Text overlay at bottom
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

// ─── Know Your Leaders ────────────────────────────────────────────────────────

class _LeadersGrid extends StatelessWidget {
  const _LeadersGrid();

  static const _leaders = [
    ('Vijay', 'President', 'assets/images/leader_vijay.png'),
    ('N. Anand', 'General Secretary', 'assets/images/leader_anand.png'),
    ('K. G. Arunraj', 'Propaganda & Policy\nGeneral Secretary',
        'assets/images/leader_arunraj.png'),
    ('Aadhav Arjuna', 'E.C.M\nGeneral Secretary',
        'assets/images/leader_aadhav.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: _LeaderCard(
              name: _leaders[0].$1,
              role: _leaders[0].$2,
              photo: _leaders[0].$3,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _LeaderCard(
              name: _leaders[1].$1,
              role: _leaders[1].$2,
              photo: _leaders[1].$3,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _LeaderCard(
              name: _leaders[2].$1,
              role: _leaders[2].$2,
              photo: _leaders[2].$3,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _LeaderCard(
              name: _leaders[3].$1,
              role: _leaders[3].$2,
              photo: _leaders[3].$3,
            ),
          ),
        ]),
      ],
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final String name;
  final String role;
  final String photo;
  const _LeaderCard(
      {required this.name, required this.role, required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LeaderScreen()),
      ),
      child: ClipRRect(
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
              Positioned(
                left: -12,
                bottom: 0,
                height: 130,
                width: 120,
                child: Image.asset(
                  photo,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomLeft,
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
                ),
              ),
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
              const Positioned(
                right: 12,
                bottom: 14,
                child: Icon(Icons.arrow_outward_rounded,
                    size: 18, color: Color(0xFFE40101)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Manifesto Cinematic ──────────────────────────────────────────────────────
// Figma: full-bleed TN map bg + Vijay foreground + "Manifesto" + "See Details"

class _ManifestoCinematic extends StatelessWidget {
  const _ManifestoCinematic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 280,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. TN constituency map — full bleed background
          Positioned.fill(
            child: Image.asset(
              'assets/images/constituency_map.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, e, s) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD9E8F5), Color(0xFFB0C8E0)],
                  ),
                ),
              ),
            ),
          ),
          // 2. Dark overlay so text is readable
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x66000000), Color(0x22000000)],
                ),
              ),
            ),
          ),
          // 3. Vijay in white/red outfit (left-centre)
          Positioned(
            left: -20,
            bottom: 0,
            top: -10,
            width: 240,
            child: Image.asset(
              'assets/images/vijay_manifesto.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomLeft,
              errorBuilder: (_, e, s) => const SizedBox.shrink(),
            ),
          ),
          // 4. "Manifesto" text + "See Details" — right side
          Positioned(
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Manifesto',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_outward_rounded,
                          color: Colors.white, size: 14),
                    ],
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

// ─── TVK Shorts Row ───────────────────────────────────────────────────────────
// Figma 1328:9238 — horizontal scroll of 9:16 portrait cards (154×257)

class _TvkShortsRow extends StatelessWidget {
  const _TvkShortsRow();

  // Hardcoded short thumbnails — will be replaced by live data later
  static const _shorts = [
    ('assets/images/social_justice_1.png', 'TVK Views'),
    ('assets/images/social_justice_2.png', '1M Views'),
    ('assets/images/social_justice_3.png', '2.3M Views'),
    ('assets/images/news_update_1.png', '820K Views'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 257,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _shorts.length,
        itemBuilder: (context, i) {
          final (img, views) = _shorts[i];
          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
            child: Container(
              width: 154,
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(img, fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => Container(
                            color: const Color(0xFF2A0A0A))),
                    // Bottom gradient
                    Positioned(
                      bottom: 0, left: 0, right: 0, height: 80,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // View count
                    Positioned(
                      bottom: 10, left: 10,
                      child: Text(views,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ),
                    // Play icon
                    const Positioned(
                      top: 10, right: 10,
                      child: Icon(Icons.play_circle_outline_rounded,
                          color: Colors.white70, size: 28),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Polls Info Card ─────────────────────────────────────────────────────────
// Figma — Polls section top card: icon + description + "Create Poll" link

class _PollsInfoCard extends StatelessWidget {
  const _PollsInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE40101).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Color(0xFFE40101), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Polls',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    )),
                const SizedBox(height: 2),
                Text(
                  "TVK's Daily Polls Updates. Voice your opinion every day — our choices help shape tomorrow.",
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: Colors.black54, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PollsScreen())),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create Poll',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: const Color(0xFFE40101),
                    )),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_outward_rounded,
                    color: Color(0xFFE40101), size: 14),
              ],
            ),
          ),
        ],
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
                          color: isSelected
                              ? const Color(0xFF9F1D1F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: const Color(0xFFCCCCCC), width: 1),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
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
                color: voted
                    ? const Color(0xFFEEEEEE)
                    : const Color(0xFF9F1D1F),
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
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: ' | ',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: const Color(0xFF888686)),
                      ),
                      TextSpan(
                        text: '02 Days left',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: const Color(0xFFDD2D2D)),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF319C35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Get TVK Badge',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
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

// ─── Campaign Toolkit — Figma pixel-perfect 2×2 grid ─────────────────────────

class _CampaignToolkitGrid extends StatelessWidget {
  const _CampaignToolkitGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ToolkitCard(
                label: 'Posters',
                gradientColors: const [Color(0xFF256CD0), Color(0xFF13376A)],
                thumbAsset: 'assets/images/tvk_vijay_thalaiva_1.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolkitCard(
                label: 'Media',
                gradientColors: const [Color(0xFF8C25D0), Color(0xFF47136A)],
                thumbAsset: 'assets/images/tvk_vijay_thalaiva_2.png',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToolkitCard(
                label: 'Slogans',
                gradientColors: const [Color(0xFFD02555), Color(0xFF6A132C)],
                thumbAsset: 'assets/images/tvk_vijay_thalaiva_1.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToolkitCard(
                label: 'Hashtags',
                gradientColors: const [Color(0xFF25C5D0), Color(0xFF13646A)],
                thumbAsset: 'assets/images/tvk_vijay_thalaiva_2.png',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolkitCard extends StatelessWidget {
  final String label;
  final List<Color> gradientColors;
  final String thumbAsset;
  const _ToolkitCard(
      {required this.label,
      required this.gradientColors,
      required this.thumbAsset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 89,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Label top-left
            Positioned(
              top: 8,
              left: 10,
              width: 70,
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            // 3 rotated poster cards — right side using real TVK artwork
            Positioned(
              right: -16,
              top: 10,
              child: Row(
                children: List.generate(3, (i) {
                  return Transform.translate(
                    offset: Offset(-i * 14.0, 0),
                    child: Transform.rotate(
                      angle: -0.60,
                      child: Container(
                        width: 40,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(-3, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            thumbAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => Container(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                  );
                }).reversed.toList(),
              ),
            ),
            // Arrow icon — bottom-left
            const Positioned(
              left: 10,
              bottom: 8,
              child: Icon(Icons.arrow_outward_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
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
      children: events
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(event: e),
              ))
          .toList(),
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
                  colors: [
                    const Color(0xFFE40101).withValues(alpha: 0.08),
                    Colors.transparent
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
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
                          style: GoogleFonts.bebasNeue(
                              fontSize: 22, color: Colors.white),
                        ),
                        Text(
                          event.date
                              .split(' ')[0]
                              .substring(0, 3)
                              .toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600),
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
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text(event.location,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text(event.time,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12, color: Colors.black54)),
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
    final upcoming =
        live == null ? await YouTubeService.getUpcomingLive() : null;
    final recent = live == null
        ? await YouTubeService.getVideos(count: 1)
            .then((v) => v.isNotEmpty ? v.first : null)
        : null;
    if (mounted) {
      setState(() {
        _liveVideo = live;
        _upcomingVideo = upcoming;
        _recentVideo = recent;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 130,
          color: const Color(0xFFF0F0F0),
          child: const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFE40101))),
        ),
      );
    }

    if (_liveVideo != null) {
      return GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: _liveVideo!))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 180,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(_liveVideo!.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, e, s) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF440000), Color(0xFF1A0000)]),
                        ),
                      )),
              Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45))),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE40101),
                      borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('LIVE',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                  ]),
                ),
              ),
              const Center(
                  child: Icon(Icons.play_circle_filled_rounded,
                      size: 56, color: Colors.white)),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(children: [
                  Expanded(
                      child: Text(_liveVideo!.title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('Watch Live',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
    }

    if (_upcomingVideo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: const Color(0xFFE40101).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.live_tv_rounded,
                  color: Color(0xFFE40101), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upcoming Live',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFFE40101),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_upcomingVideo!.title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('Set a reminder',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.black38)),
                ],
              ),
            ),
            const Icon(Icons.notifications_outlined,
                color: Color(0xFFE40101), size: 22),
          ]),
        ),
      );
    }

    if (_recentVideo != null) {
      return GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: _recentVideo!))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 180,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(_recentVideo!.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, e, s) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1A1A2E), Color(0xFF0D0D0D)]),
                        ),
                      )),
              Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3))),
              const Center(
                  child: Icon(Icons.play_circle_filled_rounded,
                      size: 56, color: Colors.white)),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(children: [
                  Expanded(
                      child: Text(_recentVideo!.title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE40101),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('View All',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
    }

    // Fallback: Figma TVK Television banner (1328:9113)
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF8B0000), Color(0xFFCC0000)],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Wooden table base (bottom-right)
              Positioned(
                right: 60,
                bottom: 0,
                height: 36,
                width: 180,
                child: Image.asset(
                  'assets/images/tv_wooden_table.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, e, s) => const SizedBox.shrink(),
                ),
              ),
              // Flat screen TV
              Positioned(
                right: 8,
                top: 6,
                bottom: 16,
                width: 190,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/tv_flat_screen.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, e, s) => const SizedBox.shrink(),
                    ),
                    // Vijay on screen
                    Positioned(
                      left: 16,
                      top: 6,
                      right: 8,
                      bottom: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.asset(
                          'assets/images/vijay_tv_screenshot.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text content (left)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 200, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TVK TELEVISION',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "CLICK THE \"TV\" CHECK",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "TVK'S ",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          TextSpan(
                            text: 'LATEST NEWS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
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
      ),
    );
  }
}

// ─── Live Streaming Banner ────────────────────────────────────────────────────
// Figma "Live Streaming" section — shows latest live or fallback card

class _LiveStreamBanner extends StatelessWidget {
  const _LiveStreamBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Image.asset(
              'assets/images/news_update_1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF440000), Color(0xFF1A0000)],
                  ),
                ),
              ),
            ),
            // Dark overlay
            Container(color: Colors.black.withValues(alpha: 0.5)),
            // "LIVE" badge top-left
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('LIVE', style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 0.5)),
                ]),
              ),
            ),
            // Viewers badge
            Positioned(
              top: 12, left: 72,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.people_rounded, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text('2.5k Watching', style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
            // Bottom content
            Positioned(
              left: 16, right: 16, bottom: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Venue Inspection for State-Level Political Conference',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white, height: 1.3,
                      ),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const YoutubeHubScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Join Live',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
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
