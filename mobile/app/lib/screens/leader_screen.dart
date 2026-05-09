import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/leader.dart';
import '../models/short_video.dart';
import '../viewmodels/leader_viewmodel.dart';
import 'chat_list_screen.dart';

class LeaderScreen extends StatelessWidget {
  const LeaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeaderViewModel()..load(),
      child: const _LeaderView(),
    );
  }
}

class _LeaderView extends StatelessWidget {
  const _LeaderView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeaderViewModel>();
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final surface = Color(f.surfaceColor);
    final border = Color(f.borderColor);

    if (vm.loading) {
      return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator()));
    }

    final leader = vm.leader;
    if (leader == null) {
      return Scaffold(backgroundColor: bg, body: Center(child: Text('No data', style: GoogleFonts.inter(color: const Color(0xFF999999)))));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bg,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A1A1A),
              expandedHeight: 260,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              flexibleSpace: FlexibleSpaceBar(
                background: _LeaderHero(leader: leader, primary: primary, surface: surface, border: border, onChat: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                }),
                collapseMode: CollapseMode.pin,
              ),
              bottom: TabBar(
                indicatorColor: primary,
                indicatorWeight: 2,
                labelColor: primary,
                unselectedLabelColor: const Color(0xFF999999),
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                dividerColor: border,
                tabs: const [Tab(text: 'About'), Tab(text: 'Milestones'), Tab(text: 'Media')],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _AboutTab(leader: leader, primary: primary, surface: surface, border: border),
              _MilestonesTab(achievements: leader.achievements, primary: primary, surface: surface, border: border),
              _MediaTab(media: vm.media, primary: primary, surface: surface),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderHero extends StatelessWidget {
  final Leader leader;
  final Color primary;
  final Color surface;
  final Color border;
  final VoidCallback onChat;

  const _LeaderHero({required this.leader, required this.primary, required this.surface, required this.border, required this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withValues(alpha: 0.75)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.15),
                  border: Border.all(color: primary.withValues(alpha: 0.4), width: 2),
                ),
                child: Icon(Icons.person_rounded, color: primary, size: 54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(leader.name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(leader.role, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.65), size: 12),
                        const SizedBox(width: 3),
                        Text(leader.location, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onChat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 6),
                            Text('Ask AI', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final Leader leader;
  final Color primary;
  final Color surface;
  final Color border;

  const _AboutTab({required this.leader, required this.primary, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(title: 'Biography', body: leader.bio, primary: primary, surface: surface, border: border),
        const SizedBox(height: 12),
        _InfoCard(title: 'Career', body: leader.careerSummary, primary: primary, surface: surface, border: border),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  final Color primary;
  final Color surface;
  final Color border;

  const _InfoCard({required this.title, required this.body, required this.primary, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

class _MilestonesTab extends StatelessWidget {
  final List<LeaderAchievement> achievements;
  final Color primary;
  final Color surface;
  final Color border;

  const _MilestonesTab({required this.achievements, required this.primary, required this.surface, required this.border});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, i) {
        final a = achievements[i];
        final isLast = i == achievements.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.15),
                      border: Border.all(color: primary.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(a.year.substring(a.year.length > 4 ? 2 : 0), style: GoogleFonts.inter(color: primary, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 1, color: border)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(a.description, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MediaTab extends StatelessWidget {
  final List<ShortVideo> media;
  final Color primary;
  final Color surface;

  const _MediaTab({required this.media, required this.primary, required this.surface});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: media.length,
      itemBuilder: (context, i) {
        final video = media[i];
        return Container(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withValues(alpha: 0.1)),
          ),
          child: Stack(
            children: [
              Center(child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
                child: Icon(Icons.play_arrow_rounded, color: primary, size: 26),
              )),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.white.withValues(alpha: 0.95), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.title, style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontSize: 11, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(video.duration, style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
