import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/youtube_video.dart';

class ShortPlayerScreen extends StatefulWidget {
  final YouTubeVideo video;

  const ShortPlayerScreen({super.key, required this.video});

  @override
  State<ShortPlayerScreen> createState() => _ShortPlayerScreenState();
}

class _ShortPlayerScreenState extends State<ShortPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _liked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
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
            children: [
              // App bar
              Container(
                color: Colors.black,
                padding: EdgeInsets.only(left: 16, right: 16, top: 12 + topPad, bottom: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.video.isLive ? '🔴 LIVE' : 'Now Playing',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.video.isLive ? const Color(0xFFE40101) : Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.ios_share_rounded, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),
              // YouTube player
              player,
              // Video info + actions
              Expanded(
                child: Container(
                  color: const Color(0xFF0D0D0D),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.video.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Channel + date
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE40101),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('TVK', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.video.channelTitle, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                  Text(widget.video.isLive ? 'Live Now' : widget.video.formattedDate, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white54)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE40101),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Subscribe', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Divider
                        Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        // Actions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ActionBtn(
                              icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              label: _likeCount > 0 ? '$_likeCount' : 'Like',
                              color: _liked ? const Color(0xFFE40101) : Colors.white54,
                              onTap: () => setState(() {
                                _liked = !_liked;
                                _likeCount += _liked ? 1 : -1;
                              }),
                            ),
                            _ActionBtn(icon: Icons.chat_bubble_outline_rounded, label: 'Comment', color: Colors.white54, onTap: _showComments),
                            _ActionBtn(icon: Icons.repeat_rounded, label: 'Share', color: Colors.white54, onTap: () {}),
                            _ActionBtn(icon: Icons.download_outlined, label: 'Save', color: Colors.white54, onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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

  void _showComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Comments', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _ShortComment(author: 'Ravi K', text: 'TVK வாழ்க! 🙏', time: '2h'),
                  _ShortComment(author: 'Priya S', text: 'Amazing speech!', time: '3h'),
                  _ShortComment(author: 'Murugan TN', text: 'நம்ம தலைவர் வாழ்க!', time: '4h'),
                  _ShortComment(author: 'Kavitha R', text: 'Sharing with everyone!', time: '5h'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _ShortComment extends StatelessWidget {
  final String author;
  final String text;
  final String time;
  const _ShortComment({required this.author, required this.text, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person_rounded, color: Colors.white38, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('· $time', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white38)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
