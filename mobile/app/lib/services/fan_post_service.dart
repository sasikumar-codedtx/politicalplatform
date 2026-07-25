import 'dart:async';
import 'dart:io';

import '../models/fan_post.dart';
import '../models/fan_comment.dart';
import 'agent_service.dart';
import 'local_cache.dart';

/// Forum data. Posts, likes and comments live on the backend so every user
/// sees the same content and the same counts — nothing is seeded or phone-local.
class FanPostService {
  /// `liked` / comment counts that came back with the last list call, so cards
  /// don't each fire their own request.
  static final Map<String, ({bool liked, int comments, int likes})> _meta = {};

  static PostMediaType _mediaType(String? v) => switch (v) {
        'image' => PostMediaType.image,
        'video' => PostMediaType.video,
        _ => PostMediaType.none,
      };

  static PostStatus _status(String? v) => switch (v) {
        'approved' => PostStatus.approved,
        'rejected' => PostStatus.rejected,
        _ => PostStatus.pending,
      };

  static FanPost _toPost(Map<String, dynamic> j) {
    final id = j['id'] as String;
    _meta[id] = (
      liked: j['liked'] == true,
      comments: (j['comment_count'] as num?)?.toInt() ?? 0,
      likes: (j['like_count'] as num?)?.toInt() ?? 0,
    );
    // An uploaded attachment is served from our backend (has_media); official
    // posts carry a remote media_url instead.
    final remote = (j['media_url'] as String?) ?? '';
    final media = j['has_media'] == true
        ? AgentService.forumMediaUrl(id)
        : (remote.isEmpty ? null : remote);
    return FanPost(
      id: id,
      userId: (j['user_id'] as String?) ?? '',
      userName: (j['user_name'] as String?) ?? 'TVK Member',
      text: (j['text'] as String?) ?? '',
      mediaType: _mediaType(j['media_type'] as String?),
      mediaUrl: media,
      status: _status(j['status'] as String?),
      createdAt:
          DateTime.tryParse((j['created_at'] as String?) ?? '')?.toLocal() ??
              DateTime.now(),
      likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
      isOfficial: j['is_official'] == true,
      linkUrl: (j['link_url'] as String?)?.isEmpty ?? true
          ? null
          : j['link_url'] as String,
    );
  }

  static FanComment _toComment(Map<String, dynamic> j) => FanComment(
        id: j['id'] as String,
        postId: (j['post_id'] as String?) ?? '',
        userId: (j['user_id'] as String?) ?? '',
        userName: (j['user_name'] as String?) ?? 'TVK Member',
        text: (j['text'] as String?) ?? '',
        createdAt:
            DateTime.tryParse((j['created_at'] as String?) ?? '')?.toLocal() ??
                DateTime.now(),
      );

  static String _key(String status, bool mine) =>
      'forum_${mine ? 'mine' : status.isEmpty ? 'all' : status}';

  /// Cached posts render instantly on open; a background call refreshes them.
  static Future<List<FanPost>> _fetch({String status = '', bool mine = false}) async {
    final key = _key(status, mine);
    final cached = await LocalCache.read(key);
    if (cached is List && cached.isNotEmpty) {
      unawaited(_refresh(key, status, mine));
      return cached.cast<Map<String, dynamic>>().map(_toPost).toList();
    }
    final rows = await AgentService.listForumPosts(status: status, mine: mine);
    if (rows.isNotEmpty) await LocalCache.write(key, rows);
    return rows.map(_toPost).toList();
  }

  static Future<void> _refresh(String key, String status, bool mine) async {
    final rows = await AgentService.listForumPosts(status: status, mine: mine);
    if (rows.isNotEmpty) {
      for (final r in rows) {
        _toPost(r); // keeps liked / comment counts current
      }
      await LocalCache.write(key, rows);
    }
  }

  static Future<List<FanPost>> getAllPosts() => _fetch();

  static Future<List<FanPost>> getApprovedPosts() => _fetch(status: 'approved');

  static Future<List<FanPost>> getMyPosts(String userId) => _fetch(mine: true);

  static Future<List<FanPost>> getPendingPosts() => _fetch(status: 'pending');

  /// Creates a post with the typed name and an optional file attachment.
  static Future<void> createPost({
    required String text,
    required String userName,
    File? file,
    String status = 'approved',
  }) async {
    await LocalCache.invalidate(_key('approved', false));
    await LocalCache.invalidate(_key('', true));
    await AgentService.createForumPost(
      text: text, userName: userName, status: status, file: file,
    );
  }

  /// New posts are created server-side. Editing an existing post is not a
  /// backend feature yet, so updates to an already-published post are ignored.
  static Future<void> savePost(FanPost post) async {
    if (int.tryParse(post.id) != null) return;
    await LocalCache.invalidate(_key('approved', false));
    await LocalCache.invalidate(_key('', true));
    await AgentService.createForumPost(
      text: post.text,
      userName: post.userName,
      status: post.status.name,
    );
  }

  static Future<void> deletePost(String postId) async {
    _meta.remove(postId);
    await AgentService.deleteForumPost(postId);
  }

  static Future<void> approvePost(String postId) =>
      AgentService.setForumPostStatus(postId, 'approved');

  static Future<void> rejectPost(String postId) =>
      AgentService.setForumPostStatus(postId, 'rejected');

  static Future<List<FanComment>> getComments(String postId) async {
    final rows = await AgentService.listForumComments(postId);
    final list = rows.map(_toComment).toList();
    final m = _meta[postId];
    _meta[postId] =
        (liked: m?.liked ?? false, comments: list.length, likes: m?.likes ?? 0);
    return list;
  }

  static Future<void> addComment(FanComment comment) async {
    await AgentService.addForumComment(
        comment.postId, comment.text, comment.userName);
  }

  static Future<int> getCommentCount(String postId) async {
    final cached = _meta[postId];
    if (cached != null) return cached.comments;
    return (await getComments(postId)).length;
  }

  static Future<bool> isLiked(String postId, String userId) async {
    final cached = _meta[postId];
    if (cached != null) return cached.liked;
    return false;
  }

  /// Toggles on the server and returns the new like count.
  static Future<int> toggleLike(String postId, String userId) async {
    final res = await AgentService.toggleForumLike(postId);
    final m = _meta[postId];
    if (res == null) return m?.likes ?? 0;
    final count = (res['like_count'] as num?)?.toInt() ?? 0;
    _meta[postId] = (
      liked: res['liked'] == true,
      comments: m?.comments ?? 0,
      likes: count,
    );
    return count;
  }
}
