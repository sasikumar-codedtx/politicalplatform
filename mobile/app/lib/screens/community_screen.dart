import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedCat = 0;
  static const _categories = ['All', 'Popular', 'My Posts', 'Followings'];

  static const _posts = [
    _PostData(
      author: 'TVK Vijay_Madurai',
      role: 'Volunteer',
      isHashtag: true,
      text: '#தமிழக வெற்றிக் கழகம்\n#TVK Vijay',
      hasImage: true,
      imageHeight: 220,
      date: 'Jun 4, 2024',
    ),
    _PostData(
      author: 'TVK Thozhar',
      role: 'Volunteer',
      isHashtag: false,
      text: "Congratulations to Hon'ble @Thiru.RahulGandhi Avargal for being unanimously elected by @INC India and its allies as Leader of Opposition in the Lok Sabha.",
      hasImage: true,
      imageHeight: 220,
      date: 'Jun 4, 2024',
    ),
    _PostData(
      author: 'TVK Official',
      role: 'Volunteer',
      isHashtag: false,
      text: 'Tamilaga Vettri Kazhagam: Flag Anthem | தமிழக வெற்றிக் கழகம்: கொடிப் பாடல்\n\nhttps://youtu.be/as86Klk5qUE\n\nநாடெங்கும் நமது கொடி பறக்கும்.\n\n#TVKFlagAnthem #ThalaivarVijay',
      hasImage: true,
      imageHeight: 200,
      date: 'Jun 4, 2024',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        backgroundColor: const Color(0xFFE40101),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(topPad: topPad),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchBar(),
                  const SizedBox(height: 24),
                  _CategoryTabs(
                    selected: _selectedCat,
                    onSelect: (i) => setState(() => _selectedCat = i),
                    labels: _categories,
                  ),
                  const SizedBox(height: 24),
                  ..._posts.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _PostCard(post: p),
                  )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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
          // Title block at bottom
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
                    'Community Wall',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share your opinions, posts & Follow our influencers',
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.black38, size: 20),
          const SizedBox(width: 10),
          Text(
            'Search',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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

class _CategoryTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final List<String> labels;

  const _CategoryTabs({required this.selected, required this.onSelect, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              height: 34,
              margin: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE40101), Color(0x00E40101)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(isActive ? 8 : 6),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _PostData post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(
        author: post.author,
        role: post.role,
        text: post.text,
        hasImage: post.hasImage,
        date: post.date,
      ))),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar — 38×38 white rounded-[10px]
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFF333333), size: 22),
            ),
            const SizedBox(width: 12),
            // Name + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.author,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        post.role,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.black54,
                          letterSpacing: 0.2,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Follow button — bg-[#e40101] px:18 py:6 rounded-[6px]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Follow',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Post text
        Text(
          post.text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: post.isHashtag ? const Color(0xFF256CD0) : const Color(0xFF1A1A1A),
            height: 23 / 15,
          ),
        ),
        const SizedBox(height: 16),
        // Post image placeholder
        if (post.hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              height: post.imageHeight,
              color: const Color(0xFFEEEEEE),
              child: const Icon(Icons.image_outlined, color: Colors.black38, size: 40),
            ),
          ),
        if (post.hasImage) const SizedBox(height: 6),
        // Date
        Text(
          post.date,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.black38,
          ),
        ),
        const SizedBox(height: 16),
        // Action row
        Row(
          children: [
            const Icon(Icons.favorite_border_rounded, size: 20, color: Colors.black54),
            const SizedBox(width: 16),
            const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.black54),
            const SizedBox(width: 16),
            const Icon(Icons.repeat_rounded, size: 20, color: Colors.black54),
            const Spacer(),
            const Icon(Icons.ios_share_rounded, size: 20, color: Colors.black54),
          ],
        ),
      ],
      ),
    );
  }
}

class _PostData {
  final String author;
  final String role;
  final bool isHashtag;
  final String text;
  final bool hasImage;
  final double imageHeight;
  final String date;

  const _PostData({
    required this.author,
    required this.role,
    required this.isHashtag,
    required this.text,
    required this.hasImage,
    required this.imageHeight,
    required this.date,
  });
}
