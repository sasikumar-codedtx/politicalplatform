import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/news_item.dart';
import '../models/event.dart';
import '../models/short_video.dart';
import '../models/poll.dart';
import '../viewmodels/home_viewmodel.dart';
import 'news_screen.dart';
import 'leader_screen.dart';
import 'manifesto_screen.dart';
import 'chat_list_screen.dart';
import 'events_screen.dart';
import 'polls_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final accent = Color(f.accentColor);
    final bg = Color(f.backgroundColor);

    return Scaffold(
      backgroundColor: bg,
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _HomeAppBar(f: f, primary: primary),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero — leader photo + tagline
                      _HeroSection(f: f, primary: primary),
                      const SizedBox(height: 16),

                      // Latest Updates
                      if (vm.latestNews.isNotEmpty) ...[
                        _SectionHeader(label: 'Latest Updates', primary: primary, onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen()))),
                        _LatestUpdates(news: vm.latestNews, primary: primary),
                        const SizedBox(height: 8),
                      ],

                      // Know your leaders
                      _SectionHeader(label: 'Know your leaders', primary: primary, onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderScreen()))),
                      _LeadersStrip(primary: primary, f: f),
                      const SizedBox(height: 8),

                      // TVK's Manifesto
                      _SectionHeader(label: "TVK's Manifesto", primary: primary, onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManifestoScreen()))),
                      _ManifestoCard(f: f, primary: primary),
                      const SizedBox(height: 8),

                      // Shorts
                      if (vm.shorts.isNotEmpty) ...[
                        _SectionHeader(label: 'Tvk Shorts', primary: primary),
                        _ShortsRow(shorts: vm.shorts, primary: primary),
                        const SizedBox(height: 8),
                      ],

                      // Daily Polls
                      if (vm.dailyPoll != null) ...[
                        _SectionHeader(label: 'Daily Polls', primary: primary, onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen()))),
                        _PollPreview(poll: vm.dailyPoll!, primary: primary, onVote: (id) => context.read<HomeViewModel>().vote(id)),
                        const SizedBox(height: 8),
                      ],

                      // What's Today
                      _SectionHeader(label: "What's Today?", primary: primary),
                      _WhatsTodayCard(primary: primary),
                      const SizedBox(height: 8),

                      // Nearby Events
                      if (vm.upcomingEvents.isNotEmpty) ...[
                        _SectionHeader(label: 'Nearby Events & Rallies', primary: primary, onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()))),
                        _EventsColumn(events: vm.upcomingEvents, primary: primary),
                      ],

                      // Campaign Vault
                      _SectionHeader(label: 'Campaign Vault', primary: primary),
                      _CampaignVault(primary: primary, accent: accent),
                      const SizedBox(height: 8),

                      // AI CM CTA
                      _AiCmBanner(primary: primary, f: f),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── App Bar ────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final FlavorConfig f;
  final Color primary;
  const _HomeAppBar({required this.f, required this.primary});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Color(f.backgroundColor),
      foregroundColor: Colors.white,
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.back_hand_outlined, size: 16, color: primary),
          ),
          const SizedBox(width: 8),
          Text(f.appName, style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: const Icon(Icons.language_outlined, size: 22, color: Colors.white70),
            onPressed: () {},
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 34,
          height: 34,
          decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.15)),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.notifications_outlined, size: 18, color: primary),
            onPressed: () {},
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Color(f.borderColor)),
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final FlavorConfig f;
  final Color primary;
  const _HeroSection({required this.f, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primary, primary.withValues(alpha: 0.85), const Color(0xFFCC0000)],
        ),
      ),
      child: Stack(
        children: [
          // Background Tamil Nadu map shape decoration
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: Icon(Icons.map_outlined, size: 260, color: Colors.white),
            ),
          ),
          // Vijay photo placeholder
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 200,
              height: 280,
              color: Colors.transparent,
              child: Center(
                child: Icon(Icons.person_rounded, size: 160, color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 16,
            top: 20,
            right: 200,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(f.govtName.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
                const SizedBox(height: 12),
                Text(f.leaderName, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                Text(f.leaderTitle, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Text(f.tagline, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(f.taglineEn, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_rounded, color: primary, size: 15),
                        const SizedBox(width: 6),
                        Text('Ask CM', style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
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

// ─── Section Header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color primary;
  final VoidCallback? onViewAll;
  const _SectionHeader({required this.label, required this.primary, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text('See All →', style: GoogleFonts.inter(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ─── Latest Updates ───────────────────────────────────────────────────────────
class _LatestUpdates extends StatelessWidget {
  final List<NewsItem> news;
  final Color primary;
  const _LatestUpdates({required this.news, required this.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: news.length,
        itemBuilder: (context, i) {
          final item = news[i];
          return Container(
            width: 240,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    color: primary.withValues(alpha: 0.12),
                  ),
                  child: Center(child: Icon(Icons.newspaper_rounded, color: primary.withValues(alpha: 0.35), size: 40)),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(item.date, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Leaders Strip ────────────────────────────────────────────────────────────
class _LeadersStrip extends StatelessWidget {
  final Color primary;
  final FlavorConfig f;
  const _LeadersStrip({required this.primary, required this.f});

  @override
  Widget build(BuildContext context) {
    final leaders = [
      (f.leaderName, f.leaderTitle),
      ('K. C. Palanichamy', 'Finance Minister'),
      ('Andimadam Rajaram', 'Agriculture Minister'),
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: leaders.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderScreen())),
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.08),
                      border: Border.all(color: primary.withValues(alpha: 0.2), width: 2),
                    ),
                    child: Icon(Icons.person_rounded, color: primary.withValues(alpha: 0.4), size: 36),
                  ),
                  const SizedBox(height: 6),
                  Text(leaders[i].$1, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(leaders[i].$2, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 9, height: 1.3), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Manifesto Preview Card ───────────────────────────────────────────────────
class _ManifestoCard extends StatelessWidget {
  final FlavorConfig f;
  final Color primary;
  const _ManifestoCard({required this.f, required this.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManifestoScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, primary.withValues(alpha: 0.75)],
          ),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(opacity: 0.12, child: Icon(Icons.gavel_rounded, size: 100, color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TVK's Manifesto", style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Our Plans, Goals & Achievements\nfor Tamil Nadu', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.3)),
                    ],
                  ),
                  Row(
                    children: [
                      ...f.manifestoYears.take(5).map((y) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(y, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      )),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Text('See Details', style: GoogleFonts.inter(color: primary, fontSize: 11, fontWeight: FontWeight.w700)),
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

// ─── Shorts Row ───────────────────────────────────────────────────────────────
class _ShortsRow extends StatelessWidget {
  final List<ShortVideo> shorts;
  final Color primary;
  const _ShortsRow({required this.shorts, required this.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: shorts.length,
        itemBuilder: (context, i) {
          return Container(
            width: 110,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: primary.withValues(alpha: 0.12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Stack(
              children: [
                Center(child: Icon(Icons.play_circle_rounded, color: primary.withValues(alpha: 0.5), size: 36)),
                Positioned(
                  bottom: 8,
                  left: 6,
                  right: 6,
                  child: Text(shorts[i].title, style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Poll Preview ─────────────────────────────────────────────────────────────
class _PollPreview extends StatelessWidget {
  final Poll poll;
  final Color primary;
  final ValueChanged<String> onVote;
  const _PollPreview({required this.poll, required this.primary, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final voted = poll.selectedOptionId != null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll.question, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          ...poll.options.take(3).map((opt) {
            final isSelected = poll.selectedOptionId == opt.id;
            return GestureDetector(
              onTap: voted ? null : () => onVote(opt.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? primary : const Color(0xFF333333)),
                  color: isSelected ? primary.withValues(alpha: 0.12) : const Color(0xFF252525),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isSelected ? primary : const Color(0xFF555555), width: 1.5),
                        color: isSelected ? primary : Colors.transparent,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(opt.text, style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
                  ],
                ),
              ),
            );
          }),
          if (!voted) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text('${poll.totalVotes} responses | 2 Days left', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── What's Today ─────────────────────────────────────────────────────────────
class _WhatsTodayCard extends StatelessWidget {
  final Color primary;
  const _WhatsTodayCard({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TodayItem(text: 'What is the key priority for Tamil Nadu\'s development today?', primary: primary),
          const Divider(height: 20, color: Color(0xFF2A2A2A)),
          _TodayItem(text: 'Share your feedback on the new agriculture scheme.', primary: primary),
          const Divider(height: 20, color: Color(0xFF2A2A2A)),
          _TodayItem(text: 'Rate your local government services this month.', primary: primary),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayItem extends StatelessWidget {
  final String text;
  final Color primary;
  const _TodayItem({required this.text, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10),
          decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
        ),
        Expanded(child: Text(text, style: GoogleFonts.inter(color: const Color(0xFFCCCCCC), fontSize: 13, height: 1.45))),
      ],
    );
  }
}

// ─── Events Column ────────────────────────────────────────────────────────────
class _EventsColumn extends StatelessWidget {
  final List<PartyEvent> events;
  final Color primary;
  const _EventsColumn({required this.events, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.take(3).map((event) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primary.withValues(alpha: 0.1),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Stack(
            children: [
              // Image placeholder
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.05)],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          children: [
                            Text(event.date.split(' ').first, style: GoogleFonts.inter(color: primary, fontSize: 14, fontWeight: FontWeight.w800)),
                            Text(event.date.split(' ').last, style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 9, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white70, size: 11),
                              const SizedBox(width: 3),
                              Expanded(child: Text(event.location, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Campaign Vault ───────────────────────────────────────────────────────────
class _CampaignVault extends StatelessWidget {
  final Color primary;
  final Color accent;
  const _CampaignVault({required this.primary, required this.accent});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.image_outlined, 'Posters'),
      (Icons.videocam_outlined, 'Videos'),
      (Icons.format_quote_rounded, 'Slogans'),
      (Icons.tag_rounded, 'Hashtags'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: items.map((item) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                Icon(item.$1, color: primary, size: 24),
                const SizedBox(height: 6),
                Text(item.$2, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// ─── AI CM Banner ─────────────────────────────────────────────────────────────
class _AiCmBanner extends StatelessWidget {
  final Color primary;
  final FlavorConfig f;
  const _AiCmBanner({required this.primary, required this.f});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, primary.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ask CM ${f.leaderName}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('AI-powered voice assistant in Tamil & English', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
