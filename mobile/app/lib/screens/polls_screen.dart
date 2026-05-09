import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_poll_screen.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  int _selectedTab = 0;
  static const _tabs = ['Active Polls', 'Inactive Polls', 'My Polls'];

  // Track selected option per poll (pollIndex → optionIndex or null)
  final Map<int, int?> _selected = {0: null, 1: 1, 2: 0};

  static const _polls = [
    _PollData(
      question: "Which issue should be the top priority for Tamil Nadu's next government?",
      options: ['Employment opportunities', 'Water management & agriculture', 'Education & skill development', 'Infrastructure & transport'],
      responses: 12,
      daysLeft: 2,
    ),
    _PollData(
      question: 'Which area should be prioritized for immediate development in your locality?',
      options: ['Roads & Infrastructure', 'Drinking Water Supply', 'Government School Renovation', 'Employment opportunities'],
      responses: 12,
      daysLeft: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(topPad: topPad),
            const SizedBox(height: 24),
            // Tab row — gap:16, no indicator bar, text only
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = i == _selectedTab;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 16 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Text(
                        _tabs[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                          color: isActive ? const Color(0xFF1A1A1A) : Colors.black38,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            // "My Polls" create button
            if (_selectedTab == 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePollScreen())),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE40101),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Create New Poll', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            if (_selectedTab == 2) const SizedBox(height: 16),
            // Poll cards
            if (_selectedTab != 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(_polls.length, (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < _polls.length - 1 ? 16 : 0),
                  child: _PollCard(
                    poll: _polls[i],
                    selectedOption: _selected[i],
                    onSelect: (opt) => setState(() => _selected[i] = opt),
                    submitted: _selected[i] != null && i == 1,
                  ),
                )),
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
          // TVK flag image
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover),
            ),
          ),
          // Gradient: transparent at top → black at bottom
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
          // Title block
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
                    'TVK POLLS',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "TVK's Daily Polls Updates. Voice your opinion every day\nour choices help shape tomorrow.",
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

class _PollCard extends StatelessWidget {
  final _PollData poll;
  final int? selectedOption;
  final ValueChanged<int?> onSelect;
  final bool submitted;

  const _PollCard({
    required this.poll,
    required this.selectedOption,
    required this.onSelect,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            poll.question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
              letterSpacing: 0.2,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 16),
          // Options
          ...List.generate(poll.options.length, (i) {
            final isSelected = selectedOption == i;
            return Padding(
              padding: EdgeInsets.only(bottom: i < poll.options.length - 1 ? 16 : 0),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      // Checkbox — 18×18, border or filled #2665be
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2665BE) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected
                              ? null
                              : Border.all(color: const Color(0xFF2665BE), width: 1),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        poll.options[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Submit button
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: submitted ? Colors.transparent : const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(6),
                border: submitted ? Border.all(color: const Color(0xFF1A1A1A), width: 1) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                'Submit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: submitted ? const Color(0xFF1A1A1A) : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Footer
          Text(
            '${poll.responses} responses | ${poll.daysLeft} Days left',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black38,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

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
