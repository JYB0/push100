import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push100/screens/category_search_screen.dart';
import 'package:push100/screens/community_post_list_screen.dart';
import 'package:collection/collection.dart';

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
                  return const Center(child: CircularProgressIndicator());
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
                      padding: EdgeInsets.symmetric(horizontal: 16),
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

            const SizedBox(height: 24),

            // 🔥 오늘 인기 게시글
            FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchTodayPopularPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("👑 오늘의 인기 글",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                                builder: (_) => CommunityPostListScreen(
                                    category: post['category']),
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
        onPressed: _showCreateCategoryDialog,
        child: const Icon(Icons.add),
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

  void _showCreateCategoryDialog() {
    String newCategory = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("새 카테고리 생성"),
        content: TextField(
          onChanged: (value) => newCategory = value,
          decoration: const InputDecoration(hintText: "카테고리 이름"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              final normalizedNewCategory = newCategory.trim().toLowerCase();

              if (normalizedNewCategory.isEmpty) return;

              // Firestore에서 모든 카테고리 가져오기
              final snapshot =
                  await FirebaseFirestore.instance.collection('posts').get();

              final existingCategories = snapshot.docs
                  .map((doc) =>
                      (doc['category'] as String?)?.trim().toLowerCase())
                  .whereType<String>()
                  .toSet();

              if (existingCategories.contains(normalizedNewCategory)) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이미 존재하는 카테고리입니다.')),
                  );
                }
                return;
              }

              // 새 카테고리 생성
              await FirebaseFirestore.instance.collection('posts').add({
                'category': newCategory.trim(), // 저장은 원본대로
                'title': newCategory,
                'content': '첫 글',
                'nickname': '관리자',
                'views': 0,
                'likes': 0,
                'dislikes': 0,
                'timestamp': Timestamp.now(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                setState(() {}); // 다시 불러오기
              }
            },
            child: const Text("생성"),
          ),
        ],
      ),
    );
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

  print("🔥 오늘 인기글 수: ${snapshot.docs.length}");
  return sorted.take(10).toList(); // 조회수 순 인기글 10개
}
