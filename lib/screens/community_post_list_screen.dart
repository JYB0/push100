import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/post_detail_screen.dart';
import 'package:push100/screens/post_write_screen.dart';

class CommunityPostListScreen extends StatelessWidget {
  final String category;

  const CommunityPostListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category 게시판'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: AppColors.redPrimary,
            ));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("아직 작성된 글이 없습니다."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final post = docs[index];
              final title = post['title'] ?? '제목 없음';
              final nickname = post['nickname'] ?? '익명';
              final timestamp = post['timestamp']?.toDate();
              return ListTile(
                title: Text(title ?? '제목 없음'),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 닉네임, 조회수, 좋아요
                    Expanded(
                      child: Text(
                        '$nickname • 조회수 ${post['views'] ?? 0} • 좋아요 ${post['likes'] ?? 0}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 시간
                    Text(
                      timestamp != null
                          ? DateFormat('HH:mm').format(timestamp.toLocal())
                          : '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(
                        postId: post.id,
                        category: post['category'] ?? '카테고리 없음',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // 🔘 글 작성 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.redPrimary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PostWriteScreen(
                      category: category,
                    )),
          );
        },
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }
}
