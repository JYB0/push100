// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  final String email = "morebetterlifeapp@gmail.com";

  void _copyEmail(BuildContext context) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("이메일 주소가 복사되었습니다!")),
    );
  }

  // Future<void> _fixOldComments(BuildContext context) async {
  //   final firestore = FirebaseFirestore.instance;
  //   final allComments = await firestore.collectionGroup('comments').get();

  //   int updatedCount = 0;

  //   for (final comment in allComments.docs) {
  //     final parentPostRef = comment.reference.parent.parent;
  //     if (parentPostRef == null) continue;

  //     final postId = parentPostRef.id;
  //     final postDoc = await firestore.collection('posts').doc(postId).get();

  //     if (!postDoc.exists) continue;

  //     final category = postDoc['category'] ?? '카테고리 없음';

  //     await comment.reference.update({
  //       'postId': postId,
  //       'category': category,
  //     });

  //     updatedCount++;
  //   }

  //   if (context.mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('✅ $updatedCount개 댓글이 업데이트되었습니다.')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text("💬 앱 문의하기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: dynamicFontSize,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyEmail(context),
                  icon: const Icon(Icons.copy),
                  tooltip: '이메일 복사',
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "문의사항이 있으면 언제든지 이메일로 연락주세요!",
              style: TextStyle(fontSize: dynamicFontSize * 0.9),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     await _fixOldComments(context);
            //   },
            //   child: const Text("🔧 댓글 필드 업데이트"),
            // ),
          ],
        ),
      ),
    );
  }
}
