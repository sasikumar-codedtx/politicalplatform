import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'policy_leader_detail_screen.dart';

// ─── Shared data models ───────────────────────────────────────────────────────

class PolicyLeaderData {
  final String role;
  final String name;
  final String imagePath;
  final String biography;
  final String? years;

  const PolicyLeaderData({
    required this.role,
    required this.name,
    required this.imagePath,
    required this.biography,
    this.years,
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
    years: '1903–1975',
  ),
  PolicyLeaderData(
    role: 'Babasaheb',
    name: 'B. R. Ambedkar',
    imagePath: 'assets/images/leader_ambedkar.png',
    biography: _kPlaceholderBio,
    years: '1891–1956',
  ),
  PolicyLeaderData(
    role: 'Thanthai',
    name: 'Periyar',
    imagePath: 'assets/images/leader_periyar.png',
    biography: _kPlaceholderBio,
    years: '1879–1973',
  ),
  PolicyLeaderData(
    role: 'The Jhansi Rani of South India',
    name: 'Anjalai Ammal',
    imagePath: 'assets/images/leader_anjalai.png',
    years: '1890–1961',
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
    years: '1730–1796',
  ),
];

// TVK party leaders — used on home screen cards
const List<PolicyLeaderData> kTvkLeaders = [
  PolicyLeaderData(
    role: 'President',
    name: 'Vijay',
    imagePath: 'assets/images/leader_vijay.png',
    biography:
        'Joseph Vijay Chandrasekhar, known professionally as Vijay, is an '
        'Indian actor and politician who founded Tamilaga Vettri Kazhagam (TVK) '
        'in 2024. After a celebrated career in Tamil cinema spanning three decades, '
        'he entered politics with a vision for a modern, technology-enabled and '
        'socially just Tamil Nadu.\n\n'
        'As TVK\'s founding president, Vijay champions youth empowerment, '
        'agricultural welfare, and transparent governance. His movement draws '
        'heavily from the social justice ideology of Periyar, Kamarajar, and '
        'Ambedkar, adapting their principles for the 21st century.',
  ),
  PolicyLeaderData(
    role: 'General Secretary',
    name: 'N. Anand',
    imagePath: 'assets/images/leader_anand.png',
    biography:
        'N. Anand serves as the General Secretary of Tamilaga Vettri Kazhagam. '
        'A close associate of Vijay, Anand brings decades of grassroots political '
        'experience and organisational acumen to the party.\n\n'
        'He has been instrumental in building the party\'s district-level networks '
        'across Tamil Nadu, ensuring that TVK\'s message of inclusive development '
        'reaches every constituency.',
  ),
  PolicyLeaderData(
    role: 'Propaganda & Policy General Secretary',
    name: 'K. G. Arunraj',
    imagePath: 'assets/images/leader_arunraj.png',
    biography:
        'K. G. Arunraj is the Propaganda and Policy General Secretary of '
        'Tamilaga Vettri Kazhagam. He leads the party\'s communications strategy '
        'and policy formulation, translating TVK\'s vision into concrete, '
        'actionable governance plans.\n\n'
        'Arunraj has been a key architect of TVK\'s manifesto, with a special '
        'focus on digital inclusion, agricultural reform, and education policy.',
  ),
  PolicyLeaderData(
    role: 'Youth Wing Secretary',
    name: 'A. Aadhav Arjuna',
    imagePath: 'assets/images/leader_aadhav.png',
    biography:
        'A. Aadhav Arjuna heads the Youth Wing of Tamilaga Vettri Kazhagam, '
        'mobilising millions of young voters across Tamil Nadu. His dynamic '
        'leadership style and connect with the youth has made him one of the '
        'most recognisable faces of the TVK movement.\n\n'
        'Aadhav champions digital literacy programmes and skill development '
        'initiatives designed to prepare Tamil Nadu\'s youth for the emerging '
        'technology economy.',
  ),
];

// ─── Election candidate data ──────────────────────────────────────────────────

class ElectionCandidate {
  final String name;
  final String role;
  final String district;
  final String constituency;
  final int constituencyNo;
  final String? imagePath;

