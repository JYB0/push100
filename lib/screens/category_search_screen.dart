import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/community_post_list_screen.dart';

class CategorySearchScreen extends StatefulWidget {
  const CategorySearchScreen({super.key});

  @override
  State<CategorySearchScreen> createState() => _CategorySearchScreenState();
}

class _CategorySearchScreenState extends State<CategorySearchScreen> {
  String searchQuery = '';
  List<String> allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _showCreateCategoryDialog() async {
    final contextMounted = context.mounted;

    final result = await showTextInputDialog(
      context: context,
      title: '새 카테고리 생성',
      textFields: const [
        DialogTextField(
          hintText: '카테고리 이름',
          maxLength: 13,
        ),
      ],
      okLabel: '생성',
      cancelLabel: '취소',
      isDestructiveAction: true,
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
      'title': '첫 생성글',
      'content': '첫 글',
      'nickname': '관리자',
      'views': 0,
      'likesCount': 0, // 좋아요 수
      'commentCount': 0, // 댓글 수
      'timestamp': Timestamp.now(),
      'deviceUid': 'admin', // 관리자 고정값
      'reportCount': 5,
    });

    if (contextMounted) {
      // ✅ 생성 완료 후 바로 해당 카테고리 게시판으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) =>
                CommunityPostListScreen(category: newCategory),
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
      }
    }
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('posts').get();

    final categories = snapshot.docs
        .map((doc) => doc['category'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      allCategories = categories.cast<String>();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = allCategories
        .where((c) => c.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("카테고리 검색")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              // cursorColor: AppColors.yellowPrimary,
              decoration: const InputDecoration(
                hintText: '카테고리 입력',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.redPrimary,
                    width: 1,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('검색 결과가 없습니다.'),
                      SizedBox(height: 12),
                      Text(
                        '원하시는 카테고리가 없다면\n아래 + 버튼을 눌러 생성해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return ListTile(
                        title: Text('$category 게시판'),
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 400),
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  CommunityPostListScreen(category: category),
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
          ),
        ],
      ),
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
}
