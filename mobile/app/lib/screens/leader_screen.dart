import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/leader.dart';
import '../viewmodels/leader_viewmodel.dart';

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

class _LeaderView extends StatefulWidget {
  const _LeaderView();

  @override
  State<_LeaderView> createState() => _LeaderViewState();
}

class _LeaderViewState extends State<_LeaderView> {
  int _tab = 0;
  static const _tabs = ['About', 'Achievements', 'Media'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeaderViewModel>();
    final topPad = MediaQuery.of(context).padding.top;

    if (vm.loading || vm.leader == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE40101))),
      );
    }

    final leader = vm.leader!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Hero(leader: leader, topPad: topPad),
            const SizedBox(height: 16),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = i == _tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        height: 34,
                        margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
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
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            if (_tab == 0) _AboutContent(leader: leader),
            if (_tab == 1) _AchievementsContent(leader: leader),
            if (_tab == 2) _MediaContent(videos: vm.media),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Leader leader;
  final double topPad;
  const _Hero({required this.leader, required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 370 + topPad,
      child: Stack(
        children: [
          // Black background (hero stays dark with image)
          Container(color: Colors.black),
          // TVK flag image (low opacity background)
          Positioned(
            top: 119,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/images/tvk_flag_bg.png', fit: BoxFit.cover, height: 199),
            ),
          ),
          // Leader photo (right side, overflows screen edge like Figma)
          Positioned(
            left: 64,
            top: 23,
            right: -40,
            height: 330,
            child: Image.asset('assets/images/leader_vijay.png', fit: BoxFit.contain, alignment: Alignment.centerRight),
          ),
          // Bottom gradient for readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
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
          // Name + title + location
          Positioned(
            left: 16,
            bottom: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  leader.role,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: const Color(0xFFE3E9ED),
                  ),
                ),
              ],
            ),
          ),
          // Location row
          Positioned(
            left: 16,
            bottom: 28,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  leader.location,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.white,
                    letterSpacing: 0.2,
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

class _AboutContent extends StatelessWidget {
  final Leader leader;
  const _AboutContent({required this.leader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card: light table
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _InfoRow('Name', 'Joseph Vijay Chandrasekhar'),
                _InfoRow('Party Position', 'President'),
                _InfoRow('Date of Birth', '22 June 1974'),
                _InfoRow('Age', '54'),
                _InfoRow('Place of origin', 'Chennai, Tamil Nadu'),
                _InfoRow('Education', 'B.A. in Visual Communication', last: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Personal Background
          _Section(
            title: 'Personal Background',
            body: leader.bio,
          ),
          const SizedBox(height: 16),
          // Career Summary
          _Section(
            title: 'Career Summary',
            body: leader.careerSummary,
          ),
          const SizedBox(height: 16),
          // Political Journey
          _Section(
            title: 'Political Journey',
            body: 'From actor and philanthropist (2009, Vijay Makkal Iyakkam) to full-scale political leader (2024, TVK launch).',
          ),
          const SizedBox(height: 16),
          // Major Campaigns
          Text(
            'Major Campaigns',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 16),
          _CampaignItem(
            imagePath: 'assets/images/campaign1.png',
            text: "Led rallies in Vikravandi and Villupuram, set the party's ideology drawing inspiration from Periyar and social justice.",
          ),
          const SizedBox(height: 8),
          _CampaignItem(
            imagePath: 'assets/images/campaign2.png',
            text: "Launched Villupuram Declaration affirming TVK's commitment to Dravidian social justice and anti-corruption governance.",
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _InfoRow(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: const Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Text(
          body,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.black54,
            height: 22 / 14,
          ),
        ),
      ],
    );
  }
}

class _CampaignItem extends StatelessWidget {
  final String imagePath;
  final String text;
  const _CampaignItem({required this.imagePath, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 89,
            width: double.infinity,
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.black54,
            height: 22 / 14,
          ),
        ),
      ],
    );
  }
}

class _AchievementsContent extends StatelessWidget {
  final Leader leader;
  const _AchievementsContent({required this.leader});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: leader.achievements.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a.year,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE40101),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _MediaContent extends StatelessWidget {
  final List<dynamic> videos;
  const _MediaContent({required this.videos});

  @override
  Widget build(BuildContext context) {
    const cardW = 171.0;
    const cardH = 264.0;
    const gap = 16.0;
    final rows = (videos.length / 2).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(rows, (row) {
          final leftIdx = row * 2;
          final rightIdx = leftIdx + 1;
          return Padding(
            padding: EdgeInsets.only(bottom: row < rows - 1 ? gap : 0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: cardW,
                    height: cardH,
                    color: const Color(0xFFEEEEEE),
                    child: const Center(
                      child: _PlayButton(),
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                if (rightIdx < videos.length)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: cardW,
                      height: cardH,
                      color: const Color(0xFFEEEEEE),
                      child: const Center(
                        child: _PlayButton(),
                      ),
                    ),
                  )
                else
                  SizedBox(width: cardW, height: cardH),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xFFE40101),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
    );
  }
}
