import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/poll_service.dart';
import '../models/poll.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Poll> _polls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final poll = await PollService.getDailyPoll();
    if (mounted) setState(() { _polls = [poll]; _loading = false; });
  }

  Future<void> _vote(String pollId, String optionId) async {
    final updated = await PollService.vote(pollId, optionId);
    if (mounted) setState(() {
      final idx = _polls.indexWhere((p) => p.id == pollId);
      if (idx != -1) _polls[idx] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final border = Color(f.borderColor);
    final surface = Color(f.surfaceColor);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            floating: true,
            snap: true,
            pinned: true,
            elevation: 0,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: _TvkBanner(
                title: "TVK'S POLLS",
                subtitle: "VOICE YOUR OPINION EVERY DAY.\nOUR CHOICES HELP SHAPE TOMORROW.",
                primary: primary,
              ),
              collapseMode: CollapseMode.pin,
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: primary,
              indicatorWeight: 3,
              labelColor: primary,
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
              dividerColor: border,
              tabs: const [Tab(text: 'Active Polls'), Tab(text: 'Inactive Polls'), Tab(text: 'My Polls')],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _PollList(polls: _polls, primary: primary, surface: surface, border: border, onVote: _vote),
                  _PollList(polls: const [], primary: primary, surface: surface, border: border, onVote: _vote),
                  _PollList(polls: const [], primary: primary, surface: surface, border: border, onVote: _vote),
                ],
              ),
    );
  }
}

class _TvkBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primary;
  const _TvkBanner({required this.title, required this.subtitle, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC49A00), Color(0xFF7D1400)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.how_to_vote_rounded, color: Colors.white, size: 34),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              color: primary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PollList extends StatelessWidget {
  final List<Poll> polls;
  final Color primary;
  final Color surface;
  final Color border;
  final Function(String, String) onVote;

  const _PollList({required this.polls, required this.primary, required this.surface, required this.border, required this.onVote});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return Center(child: Text('No polls available', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length,
      itemBuilder: (context, i) => _PollCard(poll: polls[i], primary: primary, surface: surface, border: border, onVote: (optionId) => onVote(polls[i].id, optionId)),
    );
  }
}

class _PollCard extends StatelessWidget {
  final Poll poll;
  final Color primary;
  final Color surface;
  final Color border;
  final ValueChanged<String> onVote;

  const _PollCard({required this.poll, required this.primary, required this.surface, required this.border, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final voted = poll.selectedOptionId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll.question, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, height: 1.4)),
          const SizedBox(height: 14),
          ...poll.options.map((opt) {
            final isSelected = poll.selectedOptionId == opt.id;
            final pct = opt.percentage(poll.totalVotes);
            return GestureDetector(
              onTap: voted ? null : () => onVote(opt.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? primary : border),
                  color: isSelected ? primary.withValues(alpha: 0.12) : const Color(0xFF252525),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    if (voted)
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 46,
                          color: isSelected ? primary.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isSelected ? primary : const Color(0xFF555555), width: 1.5),
                              color: isSelected ? primary : Colors.transparent,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(opt.text, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                          ),
                          if (voted)
                            Text('${(pct * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(color: isSelected ? primary : const Color(0xFF666666), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (!voted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text('${poll.totalVotes} responses | 2 Days left', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 12)),
        ],
      ),
    );
  }
}
