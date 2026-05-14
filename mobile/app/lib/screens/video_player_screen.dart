import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/youtube_video.dart';
import '../services/video_like_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final YouTubeVideo video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _liked = false;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: false,
        isLive: widget.video.isLive,
      ),
    );
    _controller.addListener(_onControllerUpdate);
    VideoLikeService.isLiked(widget.video.videoId).then((v) {
      if (mounted) setState(() => _liked = v);
    });
  }

  void _onControllerUpdate() {
    if (_controller.value.hasError && !_hasError) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
    if ((_controller.value.isPlaying || _controller.value.isReady) &&
        _isLoading) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final next = await VideoLikeService.toggleLike(widget.video.videoId);
    if (mounted) setState(() => _liked = next);
  }

  Future<void> _openInYouTube() async {
    final uri = Uri.parse(
        'https://www.youtube.com/watch?v=${widget.video.videoId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: !_hasError,
        progressIndicatorColor: const Color(0xFFE40101),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFFE40101),
          handleColor: Color(0xFFE40101),
        ),
      ),
      builder: (context, player) {
        final topPad = MediaQuery.of(context).padding.top;
        final bottomPad = MediaQuery.of(context).padding.bottom;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Container(
                color: Colors.black,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12 + topPad,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.video.isLive ? '🔴  LIVE' : 'Now Playing',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.video.isLive
                              ? const Color(0xFFE40101)
                              : Colors.white70,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(
                        Icons.ios_share_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // Player or error fallback
              if (_hasError)
                _EmbedBlockedFallback(
                  video: widget.video,
                  onOpenYouTube: _openInYouTube,
                )
              else
                Stack(
                  children: [
                    player,
                    if (_isLoading && !_hasError)
                      Positioned.fill(
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE40101),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              // Title + channel + actions
              Expanded(
                child: Container(
                  color: const Color(0xFF0D0D0D),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE40101),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                'TVK',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.video.channelTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const Spacer(),
                          if (widget.video.formattedDate.isNotEmpty)
                            Text(
                              widget.video.formattedDate,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _ActionBtn(
                            icon: _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: _liked ? 'Liked' : 'Like',
                            color: _liked
                                ? const Color(0xFFE40101)
                                : Colors.white54,
                            onTap: _toggleLike,
                          ),
                          const SizedBox(width: 24),
                          _ActionBtn(
                            icon: Icons.ios_share_rounded,
                            label: 'Share',
                            color: Colors.white54,
                            onTap: () {},
                          ),
                          if (_hasError) ...[
                            const Spacer(),
                            _ActionBtn(
                              icon: Icons.open_in_new_rounded,
                              label: 'YouTube',
                              color: Colors.white70,
                              onTap: _openInYouTube,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: bottomPad),
            ],
          ),
        );
      },
    );
  }
}

// ─── Embed-blocked fallback ───────────────────────────────────────────────────

class _EmbedBlockedFallback extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback onOpenYouTube;

  const _EmbedBlockedFallback({
    required this.video,
    required this.onOpenYouTube,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SizedBox(
      width: w,
      height: w * 9 / 16,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          Image.network(
            video.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, e, s) => Container(color: const Color(0xFF1A1A1A)),
          ),
          // Dark overlay
          Container(color: Colors.black.withValues(alpha: 0.72)),
          // Message + button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_outline_rounded,
                  size: 48, color: Colors.white54),
              const SizedBox(height: 10),
              Text(
                'Playback restricted on this app',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
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
                          color: Colors.white, size: 16),
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
      ),
    );
  }
}

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
