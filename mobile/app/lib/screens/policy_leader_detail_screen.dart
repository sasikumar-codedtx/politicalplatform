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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Scrollable body ────────────────────────────────────────────
            SingleChildScrollView(
              child: _DetailBody(leader: leader, topPad: topPad),
            ),

            // ── Back button — pinned, frosted glass ─────────────────────────
            Positioned(
              top: topPad + 14,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF242424).withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF242424), size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Full scrollable content ──────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final PolicyLeaderData leader;
  final double topPad;
  const _DetailBody({required this.leader, required this.topPad});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    // Hero section height — enough room for portrait + info
    final heroH = topPad + 300.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero: white bg + glow + portrait + info ─────────────────────────
        SizedBox(
          height: heroH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // White base
              Positioned.fill(child: Container(color: Colors.white)),

              // TVK flag watermark — faint, centred, behind everything
              Positioned(
                left: (sw - 360) / 2,
                top: topPad + 60,
                width: 360,
                height: 199,
                child: Opacity(
                  opacity: 0.10,
                  child: Image.asset(
                    'assets/images/tvk_flag.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // White fade from left — keeps left text legible over flag
              Positioned(
                left: 0,
                top: topPad + 60,
                width: sw * 0.55,
                height: 199,
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

              // Large red/pink radial glow — right side, behind portrait
              Positioned(
                right: -60,
                top: topPad + 20,
                width: sw * 0.85,
                height: heroH - topPad,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.4, -0.2),
                      radius: 0.65,
                      colors: [Color(0x55E87878), Color(0x00E87878)],
                    ),
                  ),
                ),
              ),

              // Secondary bottom glow
              Positioned(
                left: sw * 0.3,
                bottom: 0,
                width: sw * 1.7,
                height: 230,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.5,
                      colors: [Color(0x33F0A0A0), Color(0x00F0A0A0)],
                    ),
                  ),
                ),
              ),

              // Leader portrait — right side, large, slightly overflowing
              Positioned(
                left: sw * 0.18,
                top: topPad + 40,
                right: -sw * 0.05,
                height: heroH - topPad - 20,
                child: Image.asset(
                  leader.imagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, e, s) => Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 180,
                      height: 180,
                      margin: const EdgeInsets.only(right: 20, bottom: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE40101).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(0xFFE40101).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        leader.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 72,
                          color: const Color(0xFFE40101),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Name / quote / years — bottom-left area
              Positioned(
                left: 16,
                bottom: 48,
                width: sw * 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      leader.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF242424),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${leader.role}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF242424),
                        height: 1.5,
                      ),
                    ),
                    if (leader.years != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        leader.years!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF242424).withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Biography card ────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, -7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biography',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF242424),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                leader.biography,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF242424).withValues(alpha: 0.8),
                  height: 22 / 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}
