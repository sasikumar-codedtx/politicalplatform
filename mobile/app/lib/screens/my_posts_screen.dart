import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../models/fan_post.dart';
import '../services/fan_post_service.dart';
import 'create_fan_post_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FanPost> _myPosts = [];
  List<FanPost> _pendingPosts = [];
  bool _loadingMy = true;
  bool _loadingAdmin = true;

  String get _userId =>
      FirebaseAuth.instance.currentUser?.phoneNumber ?? 'anonymous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMy();
    _loadAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMy() async {
    final posts = await FanPostService.getMyPosts(_userId);
    if (mounted) setState(() { _myPosts = posts; _loadingMy = false; });
  }

  Future<void> _loadAdmin() async {
    final posts = await FanPostService.getPendingPosts();
    if (mounted) setState(() { _pendingPosts = posts; _loadingAdmin = false; });
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadMy(), _loadAdmin()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          t('my_posts.title'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
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
          tabs: [
            Tab(text: t('my_posts.tab_my_posts')),
            Tab(text: t('my_posts.tab_admin_panel')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE40101),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateFanPostScreen()),
          );
          _refreshAll();
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyPostsTab(
            posts: _myPosts,
            loading: _loadingMy,
            onRefresh: _refreshAll,
            userId: _userId,
          ),
          _AdminTab(
            posts: _pendingPosts,
            loading: _loadingAdmin,
            onRefresh: _refreshAll,
          ),
        ],
      ),
    );
  }
}

class _MyPostsTab extends StatelessWidget {
  final List<FanPost> posts;
  final bool loading;
  final VoidCallback onRefresh;
  final String userId;

  const _MyPostsTab({
    required this.posts,
    required this.loading,
    required this.onRefresh,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE40101)));
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              t('my_posts.empty_my_posts'),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
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
        itemBuilder: (context, i) => _MyPostCard(
          post: posts[i],
          onRefresh: onRefresh,
        ),
      ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  final FanPost post;
  final VoidCallback onRefresh;

  const _MyPostCard({required this.post, required this.onRefresh});

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: post.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          t('my_posts.edit_post'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: t('my_posts.edit_post_hint'),
            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE40101)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t('my_posts.cancel'),
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;
              final updated = post.copyWith(pendingEdit: newText);
              await FanPostService.savePost(updated);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              onRefresh();
            },
            child: Text(
              t('my_posts.save'),
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFE40101),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          t('my_posts.delete_post'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          t('my_posts.delete_confirm'),
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t('my_posts.cancel'),
              style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FanPostService.deletePost(post.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              onRefresh();
            },
            child: Text(
              t('my_posts.delete'),
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFE40101),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget statusBadge;
    switch (post.status) {
      case PostStatus.pending:
        statusBadge = _StatusChip(label: t('my_posts.status_pending'), color: Colors.orange);
        break;
      case PostStatus.approved:
        statusBadge = _StatusChip(label: t('my_posts.status_approved'), color: Colors.green);
        break;
      case PostStatus.rejected:
        statusBadge = _StatusChip(label: t('my_posts.status_rejected'), color: const Color(0xFFE40101));
        break;
    }

    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              statusBadge,
              if (post.pendingEdit != null && post.status == PostStatus.approved)
                _StatusChip(label: t('my_posts.status_edit_pending'), color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                post.timeAgo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (post.status == PostStatus.approved)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => _showEditDialog(context),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.textSecondary,
                onPressed: () => _showDeleteDialog(context),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (post.status == PostStatus.approved) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    post.commentsEnabled
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.speaker_notes_off_outlined,
                    size: 20,
                  ),
                  color: post.commentsEnabled ? AppColors.textSecondary : AppColors.textMuted,
                  onPressed: () async {
                    final updated =
                        post.copyWith(commentsEnabled: !post.commentsEnabled);
                    await FanPostService.savePost(updated);
                    onRefresh();
                  },
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AdminTab extends StatelessWidget {
  final List<FanPost> posts;
  final bool loading;
  final VoidCallback onRefresh;

  const _AdminTab({
    required this.posts,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE40101)));
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFFFF8E1),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF57F17)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('my_posts.admin_banner'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF57F17),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (posts.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                t('my_posts.empty_pending'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFE40101),
              onRefresh: () async => onRefresh(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: posts.length,
                separatorBuilder: (context, i) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _AdminCard(
                  post: posts[i],
                  onRefresh: onRefresh,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  final FanPost post;
  final VoidCallback onRefresh;

  const _AdminCard({required this.post, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.userName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await FanPostService.approvePost(post.id);
                    onRefresh();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    t('my_posts.approve'),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await FanPostService.rejectPost(post.id);
                    onRefresh();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE40101),
                    side: const BorderSide(color: Color(0xFFE40101)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    t('my_posts.reject'),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
