import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
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
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            // ── Scrollable body ────────────────────────────────────────────
            SingleChildScrollView(
              child: _DetailBody(leader: leader, topPad: topPad),
            ),

            // ── Back button — pinned, dark ────────────────────────────────
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
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
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
        // ── Hero: dark bg + red glow + flag + portrait ──────────────────────
        SizedBox(
          height: heroH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Dark base
              Positioned.fill(child: Container(color: const Color(0xFF080808))),

              // TVK flag — clearly visible, blurred behind leader
              Positioned(
                left: 0, right: 0,
                top: topPad,
                bottom: 0,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                  child: Opacity(
                    opacity: 0.38,
                    child: Image.asset(
                      'assets/images/tvk_flag.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Dark red centered radial glow
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.1, 0.0),
                      radius: 0.9,
                      colors: [Color(0xFF6B0000), Color(0x005A0000)],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Top + bottom dark vignette
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xBB080808), Colors.transparent, Color(0xCC080808)],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Leader portrait — right side, large
              Positioned(
                left: sw * 0.2,
                top: topPad + 20,
                right: -sw * 0.04,
                bottom: 0,
                child: Image.asset(
                  leader.imagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, e, s) => Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 180, height: 180,
                      margin: const EdgeInsets.only(right: 20, bottom: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE40101).withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        leader.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.bebasNeue(fontSize: 72, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

              // Left fade for text legibility
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: sw * 0.65,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xE0080808), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Name / role / years — bottom-left
              Positioned(
                left: 16, bottom: 48,
                width: sw * 0.55,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      leader.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: Colors.white, height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leader.role,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7070), height: 1.4,
                      ),
                    ),
                    if (leader.years != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          leader.years!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
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
            color: AppColors.surface,
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                leader.biography,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
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
