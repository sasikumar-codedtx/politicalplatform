import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/youtube_video.dart';
import '../services/video_like_service.dart';

class ShortsReelScreen extends StatefulWidget {
  final List<YouTubeVideo> videos;
  final int initialIndex;

  const ShortsReelScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  State<ShortsReelScreen> createState() => _ShortsReelScreenState();
}

class _ShortsReelScreenState extends State<ShortsReelScreen> {
  late YoutubePlayerController _controller;
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<String, bool> _likes = {};
  final Map<String, bool> _errors = {}; // videoId → embed blocked

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = YoutubePlayerController(
      initialVideoId: widget.videos[_currentIndex].videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: false,
        loop: false,
        hideControls: false,
      ),
    );
    _controller.addListener(_onControllerUpdate);
    _pageController = PageController(initialPage: _currentIndex);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadLikeForIndex(_currentIndex);
  }

  void _onControllerUpdate() {
    if (_controller.value.hasError) {
      final videoId = widget.videos[_currentIndex].videoId;
      if (_errors[videoId] != true) {
        if (mounted) setState(() => _errors[videoId] = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _pageController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _loadLikeForIndex(int index) async {
    final videoId = widget.videos[index].videoId;
    if (_likes.containsKey(videoId)) return;
    final liked = await VideoLikeService.isLiked(videoId);
    if (mounted) setState(() => _likes[videoId] = liked);
  }

  void _onPageChanged(int index) {
    _controller.pause();
    setState(() {
      _currentIndex = index;
      _errors.remove(widget.videos[index].videoId);
    });
    _controller.load(widget.videos[index].videoId);
    _loadLikeForIndex(index);
  }

  Future<void> _toggleLike(String videoId) async {
    final next = await VideoLikeService.toggleLike(videoId);
    if (mounted) setState(() => _likes[videoId] = next);
  }

  Future<void> _openInYouTube(String videoId) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Natural 9:16 player height for the screen width.
    final naturalH = screenSize.width * 16 / 9;

    // Scale factor so the player fills the full screen height (cover behaviour).
    final fillScale = screenSize.height / naturalH;

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller,
        aspectRatio: 9 / 16,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE40101),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFE40101),
          handleColor: Color(0xFFE40101),
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ── Vertical swipe PageView ────────────────────────────────
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                onPageChanged: _onPageChanged,
                itemCount: widget.videos.length,
                itemBuilder: (context, index) {
                  final video = widget.videos[index];
                  final isCurrent = index == _currentIndex;
                  final liked = _likes[video.videoId] ?? false;
                  final hasError = _errors[video.videoId] ?? false;
                  return _ReelPage(
                    video: video,
                    player: (isCurrent && !hasError) ? player : null,
                    hasError: hasError,
                    naturalH: naturalH,
                    fillScale: fillScale,
                    screenW: screenSize.width,
                    screenH: screenSize.height,
                    bottomPad: bottomPad,
                    liked: liked,
                    onLike: () => _toggleLike(video.videoId),
                    onOpenYouTube: () => _openInYouTube(video.videoId),
                  );
                },
              ),
              // ── Back button ────────────────────────────────────────────
              Positioned(
                top: topPad + 12,
                left: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Single Reel Page ─────────────────────────────────────────────────────────

class _ReelPage extends StatelessWidget {
  final YouTubeVideo video;
  final Widget? player;
  final bool hasError;

  /// Natural height of the 9:16 player at the device width.
  final double naturalH;

  /// Scale needed to make naturalH fill screenH (cover behaviour).
  final double fillScale;

  final double screenW;
  final double screenH;
  final double bottomPad;
  final bool liked;
  final VoidCallback? onLike;
  final VoidCallback? onOpenYouTube;

  const _ReelPage({
    required this.video,
    required this.player,
    required this.hasError,
    required this.naturalH,
    required this.fillScale,
    required this.screenW,
    required this.screenH,
    required this.bottomPad,
    required this.liked,
    this.onLike,
    this.onOpenYouTube,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenW,
      height: screenH,
      child: Stack(
        children: [
          // ── Full-screen video / thumbnail / error ──────────────────
          Positioned.fill(
            child: ClipRect(
              child: hasError
                  // Error state: thumbnail + "Watch on YouTube" overlay
                  ? _ErrorOverlay(
                      thumbnailUrl: video.thumbnailUrl,
                      onOpenYouTube: onOpenYouTube ?? () {},
                    )
                  : player != null
                      // Scale the 9:16 player up so it covers the full screen
                      // height; ClipRect trims the small side-overflow.
                      ? Transform.scale(
                          scale: fillScale,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: screenW,
                            height: naturalH,
                            child: player!,
                          ),
                        )
                      : Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) =>
                              Container(color: Colors.black87),
                        ),
            ),
          ),

          // ── Bottom gradient ────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 260,
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

          // ── Channel + title (bottom-left) ──────────────────────────
          Positioned(
            bottom: bottomPad + 24,
            left: 16,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '@${video.channelTitle.replaceAll(' ', '')}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Subscribe',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  video.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Right-side actions ─────────────────────────────────────
          Positioned(
            bottom: bottomPad + 24,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: liked ? 'Liked' : 'Like',
                  color: liked ? const Color(0xFFE40101) : Colors.white,
                  onTap: onLike ?? () {},
                ),
                const SizedBox(height: 24),
                _ActionBtn(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  color: Colors.white,
                  onTap: () {},
                ),
                if (hasError) ...[
                  const SizedBox(height: 24),
                  _ActionBtn(
                    icon: Icons.open_in_new_rounded,
                    label: 'YouTube',
                    color: Colors.white70,
                    onTap: onOpenYouTube ?? () {},
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error overlay (embed blocked) ───────────────────────────────────────────

class _ErrorOverlay extends StatelessWidget {
  final String thumbnailUrl;
  final VoidCallback onOpenYouTube;

  const _ErrorOverlay({
    required this.thumbnailUrl,
    required this.onOpenYouTube,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, e, s) => Container(color: Colors.black87),
        ),
        Container(color: Colors.black.withValues(alpha: 0.65)),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 44, color: Colors.white54),
            const SizedBox(height: 10),
            Text(
              'Playback restricted',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This video can only be played on YouTube',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onOpenYouTube,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'Watch on YouTube',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
