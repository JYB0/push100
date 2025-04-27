import 'package:animations/animations.dart';
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
              final timestampRaw = post['timestamp'];
              final timestamp =
                  timestampRaw is Timestamp ? timestampRaw.toDate() : null;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post.id)
                    .collection('likes')
                    .get(),
                builder: (context, snapshot) {
                  final likesCount = snapshot.data?.docs.length ?? 0;

                  return ListTile(
                    title: Text(title),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                '$nickname • 조회수 ${post['views'] ?? 0}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (likesCount > 0) ...[
                                const Text(' • '),
                                const Icon(
                                  Icons.thumb_up,
                                  size: 16,
                                  color: AppColors.redPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$likesCount',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          timestamp != null
                              ? DateFormat('HH:mm').format(timestamp.toLocal())
                              : '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  PostDetailScreen(
                            postId: post.id,
                            category: post['category'] ?? '카테고리 없음',
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return SharedAxisTransition(
                              animation: animation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType:
                                  SharedAxisTransitionType.horizontal,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
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
