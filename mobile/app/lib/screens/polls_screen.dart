import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../services/agent_service.dart';
import 'create_poll_screen.dart';
import 'complaints_screen.dart';

class PollsScreen extends StatefulWidget {
  final int initialTab; // 0=Polls, 1=Complaints, 2=Donation
  const PollsScreen({super.key, this.initialTab = 0});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  late int _tab = widget.initialTab; // 0=Polls, 1=Complaints, 2=Donation

  List<Map<String, dynamic>> _polls = const [];
  List<Map<String, dynamic>> _complaints = const [];
  bool _loading = true;

  // Selected option + submitted + live response count, keyed by poll id.
  final Map<int, int?> _selected = {};
  final Set<int> _submitted = {};
  final Map<int, int> _responses = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AgentService.listPolls(),
      AgentService.getComplaints(),
    ]);
    final polls = results[0];
    if (!mounted) return;
    setState(() {
      _polls = polls;
      _complaints = results[1];
      _loading = false;
      _selected.clear();
      _submitted.clear();
      _responses.clear();
      for (final p in polls) {
        final id = p['id'] as int;
        _responses[id] = (p['responses'] as int?) ?? 0;
        final my = p['my_vote'] as int?;
        if (my != null) {
          _selected[id] = my;
          _submitted.add(id);
        }
      }
    });
  }

  void _select(int pollId, int optIdx) {
    if (_submitted.contains(pollId)) return;
    setState(() => _selected[pollId] = optIdx);
  }

  Future<void> _submit(int pollId) async {
    final opt = _selected[pollId];
    if (opt == null || _submitted.contains(pollId)) return;
    setState(() => _submitted.add(pollId));
    final ok = await AgentService.votePoll(pollId, opt);
    if (!mounted) return;
    if (ok) {
      setState(() => _responses[pollId] = (_responses[pollId] ?? 0) + 1);
    } else {
      setState(() => _submitted.remove(pollId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit your vote. Please try again.')),
      );
    }
  }

  Future<void> _createPoll() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePollScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────
          _AppBar(topPad: topPad, title: 'Take Action'),
          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'Polls', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Complaints', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Donation', active: _tab == 2, onTap: () => setState(() => _tab = 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_tab == 0) ...[
                    _CreatePollButton(onTap: _createPoll),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF9F1D1F))),
                      )
                    else if (_polls.isEmpty)
                      _InfoCard(text: 'No polls yet. Create the first one!')
                    else
                      ...List.generate(_polls.length, (i) {
                        final p = _polls[i];
                        final id = p['id'] as int;
                        return Padding(
                          padding: EdgeInsets.only(bottom: i < _polls.length - 1 ? 12 : 0),
                          child: _PollCard(
                            question: p['question'] as String? ?? '',
                            options: ((p['options'] as List?) ?? const []).cast<String>(),
                            responses: _responses[id] ?? 0,
                            daysLeft: (p['days_left'] as int?) ?? 0,
                            selectedOption: _selected[id],
                            submitted: _submitted.contains(id),
                            onSelect: (opt) => _select(id, opt),
                            onSubmit: () => _submit(id),
                          ),
                        );
                      }),
                  ] else if (_tab == 2) ...[
                    const _DonationComingSoon(),
                  ] else ...[
                    _CreateComplaintButton(onTap: _openComplaints),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF9F1D1F))),
                      )
                    else if (_complaints.isEmpty)
                      _InfoCard(text: 'No complaints yet.')
                    else
                      ...List.generate(_complaints.length, (i) {
                        final c = _complaints[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: i < _complaints.length - 1 ? 12 : 0),
                          child: _ComplaintCard(
                            title: c['title'] as String? ?? '',
                            description: c['description'] as String? ?? '',
                            category: c['category'] as String? ?? '',
                            status: c['status'] as String? ?? 'Pending',
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openComplaints() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ComplaintsScreen()));
    _load(); // refresh in case one was registered
  }
}

// ─── Complaints ─────────────────────────────────────────────────────────────

class _CreateComplaintButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateComplaintButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF9F1D1F),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Register Complaint',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final String title, description, category, status;
  const _ComplaintCard({
    required this.title,
    required this.description,
    required this.category,
    required this.status,
  });

  Color get _statusColor => switch (status.toLowerCase()) {
        'resolved' => const Color(0xFF2E7D32),
        'in-progress' || 'in progress' => const Color(0xFFF57F17),
        _ => const Color(0xFF9F1D1F),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _statusColor)),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          ],
          if (category.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Create Poll Button ─────────────────────────────────────────────────────────

class _CreatePollButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreatePollButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF9F1D1F),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Create New Poll',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─── Donation (welfare contribution) — coming soon ──────────────────────────────

class _DonationComingSoon extends StatelessWidget {
  const _DonationComingSoon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF9D8D8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF9F1D1F), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Welfare Contribution',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contribute an amount towards TVK welfare initiatives. Secure payments are coming soon.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Coming soon',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9F1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info / empty card ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary)),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF9F1D1F) : const Color(0xFFF9D8D8),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF9F1D1F),
          ),
        ),
      ),
    );
  }
}

// ─── Poll Card ────────────────────────────────────────────────────────────────

class _PollCard extends StatelessWidget {
  final String question;
  final List<String> options;
  final int responses;
  final int daysLeft;
  final int? selectedOption;
  final bool submitted;
  final ValueChanged<int> onSelect;
  final VoidCallback onSubmit;

  const _PollCard({
    required this.question,
    required this.options,
    required this.responses,
    required this.daysLeft,
    required this.selectedOption,
    required this.submitted,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Options
          Column(
            children: List.generate(options.length, (i) {
              final isSelected = selectedOption == i;
              return Padding(
                padding: EdgeInsets.only(bottom: i < options.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? const Color(0xFF9F1D1F) : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Checkbox
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF9F1D1F) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            options[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Submit button
          GestureDetector(
            onTap: submitted ? null : onSubmit,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: submitted ? AppColors.surfaceAlt : const Color(0xFF9F1D1F),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                submitted ? 'Voted' : 'Submit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: submitted ? const Color(0xFF9F1D1F) : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Footer: responses + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    children: [
                      TextSpan(text: '$responses responses ', style: TextStyle(color: AppColors.textPrimary)),
                      TextSpan(text: '| ', style: TextStyle(color: AppColors.textMuted)),
                      TextSpan(
                        text: daysLeft > 0 ? ' $daysLeft Days left' : ' Closed',
                        style: const TextStyle(color: Color(0xFFDD2D2D)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF319C35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Get TVK Badge',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared App Bar ───────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final double topPad;
  final String title;

  const _AppBar({required this.topPad, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_rounded, size: 24, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
