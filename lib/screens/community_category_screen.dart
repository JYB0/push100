import 'package:animations/animations.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/category_search_screen.dart';
import 'package:push100/screens/community_post_list_screen.dart';
import 'package:collection/collection.dart';
import 'package:push100/screens/post_detail_screen.dart';

class CommunityCategoryScreen extends StatefulWidget {
  const CommunityCategoryScreen({super.key});

  @override
  State<CommunityCategoryScreen> createState() =>
      _CommunityCategoryScreenState();
}

class _CommunityCategoryScreenState extends State<CommunityCategoryScreen> {
  final List<DocumentSnapshot> todayPopularPosts = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialTodayPosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _fetchMoreTodayPosts();
      }
    });
  }

  Future<void> _fetchInitialTodayPosts() async {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight))
        .orderBy('views', descending: true)
        .limit(20)
        .get();

    todayPopularPosts.clear();
    todayPopularPosts.addAll(
      snapshot.docs.where((doc) => (doc['views'] ?? 0) >= 10),
    );

    if (snapshot.docs.isNotEmpty) {
      lastDocument = snapshot.docs.last;
    }

    hasMore = snapshot.docs.length == 20;
    setState(() {});
  }

  Future<void> _fetchMoreTodayPosts() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight))
        .orderBy('views', descending: true)
        .startAfterDocument(lastDocument!)
        .limit(20)
        .get();

    todayPopularPosts.addAll(snapshot.docs);

    if (snapshot.docs.isNotEmpty) {
      lastDocument = snapshot.docs.last;
    }
    if (snapshot.docs.length < 20) {
      hasMore = false;
    }
    isLoading = false;

    setState(() {});
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
        title: const Text('Push100'),
      ),
      body: CustomRefreshIndicator(
        onRefresh: _fetchInitialTodayPosts,
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
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 검색바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const CategorySearchScreen(),
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
                  },
                  child: const AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '카테고리 검색',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 카테고리 랭킹 리스트
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchCategoryRanking(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                      color: AppColors.redPrimary,
                    ));
                  }

                  final data = snapshot.data ?? [];

                  if (data.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('카테고리가 없습니다.'),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text("🔥 인기 카테고리",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.length > 3 ? 3 : data.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = data[index];
                          return ListTile(
                            title: Text("${index + 1}. ${item['name']} 게시판"),
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      CommunityPostListScreen(
                                          category: item['name']),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return SharedAxisTransition(
                                      animation: animation,
                                      secondaryAnimation: secondaryAnimation,
                                      transitionType:
                                          SharedAxisTransitionType.scaled,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // 🔥 오늘 인기 게시글
              // 🔥 오늘 인기 글 파트
              if (todayPopularPosts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('오늘 올라온 인기 글이 없습니다.'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "👑 오늘의 인기 글",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayPopularPosts.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final post = todayPopularPosts[index];
                        final title = post['title'] ?? '제목 없음';
                        final commentCount = post['commentCount'] ?? 0;
                        final likesCount = post['likesCount'] ?? 0;
                        final views = post['views'] ?? 0;
                        final category = post['category'] ?? '익명';
                        final timestamp =
                            (post['timestamp'] as Timestamp?)?.toDate();

                        return ListTile(
                          title: Row(
                            children: [
                              Text(title),
                              if (commentCount > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '[$commentCount]',
                                  style: const TextStyle(
                                      color: AppColors.redPrimary),
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
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    if (likesCount > 0) ...[
                                      const Text(' • ',
                                          style: TextStyle(color: Colors.grey)),
                                      const Icon(Icons.thumb_up,
                                          size: 16,
                                          color: AppColors.redPrimary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$likesCount',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  DateFormat('HH:mm')
                                      .format(timestamp.toLocal()),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        PostDetailScreen(
                                  postId: post.id,
                                  category: post['category'] ?? '카테고리 없음',
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return SharedAxisTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    transitionType:
                                        SharedAxisTransitionType.scaled,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCategoryRanking() async {
    final snapshot = await FirebaseFirestore.instance.collection('posts').get();

    // 🔄 카테고리별 글 모음
    Map<String, List<QueryDocumentSnapshot>> categoryPosts = {};

    for (var doc in snapshot.docs) {
      final category = doc['category'] ?? '';
      if (category.isEmpty) continue;

      categoryPosts.putIfAbsent(category, () => []);
      categoryPosts[category]!.add(doc);
    }

    // 🔢 정렬 기준: 최근 10개의 조회수 합산
    final result = categoryPosts.entries.map((entry) {
      final recent = entry.value
          .sorted((a, b) => (b['timestamp'] as Timestamp)
              .compareTo(a['timestamp'] as Timestamp))
          .take(10)
          .toList();

      final viewSum = recent.fold<int>(
        0,
        (prev, doc) => prev + (doc['views'] as int? ?? 0),
      );

      return {
        'name': entry.key,
        'views': viewSum,
      };
    }).toList();

    result.sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

    return result;
  }
}
