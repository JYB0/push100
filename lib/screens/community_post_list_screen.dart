import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/post_detail_screen.dart';
import 'package:push100/screens/post_write_screen.dart';

class CommunityPostListScreen extends StatefulWidget {
  final String category;

  const CommunityPostListScreen({super.key, required this.category});

  @override
  State<CommunityPostListScreen> createState() =>
      _CommunityPostListScreenState();
}

class _CommunityPostListScreenState extends State<CommunityPostListScreen> {
  final List<QueryDocumentSnapshot> posts = [];
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
          _scrollController.position.maxScrollExtent - 300) {
        _fetchMorePosts();
      }
    });
  }

  Future<void> _fetchInitialPosts() async {
    hasMore = true;
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('category', isEqualTo: widget.category)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    posts.clear();
    posts.addAll(snapshot.docs);

    if (snapshot.docs.isNotEmpty) {
      lastDocument = snapshot.docs.last;
    }
    hasMore = snapshot.docs.length == 20;
    setState(() {});
  }

  Future<void> _fetchMorePosts() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('category', isEqualTo: widget.category)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDocument!)
          .limit(20)
          .get();

      posts.addAll(snapshot.docs);

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }
      if (snapshot.docs.length < 20) {
        hasMore = false;
      }
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} 게시판'),
      ),
      body: CustomRefreshIndicator(
        onRefresh: _fetchInitialPosts,
        offsetToArmed: 80,
        builder: (context, child, controller) {
          double progress = controller.value.clamp(0.0, 1.0);
          double minFontSize = 20;
          double maxFontSize = 40;
          double fontSize =
              minFontSize + (maxFontSize - minFontSize) * progress;
          double opacity = progress;

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              child,
              if (controller.value > 0)
                Positioned(
                  top: 30,
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      'Push100',
                      style: GoogleFonts.bebasNeue(
                        color: AppColors.redPrimary,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: posts.isEmpty
            ? const Center(child: Text('아직 작성된 글이 없습니다.'))
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == posts.length) {
                    // ⭐️ 마지막에 로딩 또는 "다 읽었습니다" 문구 표시
                    if (hasMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.redPrimary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            '🎉 모든 글을 다 읽었습니다!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  final post = posts[index];
                  final title = post['title'] ?? '제목 없음';
                  final likesCount = post['likesCount'] ?? 0;
                  final views = post['views'] ?? 0;
                  final commentCount = post['commentCount'] ?? 0;
                  final nickname = post['nickname'] ?? '익명';
                  final timestamp = (post['timestamp'] as Timestamp?)?.toDate();

                  return ListTile(
                    title: Row(
                      children: [
                        Text(title),
                        if (commentCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '[$commentCount]',
                            style: const TextStyle(
                              color: AppColors.redPrimary, // 🔥 댓글 수 빨간색
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                '$nickname • 조회수 $views',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.grey), // 💬 서브텍스트 회색
                              ),
                              if (likesCount > 0) ...[
                                const Text(
                                  ' • ',
                                  style: TextStyle(color: Colors.grey),
                                ),
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
              ),
      ),

      // 🔘 글 작성 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.redPrimary,
        onPressed: () async {
          final result = await Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PostWriteScreen(
                category: widget.category,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
            ),
          );
          if (result == true) {
            _fetchInitialPosts();
          }
        },
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
    );
  }
}