  const ElectionCandidate({
    required this.name,
    required this.role,
    required this.district,
    required this.constituency,
    required this.constituencyNo,
    this.imagePath,
  });
}

class DistrictGroup {
  final String name;
  final List<ElectionCandidate> candidates;
  const DistrictGroup({required this.name, required this.candidates});
}

const List<DistrictGroup> kDistrictGroups = [
  DistrictGroup(name: 'Chennai', candidates: [
    ElectionCandidate(name: 'C. Joseph Vijay', role: 'Party President', district: 'Chennai', constituency: 'Perambur', constituencyNo: 12, imagePath: 'assets/images/leader_vijay.png'),
    ElectionCandidate(name: 'R. Senthil Kumar', role: 'District Secretary', district: 'Chennai', constituency: 'Harbour', constituencyNo: 6),
    ElectionCandidate(name: 'M. Kavitha', role: 'Youth Wing Leader', district: 'Chennai', constituency: 'Thousand Lights', constituencyNo: 14),
    ElectionCandidate(name: 'P. Arumugam', role: 'District Treasurer', district: 'Chennai', constituency: 'Anna Nagar', constituencyNo: 9),
  ]),
  DistrictGroup(name: 'Coimbatore', candidates: [
    ElectionCandidate(name: 'N. Anand', role: 'General Secretary', district: 'Coimbatore', constituency: 'Coimbatore South', constituencyNo: 155, imagePath: 'assets/images/leader_anand.png'),
    ElectionCandidate(name: 'S. Priya Dharshini', role: 'Women Wing Sec.', district: 'Coimbatore', constituency: 'Pollachi', constituencyNo: 149),
    ElectionCandidate(name: 'K. Murugan', role: 'District Secretary', district: 'Coimbatore', constituency: 'Mettupalayam', constituencyNo: 143),
  ]),
  DistrictGroup(name: 'Madurai', candidates: [
    ElectionCandidate(name: 'K. G. Arunraj', role: 'Propaganda Secretary', district: 'Madurai', constituency: 'Madurai East', constituencyNo: 192, imagePath: 'assets/images/leader_arunraj.png'),
    ElectionCandidate(name: 'T. Selvarani', role: 'District Secretary', district: 'Madurai', constituency: 'Melur', constituencyNo: 197),
    ElectionCandidate(name: 'V. Karthik', role: 'IT Wing Head', district: 'Madurai', constituency: 'Sholavandan', constituencyNo: 195),
  ]),
  DistrictGroup(name: 'Salem', candidates: [
    ElectionCandidate(name: 'A. Aadhav Arjuna', role: 'Youth Wing Sec.', district: 'Salem', constituency: 'Edappadi', constituencyNo: 117, imagePath: 'assets/images/leader_aadhav.png'),
    ElectionCandidate(name: 'G. Nalini', role: 'District Co-Secretary', district: 'Salem', constituency: 'Salem West', constituencyNo: 112),
    ElectionCandidate(name: 'M. Perumal', role: 'District Treasurer', district: 'Salem', constituency: 'Attur', constituencyNo: 116),
  ]),
  DistrictGroup(name: 'Tiruvallur', candidates: [
    ElectionCandidate(name: 'R. Ashwin Kumar', role: 'District Secretary', district: 'Tiruvallur', constituency: 'Ponneri', constituencyNo: 21),
    ElectionCandidate(name: 'S. Meenakshi', role: 'Women Wing Sec.', district: 'Tiruvallur', constituency: 'Gummidipoondi', constituencyNo: 22),
    ElectionCandidate(name: 'L. Pandian', role: 'District Joint Sec.', district: 'Tiruvallur', constituency: 'Tiruvallur', constituencyNo: 20),
  ]),
  DistrictGroup(name: 'Vellore', candidates: [
    ElectionCandidate(name: 'D. Selvakumar', role: 'District Secretary', district: 'Vellore', constituency: 'Vellore', constituencyNo: 67),
    ElectionCandidate(name: 'C. Saranya', role: 'Youth Wing Head', district: 'Vellore', constituency: 'Arakkonam', constituencyNo: 62),
    ElectionCandidate(name: 'B. Vijayakumar', role: 'District Treasurer', district: 'Vellore', constituency: 'Ranipet', constituencyNo: 71),
  ]),
  DistrictGroup(name: 'Thanjavur', candidates: [
    ElectionCandidate(name: 'M. Suresh', role: 'District Secretary', district: 'Thanjavur', constituency: 'Thanjavur', constituencyNo: 168),
    ElectionCandidate(name: 'K. Vasantha', role: 'Women Wing Sec.', district: 'Thanjavur', constituency: 'Papanasam', constituencyNo: 170),
    ElectionCandidate(name: 'R. Manikandan', role: 'District Joint Sec.', district: 'Thanjavur', constituency: 'Kumbakonam', constituencyNo: 167),
  ]),
  DistrictGroup(name: 'Tirunelveli', candidates: [
    ElectionCandidate(name: 'P. Annamalai', role: 'District Secretary', district: 'Tirunelveli', constituency: 'Tirunelveli', constituencyNo: 216),
    ElectionCandidate(name: 'R. Deepa', role: 'Youth Wing Sec.', district: 'Tirunelveli', constituency: 'Palayamkottai', constituencyNo: 215),
    ElectionCandidate(name: 'S. Thirunavukkarasu', role: 'District Treasurer', district: 'Tirunelveli', constituency: 'Tenkasi', constituencyNo: 220),
  ]),
  DistrictGroup(name: 'Erode', candidates: [
    ElectionCandidate(name: 'T. Prabhu', role: 'District Secretary', district: 'Erode', constituency: 'Erode East', constituencyNo: 131),
    ElectionCandidate(name: 'N. Kamala', role: 'Women Wing Head', district: 'Erode', constituency: 'Bhavani', constituencyNo: 134),
    ElectionCandidate(name: 'K. Saravanan', role: 'District Joint Sec.', district: 'Erode', constituency: 'Perundurai', constituencyNo: 136),
  ]),
  DistrictGroup(name: 'Kanchipuram', candidates: [
    ElectionCandidate(name: 'V. Dhandapani', role: 'District Secretary', district: 'Kanchipuram', constituency: 'Kanchipuram', constituencyNo: 42),
    ElectionCandidate(name: 'A. Revathi', role: 'Youth Wing Sec.', district: 'Kanchipuram', constituency: 'Walajabad', constituencyNo: 44),
    ElectionCandidate(name: 'R. Murugesan', role: 'District Treasurer', district: 'Kanchipuram', constituency: 'Uthiramerur', constituencyNo: 46),
  ]),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class TvkFamilyScreen extends StatefulWidget {
  const TvkFamilyScreen({super.key});

  @override
  State<TvkFamilyScreen> createState() => _TvkFamilyScreenState();
}

class _TvkFamilyScreenState extends State<TvkFamilyScreen> {
  String _searchQuery = '';
  String _activeDistrict = 'All';

  List<DistrictGroup> get _filteredGroups {
    var groups = kDistrictGroups;

    // District filter
    if (_activeDistrict != 'All') {
      groups = groups.where((g) => g.name == _activeDistrict).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      groups = groups
          .map((g) => DistrictGroup(
                name: g.name,
                candidates: g.candidates
                    .where((c) =>
                        c.name.toLowerCase().contains(q) ||
                        c.constituency.toLowerCase().contains(q) ||
                        c.role.toLowerCase().contains(q))
                    .toList(),
              ))
          .where((g) => g.candidates.isNotEmpty)
          .toList();
    }
    return groups;
  }

  int get _totalCandidates =>
      _filteredGroups.fold(0, (sum, g) => sum + g.candidates.length);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final districts = ['All', ...kDistrictGroups.map((g) => g.name)];
    final filtered = _filteredGroups;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Column(
          children: [
            // ── Hero banner ─────────────────────────────────────────────────
            _HeroBanner(topPad: topPad, totalCount: _totalCandidates),

            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDEDEDE)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x18000000), blurRadius: 4),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, color: const Color(0xFF242424)),
                  decoration: InputDecoration(
                    hintText: 'Search by name, constituency or role…',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF999999),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF888888), size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // ── District filter chips ────────────────────────────────────────
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: districts.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final d = districts[i];
                  final isActive = d == _activeDistrict;
                  return GestureDetector(
                    onTap: () => setState(() => _activeDistrict = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE40101)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFE40101)
                              : const Color(0xFFDEDEDE),
                        ),
                      ),
                      child: Text(
                        d,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ── Candidate list grouped by district ──────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No candidates found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _DistrictSection(group: filtered[i]),
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
  final double topPad;
  final int totalCount;
  const _HeroBanner({required this.topPad, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topPad + 160,
      child: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/leader_group_banner.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
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
          // Top vignette
          Positioned(
            top: 0, left: 0, right: 0, height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Colors.transparent],
                ),
              ),
            ),
          ),
          // Bottom vignette
          Positioned(
            bottom: 0, left: 0, right: 0, height: 130,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
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
          // Title + badge
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TVK',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 36,
                          color: const Color(0xFFE40101),
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'FAMILY',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 36,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Know Your Leaders · All Districts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCount',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 28,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'Members',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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

// ─── District section (header + candidate cards) ──────────────────────────────

class _DistrictSection extends StatelessWidget {
  final DistrictGroup group;
  const _DistrictSection({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // District header
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              group.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE40101).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${group.candidates.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE40101),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Cards
        ...group.candidates.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CandidateCard(candidate: c),
            )),
      ],
    );
  }
}

