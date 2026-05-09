import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShortPlayerScreen extends StatefulWidget {
  final String title;
  final String creator;
  final String duration;
  final String imagePath;

  const ShortPlayerScreen({
    super.key,
    required this.title,
    required this.creator,
    required this.duration,
    required this.imagePath,
  });

  @override
  State<ShortPlayerScreen> createState() => _ShortPlayerScreenState();
}

class _ShortPlayerScreenState extends State<ShortPlayerScreen> {
  bool _playing = true;
  bool _liked = false;
  int _likeCount = 4200;
  bool _showControls = true;

  void _togglePlay() => setState(() => _playing = !_playing);

  void _toggleControls() => setState(() => _showControls = !_showControls);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Full-screen video background (image placeholder)
            Positioned.fill(
              child: Image.asset(widget.imagePath, fit: BoxFit.cover),
            ),
            // Dark overlay
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
            // Top controls
            if (_showControls)
              Positioned(
                top: 16 + topPad,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    GestureDetector(
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
                    const Spacer(),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            // Center play/pause button
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            // Right-side action buttons
            Positioned(
              right: 16,
              bottom: 120 + bottomPad,
              child: Column(
                children: [
                  _ActionBtn(
                    icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: _likeCount > 999 ? '${(_likeCount / 1000).toStringAsFixed(1)}K' : '$_likeCount',
                    color: _liked ? const Color(0xFFE40101) : Colors.white,
                    onTap: () => setState(() {
                      _liked = !_liked;
                      _likeCount += _liked ? 1 : -1;
                    }),
                  ),
                  const SizedBox(height: 24),
                  _ActionBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '312',
                    color: Colors.white,
                    onTap: _showComments,
                  ),
                  const SizedBox(height: 24),
                  _ActionBtn(
                    icon: Icons.repeat_rounded,
                    label: '89',
                    color: Colors.white,
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  _ActionBtn(
                    icon: Icons.ios_share_rounded,
                    label: 'Share',
                    color: Colors.white,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            // Bottom info
            Positioned(
              left: 16,
              right: 80,
              bottom: 40 + bottomPad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE40101), width: 1.5),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF333333), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.creator,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE40101),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Follow', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    widget.title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  Row(
                    children: [
                      _Tag('#TVK'),
                      const SizedBox(width: 6),
                      _Tag('#TamilNadu'),
                      const SizedBox(width: 6),
                      _Tag('#Development'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  _ProgressBar(duration: widget.duration),
                ],
              ),
            ),
          ],
        ),
      ),
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
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Comments (312)', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _ShortComment(author: 'Ravi K', text: 'Inspiring speech! TVK will transform TN.', time: '2h'),
                  _ShortComment(author: 'Priya S', text: 'We need this leadership now!', time: '3h'),
                  _ShortComment(author: 'Murugan', text: 'நம்ம தலைவர் வாழ்க! 🙏', time: '4h'),
                  _ShortComment(author: 'Kavitha', text: 'Shared this with my whole district!', time: '5h'),
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)));
  }
}

class _ProgressBar extends StatelessWidget {
  final String duration;
  const _ProgressBar({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: 0.42,
            minHeight: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE40101)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0:48', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white54)),
            Text(duration, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ],
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
                    Text(author, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
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
