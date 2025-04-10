import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push100'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 검색바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategorySearchScreen(),
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
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = data[index];
                        return ListTile(
                          title: Text("${index + 1}. ${item['name']} 게시판"),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityPostListScreen(
                                    category: item['name']),
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
            FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchTodayPopularPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: AppColors.redPrimary,
                  ));
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('오늘 올라온 인기 글이 없습니다.'),
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
                      child: Text("👑 오늘의 인기 글",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return ListTile(
                          title: Text(post['title'] ?? '제목 없음'),
                          subtitle: Text(
                            '${post['category'] ?? '익명'} 게시판 • 조회수 ${post['views'] ?? 0}',
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
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      // ➕ 카테고리 생성 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.redPrimary,
        onPressed: _showCreateCategoryDialog,
        child: const Icon(
          Icons.add,
          color: Colors.white,
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

  void _showCreateCategoryDialog() async {
    final contextMounted = context.mounted;

    final result = await showTextInputDialog(
      context: context,
      title: '새 카테고리 생성',
      textFields: const [
        DialogTextField(
          hintText: '카테고리 이름',
        ),
      ],
      okLabel: '생성',
      cancelLabel: '취소',
    );

    if (result == null || result.isEmpty) return;

    final newCategory = result.first.trim();
    final normalizedNewCategory = newCategory.toLowerCase();

    // Firestore에서 중복 확인
    final snapshot = await FirebaseFirestore.instance.collection('posts').get();

    final existingCategories = snapshot.docs
        .map((doc) => (doc['category'] as String?)?.trim().toLowerCase())
        .whereType<String>()
        .toSet();

    if (existingCategories.contains(normalizedNewCategory)) {
      if (!mounted) return;
      if (contextMounted) {
        showOkAlertDialog(
          context: context,
          title: '중복된 카테고리',
          message: '이미 존재하는 카테고리입니다.',
        );
      }
      return;
    }

    // 새 카테고리 생성
    await FirebaseFirestore.instance.collection('posts').add({
      'category': newCategory,
      'title': newCategory,
      'content': '첫 글',
      'nickname': '관리자',
      'views': 0,
      'likes': 0,
      'dislikes': 0,
      'timestamp': Timestamp.now(),
    });

    if (contextMounted) {
      setState(() {}); // 리스트 갱신
    }
  }
}

Future<List<DocumentSnapshot>> _fetchTodayPopularPosts() async {
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);

  final snapshot = await FirebaseFirestore.instance
      .collection('posts')
      .where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayMidnight))
      .orderBy('timestamp', descending: true) // 최신 글 먼저
      .limit(50)
      .get();

// 클라이언트에서 정렬
  final sorted = snapshot.docs
    ..sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));

  return sorted.take(10).toList(); // 조회수 순 인기글 10개
}
