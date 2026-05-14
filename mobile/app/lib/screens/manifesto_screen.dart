import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/manifesto_plan.dart';
import '../viewmodels/manifesto_viewmodel.dart';
import 'manifesto_detail_screen.dart';

class ManifestoScreen extends StatelessWidget {
  const ManifestoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManifestoViewModel()..load(),
      child: const _ManifestoView(),
    );
  }
}

class _ManifestoView extends StatefulWidget {
  const _ManifestoView();
  @override
  State<_ManifestoView> createState() => _ManifestoViewState();
}

class _ManifestoViewState extends State<_ManifestoView> {
  int _tab = 0;
  static const _tabs = ['5-Year Plans', 'Visions', 'Goals & Achievements'];
  static const _years = ['2026', '2027', '2028', '2029', '2030'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManifestoViewModel>();
    final topPad = MediaQuery.of(context).padding.top;

    if (vm.loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE40101))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ────────────────────────────────────────
            _Header(topPad: topPad),

            // ── Segmented tab bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEBEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final active = i == _tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFE40101) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _tabs[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                              color: active ? Colors.white : const Color(0xFF242424),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // ── Year timeline (only on 5-Year Plans) ──────────────
            if (_tab == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _YearTimeline(years: _years),
              ),

            // ── Tab content ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _tab == 0
                  ? Column(
                      children: List.generate(vm.plans.length, (i) => Padding(
                        padding: EdgeInsets.only(bottom: i < vm.plans.length - 1 ? 16 : 0),
                        child: _PlanCard(plan: vm.plans[i]),
                      )),
                    )
                  : _tab == 1
                      ? const _VisionsTab()
                      : const _GoalsTab(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216 + topPad,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/manifesto_header.png', fit: BoxFit.cover),
          ),
          // Top gradient (dark → transparent) for status bar readability
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 82,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),
          // Bottom gradient (transparent → black)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 170,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.16, 1.0],
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: topPad + 24,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
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
          // Title
          Positioned(
            bottom: 16,
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
                    "TVK's MANIFESTO",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our plans, goals & achievements for Tamil Nadu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.3,
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

// ─── Year timeline ─────────────────────────────────────────────────────────────

class _YearTimeline extends StatelessWidget {
  final List<String> years;
  const _YearTimeline({required this.years});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(years.length, (i) {
        return Expanded(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Connecting line (hidden for last item)
                  if (i < years.length - 1)
                    Positioned(
                      left: 10,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFAF36),
                              const Color(0xFFFFAF36).withValues(alpha: i == years.length - 2 ? 0.0 : 1.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Dot
                  Container(
                    width: i == 0 ? 20 : 13,
                    height: i == 0 ? 20 : 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? const Color(0xFFFFAF36) : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFFFFAF36),
                        width: 2,
                      ),
                    ),
                    child: i == 0
                        ? null
                        : Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFAF36),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                years[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                  color: const Color(0xFF242424),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final ManifestoPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8.5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with title overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 89,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(plan.imageAsset, fit: BoxFit.cover),
                  ),
                  // Bottom gradient
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 53,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.16, 1.0],
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                  // Title + share at bottom
                  Positioned(
                    left: 10, right: 10, bottom: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.ios_share_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Description — Poppins per Figma
          Text(
            plan.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF242424).withValues(alpha: 0.8),
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Timeline + Budget chips
          Row(
            children: [
              _InfoChip(label: 'Timeline', value: plan.timeline),
              const SizedBox(width: 16),
              Expanded(child: _InfoChip(label: 'Budget', value: plan.budget, expand: true)),
            ],
          ),
          const SizedBox(height: 12),
          // See Details button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ManifestoDetailScreen(plan: plan)),
            ),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                'See Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool expand;
  const _InfoChip({required this.label, required this.value, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEDEDE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF242424).withValues(alpha: 0.8), height: 1.4)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF242424), height: 1.4)),
        ],
      ),
    );
    return expand ? IntrinsicWidth(stepWidth: double.infinity, child: child) : child;
  }
}

// ─── Visions tab ───────────────────────────────────────────────────────────────

class _VisionsTab extends StatefulWidget {
  const _VisionsTab();
  @override
  State<_VisionsTab> createState() => _VisionsTabState();
}

class _VisionsTabState extends State<_VisionsTab> {
  int _selected = 0;

  static const _menuItems = ['Our policies', 'Our Purpose', 'Our basic principle'];