// ─── Candidate card ───────────────────────────────────────────────────────────

class _CandidateCard extends StatelessWidget {
  final ElectionCandidate candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar — photo or initials
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 56,
              height: 56,
              child: candidate.imagePath != null
                  ? Image.asset(
                      candidate.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          _InitialsAvatar(name: candidate.name),
                    )
                  : _InitialsAvatar(name: candidate.name),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  candidate.role,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 6),
                // Constituency pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Color(0xFF888888)),
                      const SizedBox(width: 3),
                      Text(
                        '${candidate.constituencyNo}. ${candidate.constituency}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFCCCCCC), size: 22),
        ],
      ),
    );
  }
}

// ─── Initials avatar ──────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  const _InitialsAvatar({required this.name});

  // Deterministic color from name
  Color get _bgColor {
    final colors = [
      const Color(0xFF9F1D1F),
      const Color(0xFF1A5276),
      const Color(0xFF1E8449),
      const Color(0xFF7D3C98),
      const Color(0xFFB9770E),
      const Color(0xFF2E4053),
    ];
    return colors[name.codeUnits.first % colors.length];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Policy Leaders Screen (Figma 1328:4500) ──────────────────────────────────
// Historical social-justice leaders list — separate from TVK Family

class PolicyLeadersScreen extends StatelessWidget {
  const PolicyLeadersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── Hero banner ────────────────────────────────────────────────
            _PolicyHeroBanner(topPad: topPad),

            // ── Leader cards list ──────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: kPolicyLeaders.length,
                separatorBuilder: (context, i) => const SizedBox(height: 18),
                itemBuilder: (context, i) => _PolicyLeaderCard(
                  leader: kPolicyLeaders[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PolicyLeaderDetailScreen(
                          leader: kPolicyLeaders[i]),
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

class _PolicyHeroBanner extends StatelessWidget {
  final double topPad;
  const _PolicyHeroBanner({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: topPad + 162,
      child: Stack(
        children: [
          // Group photo background
          Positioned.fill(
            child: Image.asset(
              'assets/images/leader_group_banner.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
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

          // Dark gradient — bottom (text readability)
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: topPad + 162,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.838, 1.0],
                  colors: [
                    Colors.black,
                    Color(0xCC000000),
                    Colors.transparent,
                  ],
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

          // Title
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
                  'KNOW OUR POLICY LEADERS',
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

// ─── Policy leader card (Figma exact) ────────────────────────────────────────

class _PolicyLeaderCard extends StatelessWidget {
  final PolicyLeaderData leader;
  final VoidCallback onTap;
  const _PolicyLeaderCard({required this.leader, required this.onTap});

  // Portrait dimensions per leader (right-side positioning)
  _PortraitSpec get _portrait {
    switch (leader.name) {
      case 'Kamarajar':
        return const _PortraitSpec(right: 1, top: 12, width: 97, height: 101);
      case 'B. R. Ambedkar':
        return const _PortraitSpec(right: 12, top: 0, width: 118, height: 113);
      case 'Periyar':
        return const _PortraitSpec(right: -14, top: 8, width: 149, height: 112);
      case 'Anjalai Ammal':
        return const _PortraitSpec(right: 4, top: 6, width: 134, height: 107);
      case 'Velu Nachiyar':
        return const _PortraitSpec(right: 11, top: 16, width: 114, height: 97);
      default:
        return const _PortraitSpec(right: 0, top: 6, width: 100, height: 107);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _portrait;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 113,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 17,
              offset: Offset.zero,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Red radial glow — right side behind portrait
            Positioned(
              right: -20,
              top: (113 - 96) / 2,
              width: 130,
              height: 96,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.65,
                    colors: [Color(0x44E89090), Color(0x00E89090)],
                  ),
                ),
              ),
            ),

            // Leader portrait — right side, per-leader sizing
            Positioned(
              right: p.right,
              top: p.top,
              width: p.width,
              height: p.height,
              child: Image.asset(
                leader.imagePath,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, e, s) => const SizedBox.shrink(),
              ),
            ),

            // Role + name — left side
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
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

            // Arrow ↗ — bottom-left (Figma: left:14, top:79)
            const Positioned(
              left: 14,
              bottom: 12,
              child: Icon(
                Icons.arrow_outward_rounded,
                color: Color(0xFFE40101),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitSpec {
  final double right;
  final double top;
  final double width;
  final double height;
  const _PortraitSpec(
      {required this.right,
      required this.top,
      required this.width,
      required this.height});
}
