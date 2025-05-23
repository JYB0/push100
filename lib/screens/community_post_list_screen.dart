import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:push100/helpers/ad_helper.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/post_detail_screen.dart';
import 'package:push100/screens/post_search_screen.dart';
import 'package:push100/screens/post_write_screen.dart';
import 'package:push100/widgets/inline_adaptive_ad_widget.dart';

class CommunityPostListScreen extends StatefulWidget {
  final String category;

  const CommunityPostListScreen({super.key, required this.category});

  @override
  State<CommunityPostListScreen> createState() =>
      _CommunityPostListScreenState();
}

class _CommunityPostListScreenState extends State<CommunityPostListScreen>
    with TickerProviderStateMixin {
  final List<QueryDocumentSnapshot> posts = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInitialPosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _fetchMorePosts();
      }
    });
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchInitialPosts(); // 탭 바꿀 때 다시 로드
      }
    });
  }

  Future<void> _fetchInitialPosts() async {
    hasMore = true;
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('category', isEqualTo: widget.category)
        .where('reportCount', isLessThan: 5);

    if (_tabController.index == 1) {
      // 베스트 탭
      query = query.where('likesCount', isGreaterThanOrEqualTo: 5);
    }

    query = query.orderBy('timestamp', descending: true).limit(20);

    final snapshot = await query.get();

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
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('category', isEqualTo: widget.category)
          .where('reportCount', isLessThan: 5);

      if (_tabController.index == 1) {
        query = query.where('likesCount', isGreaterThanOrEqualTo: 5);
      }

      query = query.orderBy('timestamp', descending: true);

      if (lastDocument != null) {
        final lastTimestamp = lastDocument!['timestamp'];
        query = query.startAfter([lastTimestamp]);
      }

      query = query.limit(20);

      // query = query
      //     .orderBy('timestamp', descending: true)
      //     .startAfterDocument(lastDocument!)
      //     .limit(20);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore = false; // 🔒 문서 없으면 무조건 중단
      } else {
        posts.addAll(snapshot.docs);
        lastDocument = snapshot.docs.last;
        if (snapshot.docs.length < 20) {
          hasMore = false; // 🔒 더 가져올 게 없으면 중단
        }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PostSearchScreen(category: widget.category),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SharedAxisTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType
                          .horizontal, // 🔁 여기 타입만 바꾸면 됨
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.redPrimary,
            labelColor: AppColors.redPrimary,
            unselectedLabelColor: Colors.grey,
            tabs: const [Tab(text: '전체'), Tab(text: '베스트')]),
      ),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await _fetchInitialPosts();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('새로고침 완료!'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
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
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height:
                        MediaQuery.of(context).size.height * 0.5, // 화면 중간쯤 오게
                    child: Center(
                      child: Text(
                        _tabController.index == 1
                            ? '아직 베스트 글이 없습니다.\n첫 번째 주인공이 되어보세요!'
                            : '아직 작성된 글이 없습니다.\n첫 번째 주인공이 되어보세요!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: posts.length + 1,
                itemBuilder: (context, index) {
                  if (index == posts.length) {
                    // 마지막 로딩 또는 완료 메시지
                    return hasMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.redPrimary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : const Padding(
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

                  final post = posts[index];
                  final title = post['title'] ?? '제목 없음';
                  final commentCount = post['commentCount'] ?? 0;
                  final nickname = post['nickname'] ?? '익명';
                  final views = post['views'] ?? 0;
                  final likesCount = post['likesCount'] ?? 0;
                  final timestamp = (post['timestamp'] as Timestamp?)?.toDate();
                  final timeText = timestamp != null
                      ? DateFormat('HH:mm').format(timestamp.toLocal())
                      : '';

                  final listTile = ListTile(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                '$nickname • 조회수 $views',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (likesCount > 0) ...[
                                const Text(' • ',
                                    style: TextStyle(color: Colors.grey)),
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
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 400),
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
                              transitionType: SharedAxisTransitionType
                                  .scaled, // 또는 .horizontal
                              child: child,
                            );
                          },
                        ),
                      );
                      if (result == true) {
                        await _fetchInitialPosts();
                      }
                    },
                  );

                  if ((index - 11) % 20 == 0) {
                    final adUnitIds = AdHelper.adaptiveBannerAdUnitIds;
                    final adUnitId = adUnitIds[index % adUnitIds.length];

                    return Column(
                      children: [
                        InlineAdaptiveAdWidget(adUnitId: adUnitId), // 광고 위젯 삽입
                        listTile,
                      ],
                    );
                  }

                  return listTile;
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
