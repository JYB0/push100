import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:push100/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:push100/screens/post_detail_screen.dart';

class MyCommentsScreen extends StatefulWidget {
  const MyCommentsScreen({super.key});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  final List<DocumentSnapshot> commentedPosts = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool isFetchingMore = false;
  int _loadedCount = 0;
  List<String> allPostIds = [];
  Map<String, String> postCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCommentedPostIds().then((_) => _fetchMorePosts());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !isFetchingMore) {
        _fetchMorePosts();
      }
    });
  }

  Future<void> _loadCommentedPostIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceUid = prefs.getString('device_uid');

    if (deviceUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final Set<String> seenPostIds = {};
    final Map<String, String> categoryMap = {};

    final commentSnapshot = await FirebaseFirestore.instance
        .collectionGroup('comments')
        .where('deviceUid', isEqualTo: deviceUid)
        .orderBy('timestamp', descending: true)
        .get();

    for (final doc in commentSnapshot.docs) {
      final postId = doc['postId'];
      final category = doc['category'] ?? '카테고리 없음';
      if (seenPostIds.add(postId)) {
        allPostIds.add(postId);
        categoryMap[postId] = category;
      }
    }

    final replySnapshot = await FirebaseFirestore.instance
        .collectionGroup('replies')
        .where('deviceUid', isEqualTo: deviceUid)
        .orderBy('timestamp', descending: true)
        .get();

    for (final doc in replySnapshot.docs) {
      if (!doc.data().containsKey('postId')) continue;
      final postId = doc['postId'];
      final category = doc['category'] ?? '카테고리 없음';
      if (seenPostIds.add(postId)) {
        allPostIds.add(postId);
        categoryMap[postId] = category;
      }
    }

    postCategories = categoryMap;
  }

  Future<void> _fetchMorePosts() async {
    if (_loadedCount >= allPostIds.length) return;
    setState(() => isFetchingMore = true);

    final batch = allPostIds.skip(_loadedCount).take(20).map((id) async {
      final doc =
          await FirebaseFirestore.instance.collection('posts').doc(id).get();
      return doc.exists ? doc : null;
    }).toList();

    final results = await Future.wait(batch);
    commentedPosts.addAll(results.whereType<DocumentSnapshot>());
    _loadedCount += 20;

    setState(() {
      _isLoading = false;
      isFetchingMore = false;
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
      appBar: AppBar(title: const Text('댓글 단 게시글')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.redPrimary),
            )
          : commentedPosts.isEmpty
              ? const Center(child: Text('댓글을 단 게시글이 없습니다.'))
              : ListView.separated(
                  controller: _scrollController,
                  itemCount: commentedPosts.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == commentedPosts.length) {
                      if (_loadedCount >= allPostIds.length) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('🎉 모든 게시글을 확인했어요!')),
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

                    final post = commentedPosts[index];
                    return _buildCommentedPostTile(context, post);
                  },
                ),
    );
  }

  Widget _buildCommentedPostTile(BuildContext context, DocumentSnapshot post) {
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
        mainAxisSize: MainAxisSize.min, // Row 너비 최소화
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
                Text(
                  '$category 게시판 • 조회수 $views',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
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
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
}
