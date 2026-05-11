enum PostStatus { pending, approved, rejected }

enum PostMediaType { none, image, video }

class FanPost {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final PostMediaType mediaType;
  final String? mediaUrl;
  final PostStatus status;
  final bool commentsEnabled;
  final DateTime createdAt;
  final int likeCount;
  final String? pendingEdit;

  const FanPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    this.mediaType = PostMediaType.none,
    this.mediaUrl,
    this.status = PostStatus.pending,
    this.commentsEnabled = true,
    required this.createdAt,
    this.likeCount = 0,
    this.pendingEdit,
  });

  FanPost copyWith({
    String? text,
    PostMediaType? mediaType,
    String? mediaUrl,
    PostStatus? status,
    bool? commentsEnabled,
    int? likeCount,
    String? pendingEdit,
    bool clearPendingEdit = false,
  }) {
    return FanPost(
      id: id,
      userId: userId,
      userName: userName,
      text: text ?? this.text,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      status: status ?? this.status,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      pendingEdit: clearPendingEdit ? null : (pendingEdit ?? this.pendingEdit),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'text': text,
        'mediaType': mediaType.name,
        'mediaUrl': mediaUrl,
        'status': status.name,
        'commentsEnabled': commentsEnabled,
        'createdAt': createdAt.toIso8601String(),
        'likeCount': likeCount,
        'pendingEdit': pendingEdit,
      };

  factory FanPost.fromJson(Map<String, dynamic> json) => FanPost(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        text: json['text'] as String,
        mediaType: PostMediaType.values.byName(
          json['mediaType'] as String? ?? 'none',
        ),
        mediaUrl: json['mediaUrl'] as String?,
        status: PostStatus.values.byName(
          json['status'] as String? ?? 'pending',
        ),
        commentsEnabled: json['commentsEnabled'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        likeCount: json['likeCount'] as int? ?? 0,
        pendingEdit: json['pendingEdit'] as String?,
      );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}
