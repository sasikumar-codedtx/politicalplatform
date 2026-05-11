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
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE40101))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(topPad: topPad),
            const SizedBox(height: 16),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = i == _tab;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Container(
                      height: 34,
                      margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFE40101), Color(0x00E40101)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                          color: isActive ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Year timeline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_years.length, (i) {
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFAF36), width: 2),
                            color: i == 0 ? const Color(0xFFFFAF36) : Colors.transparent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _years[i],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Content based on selected tab
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _tab == 0
                    ? List.generate(vm.plans.length, (i) => Padding(
                        padding: EdgeInsets.only(bottom: i < vm.plans.length - 1 ? 16 : 0),
                        child: _PlanCard(plan: vm.plans[i]),
                      ))
                    : _tab == 1
                        ? List.generate(vm.visions.length, (i) => Padding(
                            padding: EdgeInsets.only(bottom: i < vm.visions.length - 1 ? 16 : 0),
                            child: _VisionCard(vision: vm.visions[i]),
                          ))
                        : const [_GoalsCard()],
              ),
            ),
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
          // Manifesto header image
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset('assets/images/manifesto_header.png', fit: BoxFit.cover),
            ),
          ),
          // Gradient: transparent → black
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
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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
                    "TVK's Manifesto",
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

class _PlanCard extends StatelessWidget {
  final ManifestoPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
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
                  // Bottom gradient overlay
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
                  // Title + share icon at bottom
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
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
          // Description
          Text(
            plan.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManifestoDetailScreen(plan: plan, imagePath: plan.imageAsset))),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisionCard extends StatelessWidget {
  final ManifestoVision vision;
  const _VisionCard({required this.vision});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  vision.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vision.targetYear,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFE40101),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vision.description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goals & Achievements',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            'Free laptops/tablets for students.',
            'Modernization of government schools & smart classrooms.',
            'Special scholarships for rural & first-generation learners.',
            'AI & coding labs in district-level schools.',
            'Skill training centers linked with industry jobs.',
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
