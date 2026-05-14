import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'policy_leaders_screen.dart';

class PolicyLeaderDetailScreen extends StatelessWidget {
  final PolicyLeaderData leader;
  const PolicyLeaderDetailScreen({super.key, required this.leader});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Scrollable content
            SingleChildScrollView(
              child: _DetailContent(leader: leader, topPad: topPad),
            ),

            // Back button — pinned on top
            Positioned(
              top: topPad + 14,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scrollable detail content ────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  final PolicyLeaderData leader;
  final double topPad;
  const _DetailContent({required this.leader, required this.topPad});

  @override
  Widget build(BuildContext context) {
    final heroHeight = topPad + 360.0;

    return Column(
      children: [
        // ── Hero area (dark) ─────────────────────────────────────────────────
        SizedBox(
          height: heroHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Solid dark base
              Positioned.fill(child: Container(color: const Color(0xFF0D0000))),

              // TVK flag watermark (very faint)
              Positioned(
                right: 0,
                top: topPad + 80,
                width: 340,
                height: 190,
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/images/tvk_flag.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),

              // Red radial glow — upper right
              Positioned(
                right: -60,
                top: topPad + 40,
                width: 280,
                height: 280,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x33E40101), Color(0x00E40101)],
                      radius: 0.55,
                    ),
                  ),
                ),
              ),

              // Leader portrait — right side, aspect-fit
              Positioned(
                right: 0,
                top: topPad + 60,
                width: 260,
                height: 280,
                child: Image.asset(
                  leader.imagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
                ),
              ),

              // Strong bottom gradient so text block is always readable
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0.0, 0.7, 1.0],
                      colors: [
                        Color(0xFF0D0000),
                        Color(0xCC0D0000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Name / role / pill — bottom-left over gradient
              Positioned(
                left: 16,
                right: 140,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Role pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leader.role,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      leader.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Policy Leader',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Biography section (white card) ───────────────────────────────────
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Biography',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF242424),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  leader.biography,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF424242),
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
