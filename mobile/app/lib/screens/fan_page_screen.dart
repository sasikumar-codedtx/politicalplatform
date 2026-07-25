import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_colors.dart';
import '../models/fan_post.dart';
import '../services/fan_post_service.dart';
import 'create_fan_post_screen.dart';
import 'fan_post_detail_screen.dart';

class FanPageScreen extends StatefulWidget {
  const FanPageScreen({super.key});

  @override
  State<FanPageScreen> createState() => _FanPageScreenState();
}

class _FanPageScreenState extends State<FanPageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FanPost> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final posts = await FanPostService.getApprovedPosts();
    if (mounted) setState(() { _posts = posts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE40101),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateFanPostScreen()),
          );
          _load();
        },
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _Header(topPad: topPad)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFE40101),
                unselectedLabelColor: AppColors.textPrimary,
                indicatorColor: const Color(0xFFE40101),
                indicatorWeight: 2,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [Tab(text: 'All'), Tab(text: 'Popular')],
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE40101)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _PostList(posts: _posts, onRefresh: _load),
                  _PostList(
                    posts: List.from(_posts)
                      ..sort((a, b) => b.likeCount.compareTo(a.likeCount)),
                    onRefresh: _load,
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
      width: double.infinity,
      height: 234 + topPad,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset(
                'assets/images/tvk_flag.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
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
          // Conditional back button — only when this screen was pushed
          Builder(
            builder: (ctx) {
              if (!Navigator.canPop(ctx)) return const SizedBox.shrink();
              return Positioned(
                top: topPad + 14,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              );
            },
          ),
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
                    'COMMUNITY WALL',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fan posts approved by TVK volunteers',
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

class _PostList extends StatelessWidget {
  final List<FanPost> posts;
  final VoidCallback onRefresh;

  const _PostList({required this.posts, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE40101),
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: posts.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _PostCard(
          post: posts[i],
          onRefresh: onRefresh,
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final FanPost post;
  final VoidCallback onRefresh;

  const _PostCard({required this.post, required this.onRefresh});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late int _likeCount;
  bool _liked = false;
  int _commentCount = 0;
  bool _likeLoading = false;

  String get _userId =>
      FirebaseAuth.instance.currentUser?.phoneNumber ?? 'anonymous';

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _loadState();
  }

  Future<void> _loadState() async {
    final liked = await FanPostService.isLiked(widget.post.id, _userId);
    final count = await FanPostService.getCommentCount(widget.post.id);
    if (mounted) setState(() { _liked = liked; _commentCount = count; });
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    setState(() => _likeLoading = true);
    final newCount = await FanPostService.toggleLike(widget.post.id, _userId);
    if (mounted) {
      setState(() {
        _liked = !_liked;
        _likeCount = newCount;
        _likeLoading = false;
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFFE40101),
      const Color(0xFF1976D2),
      const Color(0xFF388E3C),
      const Color(0xFF7B1FA2),
      const Color(0xFFF57C00),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Future<void> _openDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FanPostDetailScreen(post: widget.post)),
    );
    if (!mounted) return;
    _loadState();
    widget.onRefresh();
  }

  void _share() {
    final post = widget.post;
    final link = post.linkUrl;
    Share.share(link == null ? post.text : '${post.text}\n\n$link');
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _avatarColor(post.userName),
                child: Text(
                  _initials(post.userName),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (post.isOfficial) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded,
                              size: 15, color: Color(0xFFE40101)),
                        ],
                      ],
                    ),
                    Text(
                      post.timeAgo,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _share,
                child: Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (post.mediaType == PostMediaType.image && post.mediaUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.mediaUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(
                  height: 200,
                  color: AppColors.surfaceAlt,
                  child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 40),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: _liked ? const Color(0xFFE40101) : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_likeCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: post.commentsEnabled ? _openDetail : null,
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: post.commentsEnabled ? AppColors.textMuted : AppColors.border,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_commentCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: post.commentsEnabled ? AppColors.textSecondary : AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _share,
                child: Icon(Icons.ios_share_rounded,
                    size: 20, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