  static const _content = [
    [
      _VisionItem('Social justice', 'We promote social justice principles to ensure equality for all social groups and to create equal opportunities for all without discrimination.'),
      _VisionItem('Technological development', 'We want to use modern technologies in public welfare work, simplify political processes, and improve public service.'),
      _VisionItem('Opportunity for the younger generation', 'We promote social justice principles to ensure equality for all social groups and to create equal opportunities for all without discrimination.'),
    ],
    [
      _VisionItem('Inclusive governance', 'TVK believes every Tamil deserves a voice in decisions that affect their lives. Our governance model ensures participatory democracy at the grassroots.'),
      _VisionItem('Transparent administration', 'We will digitize public services and make government spending publicly visible so every citizen can track how funds are used.'),
      _VisionItem('People-first policies', 'Every policy decision will be measured by its impact on the most vulnerable — farmers, women, youth, and daily wage workers.'),
    ],
    [
      _VisionItem('Democratic values', 'TVK stands firmly for constitutional democracy, federalism, and the rights guaranteed under the Indian Constitution to every citizen.'),
      _VisionItem('Tamil identity & culture', 'We will protect and promote Tamil language, arts, and heritage as a core pillar of our governance and cultural policy.'),
      _VisionItem('Non-violence & peace', 'TVK promotes non-violent political engagement and dialogue as the foundation of all party activities and public interactions.'),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Portrait + menu area
        SizedBox(
          height: 420,
          child: Stack(
            children: [
              // Red ellipse glow
              Positioned(
                right: -40, top: 140,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE40101).withValues(alpha: 0.15),
                  ),
                ),
              ),
              // Side menu
              Positioned(
                left: 0, top: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_menuItems.length, (i) {
                    final active = i == _selected;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: active
                              ? const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [Color(0xFFE40101), Color(0x00E40101)],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _menuItems[i],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                            color: active ? Colors.white : const Color(0xFF242424),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Vijay portrait
              Positioned(
                right: -10, top: 0, bottom: 0,
                child: Image.asset(
                  'assets/images/tvk_vijay_thalaiva_1.png',
                  width: 260,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ],
          ),
        ),
        // Content card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_content[_selected].length, (i) {
              final item = _content[_selected][i];
              return Padding(
                padding: EdgeInsets.only(bottom: i < _content[_selected].length - 1 ? 16 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF242424),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(item.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF242424).withValues(alpha: 0.8),
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _VisionItem {
  final String title;
  final String description;
  const _VisionItem(this.title, this.description);
}

// ─── Goals & Achievements tab ──────────────────────────────────────────────────

class _GoalsTab extends StatelessWidget {
  const _GoalsTab();

  static const _achievements = [
    _AchievementData('Health Camps Across Tamil Nadu', 'Health', 'Completed: Feb 2025', 'assets/images/event_1.png'),
    _AchievementData('Solar Panels for Rural Schools', 'Education', 'Completed: Apr 2025', 'assets/images/event_2.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ongoing Goal ────────────────────────────────────────
        Text('Ongoing Goal',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: const Color(0xFF242424), height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -7))],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular progress
                  SizedBox(
                    width: 82, height: 82,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(82, 82),
                          painter: _CircularProgressPainter(progress: 0.75),
                        ),
                        Text('75%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: const Color(0xFF242424),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Solar Classroom Initiative',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: const Color(0xFF242424), letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Installed solar-powered classrooms in 100 schools, improving digital access for 50,000 students',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: const Color(0xFF242424).withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Chips
              Row(
                children: [
                  _GoalChip(
                    icon: Icons.access_time_rounded,
                    label: 'Jan 2026 – Sep 2026',
                  ),
                  const SizedBox(width: 14),
                  _GoalChip(
                    icon: Icons.currency_rupee_rounded,
                    label: '50 Crore',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text('See Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // ── Achievements ───────────────────────────────────────
        Text('Achievements',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: const Color(0xFF242424), height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: List.generate(_achievements.length, (i) {
            final a = _achievements[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _achievements.length - 1 ? 12 : 0),
              child: _AchievementCard(data: a),
            );
          }),
        ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GoalChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDEDEDE), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: Colors.black54),
          ),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: Colors.black54,
          )),
        ],
      ),
    );
  }
}

class _AchievementData {
  final String title;
  final String category;
  final String subtitle;
  final String imageAsset;
  const _AchievementData(this.title, this.category, this.subtitle, this.imageAsset);
}

class _AchievementCard extends StatelessWidget {
  final _AchievementData data;
  const _AchievementCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 187,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(data.imageAsset, fit: BoxFit.cover),
            ),
            // Bottom gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
              ),
            ),
            // Category pill
            Positioned(
              top: 16, left: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(47),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 14, color: Color(0xFFFFAF36)),
                      const SizedBox(width: 2),
                      Text(data.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Title + arrow
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w500,
                            color: Colors.white, height: 1.4,
                          ),
                        ),
                        Text(data.subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.north_east_rounded, color: Colors.white, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circular progress painter ─────────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  const _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const startAngle = -math.pi / 2;

    // Background track
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFFEEEEEE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..color = const Color(0xFFFFAF36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) => old.progress != progress;
}
