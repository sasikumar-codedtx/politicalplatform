import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_poll_screen.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  int _tab = 0; // 0=Polls, 1=Complaints, 2=Donation
  // Selected option per poll card
  final Map<int, int?> _selected = {};
  final Set<int> _submitted = {};

  static const _polls = [
    _PollData(
      question: 'Which area should be prioritized for immediate development in your locality?',
      options: ['Roads & Infrastructure', 'Drinking Water Supply', 'Government School Renovation'],
      responses: 12,
      daysLeft: 2,
    ),
    _PollData(
      question: 'For job creation in your region, which is a better idea?',
      options: ['More startups through govt grants', 'Attract manufacturing companies', 'Strengthen career support in colleges'],
      responses: 2,
      daysLeft: 10,
    ),
  ];

  void _select(int pollIdx, int optIdx) {
    if (_submitted.contains(pollIdx)) return;
    setState(() => _selected[pollIdx] = optIdx);
  }

  void _submit(int pollIdx) {
    if (_selected[pollIdx] == null) return;
    setState(() => _submitted.add(pollIdx));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                    // Poll cards
                    ...List.generate(_polls.length, (i) => Padding(
                      padding: EdgeInsets.only(bottom: i < _polls.length - 1 ? 12 : 0),
                      child: _PollCard(
                        poll: _polls[i],
                        selectedOption: _selected[i],
                        submitted: _submitted.contains(i),
                        onSelect: (opt) => _select(i, opt),
                        onSubmit: () => _submit(i),
                      ),
                    )),
                  ] else if (_tab == 2) ...[
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePollScreen())),
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
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                      ),
                      alignment: Alignment.center,
                      child: Text('No complaints yet.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF4A4949))),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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
  final _PollData poll;
  final int? selectedOption;
  final bool submitted;
  final ValueChanged<int> onSelect;
  final VoidCallback onSubmit;

  const _PollCard({
    required this.poll,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            poll.question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Options
          Column(
            children: List.generate(poll.options.length, (i) {
              final isSelected = selectedOption == i;
              return Padding(
                padding: EdgeInsets.only(bottom: i < poll.options.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC)),
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
                                : Border.all(color: const Color(0xFFCCCCCC)),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            poll.options[i],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5E5D5D),
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
                color: submitted ? const Color(0xFFEEEEEE) : const Color(0xFF9F1D1F),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'Submit',
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
                      TextSpan(text: '${poll.responses} responses ', style: const TextStyle(color: Colors.black)),
                      const TextSpan(text: '| ', style: TextStyle(color: Color(0xFF888686))),
                      TextSpan(
                        text: ' ${poll.daysLeft} Days left',
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

// ─── Poll Data ────────────────────────────────────────────────────────────────

class _PollData {
  final String question;
  final List<String> options;
  final int responses;
  final int daysLeft;

  const _PollData({
    required this.question,
    required this.options,
    required this.responses,
    required this.daysLeft,
  });
}

// ─── Shared App Bar ───────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final double topPad;
  final String title;

  const _AppBar({required this.topPad, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const Icon(Icons.translate_rounded, size: 24, color: Colors.black),
        ],
      ),
    );
  }
}
