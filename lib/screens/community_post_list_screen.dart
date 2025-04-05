import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("아직 작성된 글이 없습니다."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final post = docs[index];
              return ListTile(
                title: Text(post['title'] ?? '제목 없음'),
                subtitle: Text(post['nickname'] ?? '익명'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(postId: post.id),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PostWriteScreen(
                      category: category,
                    )),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
