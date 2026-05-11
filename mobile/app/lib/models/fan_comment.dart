class FanComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  const FanComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FanComment.fromJson(Map<String, dynamic> json) => FanComment(
        id: json['id'] as String,
        postId: json['postId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
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
