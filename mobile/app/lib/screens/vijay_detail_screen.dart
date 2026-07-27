import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../widgets/sticky_header.dart';

class VijayDetailScreen extends StatefulWidget {
  const VijayDetailScreen({super.key});

  @override
  State<VijayDetailScreen> createState() => _VijayDetailScreenState();
}

class _VijayDetailScreenState extends State<VijayDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        // Sticky: the hero scrolls away, the tab bar pins to the top, and each
        // tab's content scrolls beneath it (shared toolkit / forum pattern).
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _VijayHeroSection(topPad: topPad)),
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedTabBar(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w400),
                  indicatorColor: const Color(0xFFE40101),
                  indicatorWeight: 2.5,
                  tabs: const [Tab(text: 'About'), Tab(text: 'Achievements')],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: const [_AboutTab(), _AchievementsTab()],
          ),
        ),
      ),
    );
  }
}

// ─── Hero section ─────────────────────────────────────────────────────────────

class _VijayHeroSection extends StatelessWidget {
  final double topPad;
  const _VijayHeroSection({required this.topPad});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final heroH = topPad + 280.0;

    return SizedBox(
      height: heroH,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Dark base ─────────────────────────────────────────────────────
          Positioned.fill(child: Container(color: const Color(0xFF080808))),

          // ── TVK flag — blurred, clearly visible behind leader ─────────────
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

          // ── Dark red centered radial glow ─────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.15, 0.0),
                  radius: 0.85,
                  colors: [Color(0xFF6B0000), Color(0x005A0000)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Dark vignette edge overlay ────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC080808), Colors.transparent, Color(0xBB080808)],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // ── Vijay portrait — large, right side ───────────────────────────
          Positioned(
            left: sw * 0.25,
            top: topPad + 10,
            right: -sw * 0.04,
            bottom: 0,
            child: Image.asset(
              'assets/images/leader_vijay.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, e, s) => Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 200, height: 200,
                  margin: const EdgeInsets.only(right: 20, bottom: 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE40101).withValues(alpha: 0.15),
                  ),
                  alignment: Alignment.center,
                  child: Text('V',
                    style: GoogleFonts.bebasNeue(fontSize: 80, color: Colors.white)),
                ),
              ),
            ),
          ),

          // ── Left fade so text is readable over portrait ───────────────────
          Positioned(
            left: 0, top: 0, bottom: 0,
            width: sw * 0.65,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xE6080808), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ── Name + title + location ───────────────────────────────────────
          Positioned(
            left: 16, bottom: 40,
            width: sw * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vijay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'President, TVK',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'Perambur, Chennai',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Back button ───────────────────────────────────────────────────
          Positioned(
            top: topPad + 14, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── About tab ────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
          // Info table
          _InfoCard(rows: const [
            _InfoRow(label: 'Full Name',   value: 'Joseph Vijay Chandrasekhar'),
            _InfoRow(label: 'Position',    value: 'President, Tamilaga Vettri Kazhagam'),
            _InfoRow(label: 'Date of Birth', value: '22 June 1974'),
            _InfoRow(label: 'Age',         value: '51 years'),
            _InfoRow(label: 'Place',       value: 'Chennai, Tamil Nadu'),
            _InfoRow(label: 'Education',   value: 'B.A. Visual Communication'),
            _InfoRow(label: 'Constituency', value: '12. Perambur, Chennai'),
          ]),
          const SizedBox(height: 20),

          // Personal Background
          _SectionCard(
            title: 'Personal Background',
            body: 'Joseph Vijay Chandrasekhar, known professionally as Vijay, was '
                'born on 22 June 1974 in Chennai to director S. A. Chandrasekhar '
                'and singer Shoba Chandrasekhar. He grew up in the heart of Chennai '
                'and completed his B.A. in Visual Communication from Loyola College.\n\n'
                'Vijay is married to Sangeetha Sornalingam and has two children, '
                'Jason Sanjay and Divya Saasha. Known for his simplicity and '
                'deep-rooted connection to Tamil culture, he is one of the most '
                'popular public figures in South India.',
          ),
          const SizedBox(height: 16),

          // Career Summary
          _SectionCard(
            title: 'Career Summary',
            body: 'Vijay made his acting debut as a child in Vetri (1984) and his '
                'first lead role in Naalaiya Theerpu (1992). Over three decades he '
                'starred in 68+ films, becoming one of Tamil cinema\'s biggest '
                'superstars. Blockbusters like Ghilli, Pokkiri, Thuppakki, Mersal, '
                'Bigil, and Master cemented his iconic status.\n\n'
                'In 2024, Vijay founded Tamilaga Vettri Kazhagam (TVK), entering '
                'politics with a vision of transparent governance, youth empowerment, '
                'and social justice for Tamil Nadu. The party rapidly grew to become '
                'a major political force, fielding 234 candidates across all Tamil '
                'Nadu constituencies for the 2026 assembly elections.',
          ),
      ],
    );
  }
}

