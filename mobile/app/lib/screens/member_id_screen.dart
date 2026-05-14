import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Figma: 1328-9683 — TVK Member ID card result screen

class MemberIdScreen extends StatelessWidget {
  final File? photoFile;
  const MemberIdScreen({super.key, this.photoFile});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Red ellipse glow (Figma: centered radial behind card) ────────
            Positioned(
              top: 120,
              left: -80,
              right: -80,
              child: Container(
                height: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x30E40101), Color(0x00E40101)],
                    radius: 0.55,
                  ),
                ),
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────────
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: topPad + 20,
                left: 20,
                right: 20,
                bottom: 120 + bottomPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // ── "Your id card is Ready!" ─────────────────────────────
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                    ).createShader(bounds),
                    child: Text(
                      'Your id card\nis Ready!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 42,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to the TVK family!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── ID Card — Figma: 194×276, red gradient ───────────────
                  _TvkIdCard(photoFile: photoFile),

                  const SizedBox(height: 32),

                  // ── Member privileges ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member Privileges',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _Privilege(
                            icon: Icons.event_available_rounded,
                            label: 'Priority event registration'),
                        _Privilege(
                            icon: Icons.how_to_vote_rounded,
                            label: 'Voting rights in party elections'),
                        _Privilege(
                            icon: Icons.group_rounded,
                            label: 'Access to exclusive member community'),
                        _Privilege(
                            icon: Icons.receipt_long_rounded,
                            label: 'Direct grievance submission'),
                        _Privilege(
                            icon: Icons.workspace_premium_rounded,
                            label: 'TVK merchandise discounts'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Back button ──────────────────────────────────────────────────
            Positioned(
              top: topPad + 14,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1A1A1A), size: 16),
                ),
              ),
            ),

            // ── Share button ─────────────────────────────────────────────────
            Positioned(
              top: topPad + 14,
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Icon(Icons.ios_share_rounded,
                    color: Color(0xFF1A1A1A), size: 18),
              ),
            ),

            // ── Bottom "Back to Home" button ─────────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + bottomPad,
              child: GestureDetector(
                onTap: () {
                  // Pop all screens until home (main shell)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE40101).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TVK ID Card widget — Figma: 194×276 portrait card ───────────────────────

class _TvkIdCard extends StatelessWidget {
  final File? photoFile;
  const _TvkIdCard({this.photoFile});

  @override
  Widget build(BuildContext context) {
    // Scale card relative to screen width while keeping Figma proportions
    final sw = MediaQuery.of(context).size.width;
    final cardW = sw - 40.0;
    // Figma: 194×276 → aspect ratio ~0.703
    // Make the card a bit taller to fit all info
    final cardH = cardW * 0.85;

    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0000), Color(0xFF5C0000), Color(0xFF1A0000)],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE40101).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background circle decoration
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE40101).withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE40101).withValues(alpha: 0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card header: TVK logo + org name ──────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE40101),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'TVK',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 11,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'தமிழக வெற்றிக் கழகம்',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Official Member Card',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3D0A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Colors.green, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.10)),
                  const SizedBox(height: 14),

                  // ── Photo + info row ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo slot — Figma: 110×110
                      Container(
                        width: 90,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE40101).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: photoFile != null
                              ? Image.file(
                                  photoFile!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.person_rounded,
                                  color: Colors.white38, size: 42),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Info fields
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vijay Prabhakar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(
                                label: 'Member ID',
                                value: 'TVK-2026-00124897'),
                            _InfoRow(
                                label: 'District',
                                value: 'Chennai North'),
                            _InfoRow(
                                label: 'Booth',
                                value: 'Ward 42, Booth 7'),
                            _InfoRow(
                                label: 'Joined',
                                value: 'May 2026'),
                            _InfoRow(
                                label: 'Valid Till',
                                value: 'Dec 2027'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Footer strip ──────────────────────────────────
                  Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.10)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Yellow/red member badge strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFCA00), Color(0xFFE40101)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE MEMBER',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 10,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'tvkvijay.com',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: Colors.white38,
                        ),
                      ),
                    ],
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

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: Colors.white38),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Privilege row ────────────────────────────────────────────────────────────

class _Privilege extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Privilege({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE40101).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFE40101), size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
