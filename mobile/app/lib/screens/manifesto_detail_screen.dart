import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../models/manifesto_plan.dart';

class ManifestoDetailScreen extends StatelessWidget {
  final ManifestoPlan plan;
  const ManifestoDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ──────────────────────────────────────────
            _Hero(imagePath: plan.imageAsset, topPad: topPad),

            // ── White content panel ─────────────────────────────────
            // Title + ministry header (grey bg)
            Container(
              color: AppColors.surfaceAlt,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary, height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.ministry,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, color: AppColors.textPrimary, height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.ios_share_rounded, size: 18, color: AppColors.textPrimary),
                ],
              ),
            ),

            // ── Description ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                plan.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  height: 1.71,
                ),
              ),
            ),

            // ── Milestones section ──────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 14),
              child: _MilestonesHeader(),
            ),

            if (plan.milestones.isNotEmpty)
              _MilestoneTimeline(milestones: plan.milestones)
            else
              _MilestoneTimeline(milestones: _defaultMilestones),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static const _defaultMilestones = [
    ManifestoMilestone(date: 'Phase 1', title: 'Planning & Setup', description: 'Project team formed, objectives defined, initial resource allocation completed.'),
    ManifestoMilestone(date: 'Phase 2', title: 'Implementation Begins', description: 'Field work starts across priority districts with monitoring committees established.'),
    ManifestoMilestone(date: 'Phase 3', title: 'Mid-term Review', description: 'Progress evaluated against targets, adjustments made based on ground feedback.'),
    ManifestoMilestone(date: 'Phase 4', title: 'Completion & Handover', description: 'Project delivered to local bodies with long-term maintenance plans in place.'),
  ];
}

// ─── Hero image with back button ──────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final String imagePath;
  final double topPad;
  const _Hero({required this.imagePath, required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300 + topPad,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
          // Top dark gradient for status bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 82,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.30, 0.92],
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: topPad + 24,
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

// ─── Milestones section header (Timeline + Budget chips) ─────────────────────

class _MilestonesHeader extends StatelessWidget {
  const _MilestonesHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Milestones',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Milestone vertical timeline ──────────────────────────────────────────────

class _MilestoneTimeline extends StatelessWidget {
  final List<ManifestoMilestone> milestones;
  const _MilestoneTimeline({required this.milestones});

  @override
  Widget build(BuildContext context) {
    // Fixed 2-column layout with red vertical line in center
    // Left col (28..~170px): date + BebasNeue title (right-aligned)
    // Center (~186px): vertical red gradient line with dot marker
    // Right col (~221..358px): description text
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(milestones.length, (i) {
          final m = milestones[i];
          final isLast = i == milestones.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: date + title
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, top: 2, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFFFFAF36)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(m.date,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFAF36),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.title.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Center line with dot
                Column(
                  children: [
                    // Top fill before dot
                    Container(
                      width: 3,
                      height: 10,
                      color: i == 0
                          ? const Color(0xFFCA3527).withValues(alpha: 0.0)
                          : const Color(0xFFCA3527),
                    ),
                    // Dot
                    Container(
                      width: 11, height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCA3527), width: 2),
                        color: i == 0 ? const Color(0xFFCA3527) : AppColors.bg,
                      ),
                    ),
                    // Line below dot (or transparent if last)
                    Expanded(
                      child: Container(
                        width: 3,
                        color: isLast ? Colors.transparent : const Color(0xFFCA3527),
                      ),
                    ),
                  ],
                ),
                // Right: description
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2, bottom: 24),
                    child: Text(
                      m.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                        height: 1.42,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