// ─── Achievements tab ─────────────────────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
          // Cinema section
          _AchievementSection(
            imagePath: 'assets/images/campaign1.png',
            sectionTitle: 'Cinema',
            badge: '68+ Films',
            items: const [
              _AchievementItem(
                icon: Icons.movie_outlined,
                title: '68+ Films',
                description: 'Three-decade career spanning 1984–2024, starring in blockbusters across multiple genres.',
              ),
              _AchievementItem(
                icon: Icons.emoji_events_outlined,
                title: 'Kalaimamani Award',
                description: 'Awarded the prestigious Kalaimamani by the Tamil Nadu Government for contribution to Tamil cinema.',
              ),
              _AchievementItem(
                icon: Icons.star_outline_rounded,
                title: 'Thalapathy',
                description: 'Beloved as "Thalapathy" (Commander) by millions of fans — a title earned through decades of dedicated performances.',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Public Service section
          _SectionTitle(title: 'Public Service'),
          const SizedBox(height: 12),
          _AchievementCard(items: const [
            _AchievementItem(
              icon: Icons.volunteer_activism_outlined,
              title: 'COVID Relief',
              description: 'Donated crores for COVID-19 relief efforts, including ventilators, PPE kits, and food for daily-wage workers.',
            ),
            _AchievementItem(
              icon: Icons.school_outlined,
              title: 'Educational Scholarships',
              description: 'Funded thousands of scholarships for students from economically weaker sections through his charitable foundation.',
            ),
            _AchievementItem(
              icon: Icons.local_hospital_outlined,
              title: 'Medical Aid',
              description: 'Provided free medical treatment for hundreds of patients through personal contributions and fundraisers.',
            ),
          ]),
          const SizedBox(height: 20),

          // Historic Events section
          _SectionTitle(title: 'Historic Events'),
          const SizedBox(height: 12),
          _AchievementCard(items: const [
            _AchievementItem(
              icon: Icons.flag_outlined,
              title: 'TVK Founded — 2024',
              description: 'Founded Tamilaga Vettri Kazhagam on 2 February 2024, drawing 100,000+ members within the first month.',
            ),
            _AchievementItem(
              icon: Icons.groups_outlined,
              title: 'Villupuram Rally — 2024',
              description: 'Addressed a historic rally of over 5 lakh party workers, unveiling TVK\'s governance vision for Tamil Nadu.',
            ),
            _AchievementItem(
              icon: Icons.how_to_vote_outlined,
              title: '234 Seats — 2026',
              description: 'TVK fielded candidates in all 234 Tamil Nadu assembly constituencies, marking a full-scale entry into state politics.',
            ),
          ]),
      ],
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: i < rows.length - 1
                  ? Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    row.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;
  const _SectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFE40101),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AchievementItem {
  final IconData icon;
  final String title;
  final String description;
  const _AchievementItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _AchievementSection extends StatelessWidget {
  final String imagePath;
  final String sectionTitle;
  final String badge;
  final List<_AchievementItem> items;
  const _AchievementSection({
    required this.imagePath,
    required this.sectionTitle,
    required this.badge,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image card with overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3D0A0A), Color(0xFF8B1010)],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  left: 14, bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sectionTitle,
                        style: GoogleFonts.bebasNeue(
                          fontSize: 22, color: Colors.white, letterSpacing: 0.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE40101),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AchievementCard(items: items),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final List<_AchievementItem> items;
  const _AchievementCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: i < items.length - 1
                  ? Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 18, color: const Color(0xFFE40101)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
