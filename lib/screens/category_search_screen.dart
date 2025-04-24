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
                ? const Center(child: Text('검색 결과가 없습니다.'))
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
        ],
      ),
    );
  }
}
