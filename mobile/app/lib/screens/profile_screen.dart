import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: const Icon(Icons.settings_outlined, size: 24, color: Colors.black),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.translate_rounded, size: 24, color: Colors.black),
              ],
            ),
          ),
          // ── Scrollable body ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile card ──────────────────────────────────
                  _ProfileCard(phoneNumber: user?.phoneNumber ?? ''),
                  const SizedBox(height: 20),

                  // ── Area's Political Pulse ────────────────────────
                  _SectionTitle(title: "Your Area's Political Pulse"),
                  const SizedBox(height: 12),
                  const _AreaPulseCard(),
                  const SizedBox(height: 20),

                  // ── Local TVK Members ─────────────────────────────
                  _SectionTitle(title: 'Your Local TVK Members'),
                  const SizedBox(height: 12),
                  const _MemberCard(
                    name: 'Mr. Ramesh',
                    role: 'Youth Wing Coordinator',
                    ward: 'Ward -14',
                    activeSince: '2024',
                    lastMeet: 'Last Meet 04- Jun 2025',
                    imagePath: 'assets/images/leader_vijay.png',
                  ),
                  const SizedBox(height: 12),
                  const _MemberCard(
                    name: 'Ms. Kavitha',
                    role: 'Ward In-Charge',
                    ward: 'Ward -14',
                    activeSince: '2024',
                    lastMeet: 'Last Meet 24- Jun 2025',
                    imagePath: 'assets/images/leader_anand.png',
                  ),
                  const SizedBox(height: 20),

                  // ── About TVK ─────────────────────────────────────
                  _SectionTitle(title: 'About TVK'),
                  const SizedBox(height: 12),
                  const _AboutTvkCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String phoneNumber;
  const _ProfileCard({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
      ),
      child: Column(
        children: [
          // Avatar + name + location
          Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 51,
                    backgroundColor: const Color(0xFFEEEEEE),
                    child: const Icon(Icons.person_rounded, size: 48, color: Color(0xFF9F1D1F)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF4A4949)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Member',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                phoneNumber.isNotEmpty ? phoneNumber : 'Chennai, Tamil Nadu.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A4949),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(label: 'Volunteer since 2024', color: const Color(0xFF4CAE4F)),
              _StatusPill(
                label: 'Earned 20 TVK Badges',
                color: const Color(0xFF093492),
                icon: Icons.verified_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatBox(
                    value: '26',
                    label: 'Polls\nparticipated',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    value: '02',
                    label: 'Complaints\nsubmitted',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    value: '₹150',
                    label: 'Total Amount\nDonated',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Join as member button
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF9F1D1F),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'Join as member',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _StatusPill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 93),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9F1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Area Pulse Card ──────────────────────────────────────────────────────────

class _AreaPulseCard extends StatelessWidget {
  const _AreaPulseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chennai- Ward 42',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF09416D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.manage_accounts_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '12 Issues resolved this month',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_rounded, size: 36, color: Color(0xFF09416D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('03', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF09416D))),
                            Text('Events\nconducted', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF09416D))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.how_to_vote_rounded, size: 36, color: Color(0xFF09416D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1,148', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF09416D))),
                            Text('Polls turnout\nvotes in May', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF09416D))),
                          ],
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

// ─── Member Card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String ward;
  final String activeSince;
  final String lastMeet;
  final String imagePath;

  const _MemberCard({
    required this.name,
    required this.role,
    required this.ward,
    required this.activeSince,
    required this.lastMeet,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(imagePath, fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: const Color(0xFFEEEEEE), child: const Icon(Icons.person_rounded, color: Color(0xFF9F1D1F)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                    Text(role, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4A4949))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBECFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ward,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3B42C3)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF9F1D1F)),
              const SizedBox(width: 6),
              Text('Active since : $activeSince',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFE68E0C)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lastMeet,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFE68E0C))),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D8D8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_rounded, size: 16, color: Color(0xFF9F1D1F)),
                      const SizedBox(width: 4),
                      Text('View Speech',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF9F1D1F))),
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

// ─── About TVK Card ───────────────────────────────────────────────────────────

class _AboutTvkCard extends StatelessWidget {
  const _AboutTvkCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(4, 4))],
      ),
      child: Column(
        children: [
          // Logo + Tamil name
          Column(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: const Color(0xFF9F1D1F), child: const Icon(Icons.flag_rounded, color: Colors.white))),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'தமிழக வெற்றிக் கழகம்',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
              ),
              const SizedBox(height: 2),
              Text(
                'பிறப்பொக்கும் எல்லா உயிர்க்கும் !',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF4A4949)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info rows
          _InfoRow(label: 'Founded Year', value: '2023'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Leader', value: 'Mr.Vijay'),
          const SizedBox(height: 16),
          // View Journey button
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF9F1D1F)),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'View Journey & Milestones',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9F1D1F),
                  letterSpacing: 0.32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF111111))),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF9F1D1F))),
      ],
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}
