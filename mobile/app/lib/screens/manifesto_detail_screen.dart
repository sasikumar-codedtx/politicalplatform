import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/manifesto_plan.dart';

class ManifestoDetailScreen extends StatelessWidget {
  final ManifestoPlan plan;
  final String imagePath;
  const ManifestoDetailScreen({super.key, required this.plan, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image
                  _Hero(imagePath: imagePath, topPad: topPad),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category + year badge row
                        Row(
                          children: [
                            _Badge(label: plan.category, color: const Color(0xFFE40101)),
                            const SizedBox(width: 8),
                            _Badge(label: plan.year, color: const Color(0xFFF0F0F0), textColor: Colors.black54),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Title
                        Text(
                          plan.title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A), height: 1.4, letterSpacing: 0.2),
                        ),
                        const SizedBox(height: 20),
                        // Timeline + Budget chips
                        Row(
                          children: [
                            Expanded(child: _MetaChip(label: 'Timeline', value: plan.timeline)),
                            const SizedBox(width: 12),
                            Expanded(child: _MetaChip(label: 'Budget', value: plan.budget)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Overview
                        Text('Overview', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                        const SizedBox(height: 10),
                        Text(
                          plan.description,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black54, height: 1.7),
                        ),
                        const SizedBox(height: 20),
                        // Progress bar
                        _ProgressSection(plan: plan),
                        const SizedBox(height: 20),
                        // Key goals
                        Text('Key Goals', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        ..._goalsFor(plan).map((goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalItem(text: goal),
                        )),
                        const SizedBox(height: 20),
                        // Impact section
                        Text('Expected Impact', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                        const SizedBox(height: 12),
                        ..._impactFor(plan).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE40101).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.trending_up_rounded, color: Color(0xFFE40101), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(item, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, height: 1.5)),
                                ),
                              ],
                            ),
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom action bar
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + MediaQuery.of(context).padding.bottom, top: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE40101),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text('Support This Plan', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.ios_share_rounded, color: Color(0xFF1A1A1A), size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _goalsFor(ManifestoPlan plan) => [
    'Benefit at least 5 lakh citizens across Tamil Nadu directly.',
    'Complete implementation within the stated timeline with quarterly reviews.',
    'Establish district-level monitoring committees for transparent tracking.',
    'Create sustainable local employment during implementation phase.',
    'Publish monthly progress reports accessible to all citizens.',
  ];

  List<String> _impactFor(ManifestoPlan plan) => [
    'Direct improvement in quality of life for rural communities.',
    'Reduction in government expenditure through efficient resource use.',
    'Increased citizen participation in governance and policy feedback.',
  ];
}

class _Hero extends StatelessWidget {
  final String imagePath;
  final double topPad;
  const _Hero({required this.imagePath, required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260 + topPad,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                  colors: [Colors.transparent, Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16 + topPad,
            left: 16,
            child: GestureDetector(
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
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Badge({required this.label, required this.color, this.textColor = const Color(0xFFE40101)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color == const Color(0xFFE40101) ? color.withValues(alpha: 0.15) : color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black38)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final ManifestoPlan plan;
  const _ProgressSection({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Implementation Progress', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
              Text('34%', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFE40101))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.34,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE40101)),
            ),
          ),
          const SizedBox(height: 8),
          Text('Phase 1 of 3 complete — on track', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black38)),
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final String text;
  const _GoalItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6, height: 6,
          decoration: const BoxDecoration(color: Color(0xFFE40101), shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, height: 1.5))),
      ],
    );
  }
}
