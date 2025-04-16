import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push100/helpers/hash_helper.dart';

class FirestoreService {
  static Future<void> uploadPost({
    required String category,
    required String nickname,
    required String password,
    required String title,
    required String content,
    String? imageUrl,
    required String deviceUid,
  }) async {
    final passwordHash = hashPassword(password);

    await FirebaseFirestore.instance.collection('posts').add({
      'category': category,
      'nickname': nickname,
      'passwordHash': passwordHash,
      'title': title,
      'content': content,
      'timestamp': Timestamp.now(),
      'imageUrl': imageUrl ?? '',
      'views': 0, // 👁️ 조회수
      'likes': 0, // 👍 좋아요
      'dislikes': 0, // 👎 싫어요
      'deviceUid': deviceUid,
    });
  }
}
