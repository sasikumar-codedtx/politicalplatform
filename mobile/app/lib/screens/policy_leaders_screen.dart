import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'policy_leader_detail_screen.dart';

// ─── Shared data class ────────────────────────────────────────────────────────

class PolicyLeaderData {
  final String role;
  final String name;
  final String imagePath;
  final String biography;

  const PolicyLeaderData({
    required this.role,
    required this.name,
    required this.imagePath,
    required this.biography,
  });
}

const _kPlaceholderBio =
    'A visionary leader who dedicated their life to the cause of social justice '
    'and equality in Tamil Nadu. Their contributions continue to inspire millions '
    'across India and the world.\n\n'
    'Their legacy lives on through the countless lives they transformed and the '
    'movements they inspired, shaping the social and political landscape of Tamil '
    'Nadu for generations to come.';

const List<PolicyLeaderData> kPolicyLeaders = [
  PolicyLeaderData(
    role: 'Karmaveer',
    name: 'Kamarajar',
    imagePath: 'assets/images/leader_kamarajar.png',
    biography: _kPlaceholderBio,
  ),
  PolicyLeaderData(
    role: 'Babasaheb',
    name: 'B. R. Ambedkar',
    imagePath: 'assets/images/leader_ambedkar.png',
    biography: _kPlaceholderBio,
  ),
  PolicyLeaderData(
    role: 'Thanthai',
    name: 'Periyar',
    imagePath: 'assets/images/leader_periyar.png',
    biography: _kPlaceholderBio,
  ),
  PolicyLeaderData(
    role: 'The Jhansi Rani of South India',
    name: 'Anjalai Ammal',
    imagePath: 'assets/images/leader_anjalai.png',
    biography:
        'She started her political activism in 1921 with the Non-cooperation '
        'movement and later took part in the Neil Statue Satyagraha, Salt '
        'Satyagraha and Quit India Movement. Her courage was so well known that '
        'Mahatma Gandhi called her "Jhansi Rani of South India".\n\n'
        'Granddaughter of Anjalai Ammal, Mangai A, explains, "My grandmother was '
        'in jail for more than four and half years and she gave birth to her last '
        'son in the jail itself."\n\n'
        'In 1930, Anjalai Ammal was arrested for picketing shops on Godown Street '
        'in Madras. In 1931, she presided over The All India Women Congress Meet. '
        'She died on 20 February 1961.',
  ),
  PolicyLeaderData(
    role: 'Veeramangai',
    name: 'Velu Nachiyar',
    imagePath: 'assets/images/leader_velunachiyar.png',
    biography: _kPlaceholderBio,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class PolicyLeadersScreen extends StatelessWidget {
  const PolicyLeadersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _HeroBanner(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: kPolicyLeaders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, i) => _LeaderCard(
                  leader: kPolicyLeaders[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PolicyLeaderDetailScreen(
                        leader: kPolicyLeaders[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 216,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/leader_group_banner.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D0A0A), Color(0xFF6B1212)],
                  ),
                ),
              ),
            ),
          ),

          // Top dark gradient (80px from top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x80000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom dark gradient (bottom half)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 108,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x29000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: topPad + 14,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // Title block bottom-left
          Positioned(
            left: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OUR POLICY LEADERS',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 34,
                    color: const Color(0xFFE40101),
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Know our policy leaders',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    height: 1.0,
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

// ─── Leader card ──────────────────────────────────────────────────────────────

class _LeaderCard extends StatelessWidget {
  final PolicyLeaderData leader;
  final VoidCallback onTap;
  const _LeaderCard({required this.leader, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 113,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.11),
              blurRadius: 17,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Red radial glow (right side)
            Positioned(
              right: 0,
              top: (113 - 96) / 2,
              width: 96,
              height: 96,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x33E40101),
                      Color(0x00E40101),
                    ],
                    radius: 0.6,
                  ),
                ),
              ),
            ),

            // Leader portrait (right side)
            Positioned(
              right: 0,
              top: 12,
              width: 97,
              height: 101,
              child: Image.asset(
                leader.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, e, s) => const SizedBox.shrink(),
              ),
            ),

            // Text column (left)
            Positioned(
              left: 14,
              top: 16,
              right: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leader.role,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF242424),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    leader.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF242424),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon bottom-left
            const Positioned(
              left: 14,
              bottom: 14,
              child: Icon(
                Icons.arrow_outward_rounded,
                size: 20,
                color: Color(0xFFE40101),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
