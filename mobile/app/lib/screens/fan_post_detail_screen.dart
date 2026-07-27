import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_colors.dart';
import '../models/fan_post.dart';
import '../models/fan_comment.dart';
import '../services/fan_post_service.dart';

class FanPostDetailScreen extends StatefulWidget {
  final FanPost post;

  const FanPostDetailScreen({super.key, required this.post});

  @override
  State<FanPostDetailScreen> createState() => _FanPostDetailScreenState();
}

class _FanPostDetailScreenState extends State<FanPostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  List<FanComment> _comments = [];
  bool _loadingComments = true;
  bool _sending = false;
  late int _likeCount;
  bool _liked = false;
  bool _likeLoading = false;

  String get _userId =>
      FirebaseAuth.instance.currentUser?.phoneNumber ?? 'anonymous';

  String get _userName =>
      FirebaseAuth.instance.currentUser?.phoneNumber?.replaceAll('+91', '') ??
      'User';

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final comments = await FanPostService.getComments(widget.post.id);
    final liked = await FanPostService.isLiked(widget.post.id, _userId);
    if (mounted) {
      setState(() {
        _comments = comments;
        _liked = liked;
        _loadingComments = false;
      });
    }
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

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final comment = FanComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.post.id,
      userId: _userId,
      userName: _userName,
      text: text,
      createdAt: DateTime.now(),
    );

    await FanPostService.addComment(comment);
    _commentController.clear();

    final updated = await FanPostService.getComments(widget.post.id);
    if (mounted) {
      setState(() {
        _comments = updated;
        _sending = false;
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

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final title = post.text.length > 40
        ? '${post.text.substring(0, 40)}...'
        : post.text;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => Share.share(post.linkUrl == null
                ? post.text
                : '${post.text}\n\n${post.linkUrl}'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _FullPostCard(
                  post: post,
                  likeCount: _likeCount,
                  liked: _liked,
                  onToggleLike: _toggleLike,
                  initials: _initials(post.userName),
                  avatarColor: _avatarColor(post.userName),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _CommentsSection(
                  post: post,
                  comments: _comments,
                  loading: _loadingComments,
                  initials: _initials,
                  avatarColor: _avatarColor,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (post.commentsEnabled)
            _CommentInputBar(
              controller: _commentController,
              sending: _sending,
              onSend: _sendComment,
            ),
        ],
      ),
    );
  }
}

class _FullPostCard extends StatelessWidget {
  final FanPost post;
  final int likeCount;
  final bool liked;
  final VoidCallback onToggleLike;
  final String initials;
  final Color avatarColor;

  const _FullPostCard({
    required this.post,
    required this.likeCount,
    required this.liked,
    required this.onToggleLike,
    required this.initials,
    required this.avatarColor,
  });

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
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
                    Text(
                      post.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
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
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          if (post.mediaType == PostMediaType.image && post.mediaUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.mediaUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(
                  height: 180,
                  color: AppColors.surfaceAlt,
                  child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 40),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: onToggleLike,
                child: Row(
                  children: [
                    Icon(
                      liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 22,
                      color: liked ? const Color(0xFFE40101) : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likeCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Share.share(post.linkUrl == null
                    ? post.text
                    : '${post.text}\n\n${post.linkUrl}'),
                child: Icon(Icons.ios_share_rounded,
                    size: 22, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final FanPost post;
  final List<FanComment> comments;
  final bool loading;
  final String Function(String) initials;
  final Color Function(String) avatarColor;

  const _CommentsSection({
    required this.post,
    required this.comments,
    required this.loading,
    required this.initials,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments (${comments.length})',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (!post.commentsEnabled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Comments are disabled on this post',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          )
        else if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFFE40101)),
            ),
          )
        else if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No comments yet. Be the first!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          ...comments.map((c) => _CommentItem(
                comment: c,
                initials: initials(c.userName),
                avatarColor: avatarColor(c.userName),
              )),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final FanComment comment;
  final String initials;
  final Color avatarColor;

  const _CommentItem({
    required this.comment,
    required this.initials,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          comment.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _CommentInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE40101),
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
