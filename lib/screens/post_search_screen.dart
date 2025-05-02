import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/post_detail_screen.dart';
import 'package:animations/animations.dart';

class PostSearchScreen extends StatefulWidget {
  final String category;

  const PostSearchScreen({super.key, required this.category});

  @override
  State<PostSearchScreen> createState() => _PostSearchScreenState();
}

class _PostSearchScreenState extends State<PostSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> results = [];
  DocumentSnapshot? lastDoc;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search({bool isNewSearch = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (isNewSearch) {
      results.clear();
      lastDoc = null;
      hasMore = true;
    }

    if (!hasMore || isLoading) return;
    setState(() => isLoading = true);

    Query baseQuery = FirebaseFirestore.instance
        .collection('posts')
        .where('category', isEqualTo: widget.category)
        .orderBy('timestamp', descending: true)
        .limit(20);

    if (lastDoc != null) {
      baseQuery = baseQuery.startAfterDocument(lastDoc!);
    }

    final snapshot = await baseQuery.get();

    final filtered = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title']?.toString().toLowerCase() ?? '';
      final content = data['content']?.toString().toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
          content.contains(query.toLowerCase());
    }).toList();

    results.addAll(filtered);
    if (snapshot.docs.isNotEmpty) lastDoc = snapshot.docs.last;
    if (snapshot.docs.length < 20) hasMore = false;

    setState(() => isLoading = false);
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('HH:mm').format(timestamp.toDate().toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '검색어 입력',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(isNewSearch: true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(isNewSearch: true),
          )
        ],
      ),
      body: Column(
        children: [
          if (results.isEmpty && !isLoading)
            const Expanded(
              child: Center(
                child: Text('검색 결과가 없습니다.'),
              ),
            ),
          if (results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: results.length + 1,
                itemBuilder: (context, index) {
                  if (index == results.length) {
                    if (!hasMore) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            '🎉 모든 글을 검색하였습니다!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    } else {
                      _search();
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

                  final post = results[index];
                  final data = post.data() as Map<String, dynamic>;
                  final title = data['title'] ?? '';
                  final nickname = data['nickname'] ?? '익명';
                  final views = data['views'] ?? 0;
                  final likes = data['likesCount'] ?? 0;
                  final comments = data['commentCount'] ?? 0;
                  final timestamp = data['timestamp'] as Timestamp?;

                  return ListTile(
                    title: Row(
                      children: [
                        Text(title),
                        if (comments > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '[$comments]',
                            style: const TextStyle(
                              color: AppColors.redPrimary,
                            ),
                          ),
                        ]
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
                              if (likes > 0) ...[
                                const Text(' • ',
                                    style: TextStyle(color: Colors.grey)),
                                const Icon(Icons.thumb_up,
                                    size: 16, color: AppColors.redPrimary),
                                const SizedBox(width: 4),
                                Text('$likes'),
                              ]
                            ],
                          ),
                        ),
                        Text(
                          formatTime(timestamp),
                          style: const TextStyle(color: Colors.grey),
                        )
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
                            category: widget.category,
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

                      if (result == true) {
                        setState(() {
                          results.removeAt(index);
                        });
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
