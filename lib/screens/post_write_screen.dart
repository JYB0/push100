import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/community_post_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

class PostWriteScreen extends StatefulWidget {
  final String category; // 선택된 카테고리

  const PostWriteScreen({super.key, required this.category});

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isLoading = false;
  String? _deviceUid;

  @override
  void initState() {
    super.initState();
    _loadDeviceUid();
  }

  Future<void> _loadDeviceUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _deviceUid = prefs.getString('device_uid');
    });
  }

  Future<void> _submitPost() async {
    if (_nicknameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // print('🔵 업로드 시작');

    try {
      await FirestoreService.uploadPost(
        category: widget.category,
        nickname: _nicknameController.text,
        password: _passwordController.text,
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: null,
        deviceUid: _deviceUid!,
      );
      // print('🟢 업로드 완료');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 글이 성공적으로 작성되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  CommunityPostListScreen(category: widget.category),
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
            (route) => false, // 모든 화면 제거 후 이동
          );
        }
      }
    } catch (e) {
      // print('🔴 업로드 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('글 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: AppColors.redPrimary,
              ))
            : Column(
                children: [
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: '닉네임'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '제목'),
                  ),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: '내용'),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitPost,
                    child: const Text('작성하기'),
                  ),
                ],
              ),
      ),
    );
  }
}
