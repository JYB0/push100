import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:push100/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:push100/screens/post_detail_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final List<DocumentSnapshot> myPosts = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !isLoading) {
        _fetchMorePosts();
      }
    });
  }

  Future<void> _fetchInitialPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceUid = prefs.getString('device_uid');
    if (deviceUid == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('deviceUid', isEqualTo: deviceUid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    setState(() {
      myPosts.clear();
      myPosts.addAll(snapshot.docs);
      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }
      hasMore = snapshot.docs.length == 20;
    });
  }

  Future<void> _fetchMorePosts() async {
    if (!hasMore || isLoading || lastDocument == null) return;
    isLoading = true;

    final prefs = await SharedPreferences.getInstance();
    final deviceUid = prefs.getString('device_uid');
    if (deviceUid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('deviceUid', isEqualTo: deviceUid)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDocument!)
        .limit(20)
        .get();

    setState(() {
      myPosts.addAll(snapshot.docs);
      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }
      hasMore = snapshot.docs.length == 20;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 쓴 글')),
      body: isLoading && myPosts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.redPrimary))
          : myPosts.isEmpty
              ? const Center(child: Text('작성한 글이 없습니다.'))
              : ListView.separated(
                  itemCount: myPosts.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == myPosts.length) {
                      if (!hasMore) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('🎉 모든 글을 다 확인했어요!')),
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.redPrimary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                    }

                    final post = myPosts[index];
                    return _buildPostTile(context, post);
                  }),
    );
  }
}

Widget _buildPostTile(BuildContext context, DocumentSnapshot post) {
  final title = post['title'] ?? '제목 없음';
  final commentCount = post['commentCount'] ?? 0;
  final likesCount = post['likesCount'] ?? 0;
  final views = post['views'] ?? 0;
  final category = post['category'] ?? '카테고리 없음';
  final timestamp = (post['timestamp'] as Timestamp?)?.toDate();

  final timeText = timestamp != null
      ? DateFormat('yy.MM.dd HH:mm').format(timestamp.toLocal())
      : '';

  return ListTile(
    title: Row(
      children: [
        Text(title),
        if (commentCount > 0) ...[
          const SizedBox(width: 6),
          Text(
            '[$commentCount]',
            style: const TextStyle(color: AppColors.redPrimary),
          ),
        ],
      ],
    ),
    subtitle: Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text('$category 게시판 • 조회수 $views',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey)),
              if (likesCount > 0) ...[
                const Text(' • ', style: TextStyle(color: Colors.grey)),
                const Icon(Icons.thumb_up,
                    size: 16, color: AppColors.redPrimary),
                const SizedBox(width: 4),
                Text('$likesCount'),
              ],
            ],
          ),
        ),
        Text(
          timeText,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    ),
    onTap: () {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              PostDetailScreen(
            postId: post.id,
            category: category,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.scaled,
              child: child,
            );
          },
        ),
      );
    },
  );
}
