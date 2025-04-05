import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatelessWidget {
  final String category;

  const PostListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final postsRef = FirebaseFirestore.instance
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text('$category 게시판')),
      body: StreamBuilder<QuerySnapshot>(
        stream: postsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('작성된 글이 없습니다.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final post = docs[index];
              final title = post['title'] ?? '제목 없음';
              final nickname = post['nickname'] ?? '익명';
              final timestamp = post['timestamp']?.toDate();

              return ListTile(
                title: Text(title),
                subtitle: Text('$nickname • ${timestamp?.toLocal()}'),
                onTap: () {
                  Navigator.of(context).push(
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
    );
  }
}
