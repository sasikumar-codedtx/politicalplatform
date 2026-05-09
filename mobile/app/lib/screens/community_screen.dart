import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const List<_Post> _posts = [
    _Post(author: 'Murugan K.', handle: '@murugank', location: 'Coimbatore', text: 'Great work by CM Vijay on the new road development scheme in our district!', time: '2h ago', likes: 124, comments: 18),
    _Post(author: 'Priya S.', handle: '@priyas', location: 'Chennai', text: 'The digital classroom initiative has completely transformed how kids learn in our village.', time: '4h ago', likes: 89, comments: 11),
    _Post(author: 'Selvam R.', handle: '@selvamr', location: 'Madurai', text: 'Attended the TVK rally today. The energy was incredible. நாம் வெல்வோம்!', time: '6h ago', likes: 210, comments: 45),
    _Post(author: 'Kavitha M.', handle: '@kavitham', location: 'Salem', text: 'Free bus passes for women scheme has been life-changing for my daily commute.', time: '8h ago', likes: 156, comments: 23),
  ];

  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final surface = Color(f.surfaceColor);
    final border = Color(f.borderColor);

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
                title: "TVK FORUM",
                subtitle: 'VOICES OF TAMIL NADU. SHARE YOUR THOUGHTS,\nSTORIES, AND SUPPORT.',
                primary: primary,
              ),
              collapseMode: CollapseMode.pin,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: border),
            ),
          ),
        ],
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Post compose strip
            Container(
              color: surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.15),
                    ),
                    child: Center(child: Icon(Icons.person_rounded, color: primary, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text("What's on your mind?", style: GoogleFonts.inter(color: const Color(0xFF555555), fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: border),
            // Posts feed
            ..._posts.map((p) => _PostCard(post: p, primary: primary, border: border)),
            const SizedBox(height: 24),
          ],
        ),
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
                child: const Icon(Icons.people_rounded, color: Colors.white, size: 34),
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

class _PostCard extends StatelessWidget {
  final _Post post;
  final Color primary;
  final Color border;
  const _PostCard({required this.post, required this.primary, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(post.author[0], style: GoogleFonts.inter(color: primary, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(post.author, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(width: 6),
                        Text(post.handle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                        const SizedBox(width: 6),
                        Text('· ${post.time}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF555555)),
                        const SizedBox(width: 2),
                        Text(post.location, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF555555))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: primary.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Follow', style: GoogleFonts.inter(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Post text
          Text(post.text, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFDDDDDD), height: 1.5)),
          const SizedBox(height: 12),
          // Action row
          Row(
            children: [
              _ActionBtn(icon: Icons.chat_bubble_outline_rounded, label: '${post.comments}', color: const Color(0xFF666666)),
              const SizedBox(width: 20),
              _ActionBtn(icon: Icons.repeat_rounded, label: 'Share', color: const Color(0xFF666666)),
              const SizedBox(width: 20),
              _ActionBtn(icon: Icons.favorite_border_rounded, label: '${post.likes}', color: const Color(0xFF666666)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionBtn({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: color)),
      ],
    );
  }
}

class _Post {
  final String author;
  final String handle;
  final String location;
  final String text;
  final String time;
  final int likes;
  final int comments;
  const _Post({required this.author, required this.handle, required this.location, required this.text, required this.time, required this.likes, required this.comments});
}
