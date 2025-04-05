class Post {
  final String id;
  final String nickname;
  final String passwordHash;
  final String content;
  final DateTime timestamp;
  final int views;
  final int likes;
  final int dislikes;

  Post({
    required this.id,
    required this.nickname,
    required this.passwordHash,
    required this.content,
    required this.timestamp,
    required this.views,
    required this.likes,
    required this.dislikes,
  });

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'passwordHash': passwordHash,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'views': views,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  factory Post.fromMap(String id, Map<String, dynamic> map) {
    return Post(
      id: id,
      nickname: map['nickname'],
      passwordHash: map['passwordHash'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
      dislikes: map['dislikes'] ?? 0,
    );
  }
}
