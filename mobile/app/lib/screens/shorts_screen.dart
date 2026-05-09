import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/short_video.dart';
import '../services/content_service.dart';
import 'short_player_screen.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  List<ShortVideo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final videos = await ContentService.getShorts();
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
          // TVK flag image
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover),
            ),
          ),
          // Gradient: transparent at top → black at bottom
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
          // Back button
          Positioned(
            top: 78 + topPad,
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
            ),
          ),
          // Title block at bottom
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                  ).createShader(bounds),
                  child: Text(
                    'TVK SHORTS',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore our members shorts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
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

class _Grid extends StatelessWidget {
  final List<ShortVideo> videos;
  const _Grid({required this.videos});

  @override
  Widget build(BuildContext context) {
    // 2-column grid: left col at x:16, right col at x:203 → gap = 203-16-171 = 16px
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
  final ShortVideo video;
  const _ShortCard({required this.width, required this.height, required this.video});

  static const _images = [
    'assets/images/event_1.png',
    'assets/images/event_2.png',
    'assets/images/event_3.png',
    'assets/images/event_4.png',
  ];

  @override
  Widget build(BuildContext context) {
    final imagePath = _images[video.id.hashCode.abs() % _images.length];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShortPlayerScreen(
        title: video.title,
        creator: 'TVK Official',
        duration: video.duration,
        imagePath: imagePath,
      ))),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFEEEEEE),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background placeholder
            Container(
              color: const Color(0xFFEEEEEE),
            ),
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
      ),
    );
  }
}
