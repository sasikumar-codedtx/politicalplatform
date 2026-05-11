import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import 'short_player_screen.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  List<YouTubeVideo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final videos = await YouTubeService.getRecentVideos(count: 12);
    if (mounted) setState(() { _videos = videos; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE40101))),
      );
    }

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(topPad: topPad),
            const SizedBox(height: 16),
            if (_videos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No videos available right now.\nCheck back soon!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, height: 1.6),
                  ),
                ),
              )
            else
              _Grid(videos: _videos),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 234 + topPad,
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                  colors: [Colors.transparent, Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16 + topPad,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 16, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                  ).createShader(bounds),
                  child: Text('TVK VIDEOS', style: GoogleFonts.bebasNeue(fontSize: 34, color: Colors.white, letterSpacing: 0.2)),
                ),
                const SizedBox(height: 4),
                Text('Official TVK Channel — Tamilaga Vettri Kazhagam',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<YouTubeVideo> videos;
  const _Grid({required this.videos});

  @override
  Widget build(BuildContext context) {
    const cardW = 171.0;
    const cardH = 264.0;
    const gap = 16.0;
    final rows = (videos.length / 2).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (row) {
          final leftIdx = row * 2;
          final rightIdx = leftIdx + 1;
          return Padding(
            padding: EdgeInsets.only(bottom: row < rows - 1 ? gap : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShortCard(width: cardW, height: cardH, video: videos[leftIdx]),
                const SizedBox(width: gap),
                if (rightIdx < videos.length)
                  _ShortCard(width: cardW, height: cardH, video: videos[rightIdx])
                else
                  SizedBox(width: cardW, height: cardH),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ShortCard extends StatelessWidget {
  final double width;
  final double height;
  final YouTubeVideo video;
  const _ShortCard({required this.width, required this.height, required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ShortPlayerScreen(video: video),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Real YouTube thumbnail
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(
                  color: const Color(0xFFEEEEEE),
                  child: const Icon(Icons.play_circle_outline_rounded, size: 40, color: Color(0xFFCCCCCC)),
                ),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(color: const Color(0xFFEEEEEE),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE40101)))),
              ),
              // Bottom gradient
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
              // Live badge
              if (video.isLive)
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE40101), borderRadius: BorderRadius.circular(4)),
                    child: Text('LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              // Play button
              Center(
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
              ),
              // Title at bottom
              Positioned(
                bottom: 8, left: 8, right: 8,
                child: Text(
                  video.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3),
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
