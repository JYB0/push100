import 'package:flutter/material.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:push100/main.dart';
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

  final englishFilter = ProfanityFilter();
  final koreanFilter = ProfanityFilter.filterAdditionally([
    '강간',
    '개새끼',
    '개자식',
    '개좆',
    '개차반',
    '거유',
    '계집년',
    '고자',
    '근친',
    '노모',
    '니기미',
    '뒤질래',
    '딸딸이',
    '때씹',
    '또라이',
    '뙤놈',
    '로리타',
    '망가',
    '몰카',
    '미친',
    '미친새끼',
    '바바리맨',
    '변태',
    '병신',
    '보지',
    '불알',
    '빠구리',
    '사까시',
    '섹스',
    '스와핑',
    '쌍놈',
    '씨발',
    '씨발놈',
    '씨팔',
    '씹',
    '씹물',
    '씹빨',
    '씹새끼',
    '씹알',
    '씹창',
    '씹팔',
    '암캐',
    '애자',
    '야동',
    '야사',
    '야애니',
    '엄창',
    '에로',
    '염병',
    '옘병',
    '유모',
    '육갑',
    '은꼴',
    '자위',
    '자지',
    '잡년',
    '종간나',
    '좆',
    '좆만',
    '죽일년',
    '쥐좆',
    '직촬',
    '짱깨',
    '쪽바리',
    '창녀',
    '포르노',
    '하드코어',
    '호로',
    '화냥년',
    '후레아들',
    '후장',
    '희쭈그리',
  ]);

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

    if (englishFilter.hasProfanity(_nicknameController.text) ||
        englishFilter.hasProfanity(_titleController.text) ||
        englishFilter.hasProfanity(_contentController.text) ||
        koreanFilter.hasProfanity(_nicknameController.text) ||
        koreanFilter.hasProfanity(_titleController.text) ||
        koreanFilter.hasProfanity(_contentController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('욕설이나 부적절한 내용이 포함되어 있습니다.')),
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
          Navigator.of(context).pop(true);
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
      appBar: AppBar(
        title: const Text('글쓰기'),
        actions: [
          IconButton(
            onPressed: _submitPost,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: AppColors.redPrimary,
              ))
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            hintText: '닉네임',
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.redPrimary),
                            ),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: '비밀번호',
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.redPrimary),
                            ),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '제목',
                      // labelText: '제목',
                      // focusedBorder: OutlineInputBorder(
                      //   borderSide: BorderSide(color: AppColors.redPrimary),
                      // ),
                      // border: OutlineInputBorder(),
                      // isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '내용',
                        alignLabelWithHint: true, // 여러 줄 텍스트일 때 레이블 위치 정렬
                        // border: OutlineInputBorder(),
                        // focusedBorder: OutlineInputBorder(
                        //   borderSide: BorderSide(
                        //       color: AppColors.redPrimary), // 포커스시 빨간색
                        // ),
                      ),
                      keyboardType: TextInputType.multiline,
                      maxLines: null, // 무제한 줄
                      expands: true, // 📢 요게 포인트!! => 빈공간을 모두 채움
                      textAlignVertical: TextAlignVertical.top, // 🔥 요거 추가!!
                    ),
                  ),
                  const SizedBox(height: 50),
                  // ElevatedButton(
                  //   onPressed: _submitPost,
                  //   child: const Text('작성하기'),
                  // ),
                ],
              ),
      ),
    );
  }
}
