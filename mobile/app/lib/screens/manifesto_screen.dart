import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/manifesto_plan.dart';
import '../viewmodels/manifesto_viewmodel.dart';

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

class _ManifestoView extends StatelessWidget {
  const _ManifestoView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ManifestoViewModel>();
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final surface = Color(f.surfaceColor);
    final border = Color(f.borderColor);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bg,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A1A1A),
              floating: true,
              snap: true,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              titleSpacing: 20,
              title: Text('Manifesto', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1A1A1A))),
              bottom: TabBar(
                indicatorColor: primary,
                indicatorWeight: 2,
                labelColor: primary,
                unselectedLabelColor: const Color(0xFF999999),
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                dividerColor: border,
                tabs: const [Tab(text: 'Plans'), Tab(text: 'Vision')],
              ),
            ),
          ],
          body: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _PlansTab(vm: vm, primary: primary, surface: surface, border: border),
                    _VisionTab(visions: vm.visions, primary: primary, surface: surface, border: border),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PlansTab extends StatelessWidget {
  final ManifestoViewModel vm;
  final Color primary;
  final Color surface;
  final Color border;

  const _PlansTab({required this.vm, required this.primary, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    final years = vm.plans.map((p) => p.year).toSet().toList()..sort();

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: years.length,
            itemBuilder: (context, i) {
              final year = years[i];
              final isSelected = vm.selectedYear == year;
              return GestureDetector(
                onTap: () => context.read<ManifestoViewModel>().selectYear(year),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? primary : border),
                  ),
                  child: Text(
                    year,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : const Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: vm.plansForYear.length,
            itemBuilder: (context, i) => _PlanCard(plan: vm.plansForYear[i], primary: primary, surface: surface, border: border),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ManifestoPlan plan;
  final Color primary;
  final Color surface;
  final Color border;

  const _PlanCard({required this.plan, required this.primary, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(plan.category, style: GoogleFonts.inter(color: primary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
              const Spacer(),
              Text(plan.year, style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(plan.title, style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 15, height: 1.3)),
          const SizedBox(height: 6),
          Text(plan.description, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Meta(icon: Icons.calendar_today_outlined, label: plan.timeline),
              const SizedBox(width: 16),
              _Meta(icon: Icons.account_balance_wallet_outlined, label: plan.budget),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF999999), size: 12),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 11)),
      ],
    );
  }
}

class _VisionTab extends StatelessWidget {
  final List<ManifestoVision> visions;
  final Color primary;
  final Color surface;
  final Color border;

  const _VisionTab({required this.visions, required this.primary, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visions.length,
      itemBuilder: (context, i) {
        final vision = visions[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb_outline_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vision.title, style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
                    const SizedBox(height: 5),
                    Text(vision.description, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13, height: 1.5)),
                    const SizedBox(height: 8),
                    Text(vision.targetYear, style: GoogleFonts.inter(color: primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
