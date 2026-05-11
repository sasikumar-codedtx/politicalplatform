import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fan_post.dart';
import '../models/fan_comment.dart';

class FanPostService {
  static const _postsKey = 'fan_posts';

  static String _commentsKey(String postId) => 'fan_comments_$postId';
  static String _likesKey(String postId) => 'fan_likes_$postId';

  static List<FanPost> _seedPosts() {
    final now = DateTime.now();
    return [
      FanPost(
        id: 'seed_1',
        userId: 'demo1',
        userName: 'TVK Vijay_Madurai',
        text:
            'Attended the community rally today in Madurai — thousands turned up! The energy was incredible. நம் மக்கள் விழிப்புடன் இருக்கிறார்கள். Proud to be part of this movement.',
        mediaType: PostMediaType.none,
        status: PostStatus.approved,
        likeCount: 47,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      FanPost(
        id: 'seed_2',
        userId: 'demo2',
        userName: 'Priya Volunteer',
        text:
            'Our volunteer team cleaned up the local park this morning. Small acts, big impact. Join us next Sunday!',
        mediaType: PostMediaType.image,
        mediaUrl: 'https://picsum.photos/seed/tvk1/400/300',
        status: PostStatus.approved,
        likeCount: 31,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      FanPost(
        id: 'seed_3',
        userId: 'demo3',
        userName: 'Murugan TN',
        text:
            'மாவட்ட கூட்டத்தில் கலந்துகொண்டேன். Attended the district meeting — the leader spoke about real issues affecting our village. நம்பிக்கை அதிகரிக்கிறது. More people should be aware.',
        mediaType: PostMediaType.none,
        status: PostStatus.approved,
        likeCount: 89,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Future<List<FanPost>> getAllPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_postsKey);
    if (raw == null) {
      final seeds = _seedPosts();
      await _savePosts(prefs, seeds);
      return List.from(seeds.reversed);
    }
    final list = (jsonDecode(raw) as List)
        .map((e) => FanPost.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<List<FanPost>> getApprovedPosts() async {
    final all = await getAllPosts();
    return all.where((p) => p.status == PostStatus.approved).toList();
  }

  static Future<List<FanPost>> getMyPosts(String userId) async {
    final all = await getAllPosts();
    return all.where((p) => p.userId == userId).toList();
  }

  static Future<List<FanPost>> getPendingPosts() async {
    final all = await getAllPosts();
    return all.where((p) => p.status == PostStatus.pending).toList();
  }

  static Future<void> savePost(FanPost post) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllPosts();
    final idx = all.indexWhere((p) => p.id == post.id);
    if (idx >= 0) {
      all[idx] = post;
    } else {
      all.insert(0, post);
    }
    await _savePosts(prefs, all);
  }

  static Future<void> deletePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllPosts();
    all.removeWhere((p) => p.id == postId);
    await _savePosts(prefs, all);
    await prefs.remove(_commentsKey(postId));
    await prefs.remove(_likesKey(postId));
  }

  static Future<void> approvePost(String postId) async {
    final all = await getAllPosts();
    final idx = all.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = all[idx];
    final updated = post.copyWith(
      text: post.pendingEdit ?? post.text,
      status: PostStatus.approved,
      clearPendingEdit: true,
    );
    await savePost(updated);
  }

  static Future<void> rejectPost(String postId) async {
    final all = await getAllPosts();
    final idx = all.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final updated = all[idx].copyWith(
      status: PostStatus.rejected,
      clearPendingEdit: true,
    );
    await savePost(updated);
  }

  static Future<List<FanComment>> getComments(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_commentsKey(postId));
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => FanComment.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> addComment(FanComment comment) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getComments(comment.postId);
    existing.insert(0, comment);
    await prefs.setString(
      _commentsKey(comment.postId),
      jsonEncode(existing.map((c) => c.toJson()).toList()),
    );
  }

  static Future<int> getCommentCount(String postId) async {
    final comments = await getComments(postId);
    return comments.length;
  }

  static Future<bool> isLiked(String postId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_likesKey(postId));
    if (raw == null) return false;
    final likes = List<String>.from(jsonDecode(raw) as List);
    return likes.contains(userId);
  }

  static Future<int> toggleLike(String postId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_likesKey(postId));
    final likes =
        raw != null ? List<String>.from(jsonDecode(raw) as List) : <String>[];

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    await prefs.setString(_likesKey(postId), jsonEncode(likes));

    final all = await getAllPosts();
    final idx = all.indexWhere((p) => p.id == postId);
    if (idx >= 0) {
      final updated = all[idx].copyWith(likeCount: likes.length);
      await savePost(updated);
    }

    return likes.length;
  }

  static Future<void> _savePosts(
    SharedPreferences prefs,
    List<FanPost> posts,
  ) async {
    await prefs.setString(
      _postsKey,
      jsonEncode(posts.map((p) => p.toJson()).toList()),
    );
  }
}
