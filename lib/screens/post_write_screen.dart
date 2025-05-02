import 'dart:async';

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

  final RegExp koreanBadWordPattern = RegExp(
    r'[시씨슈쓔쉬쉽쒸쓉]([0-9]*|[0-9]+ *)[바발벌빠빡빨뻘파팔펄]|개[쒜쓉애]*[끼|새기]|느금|걸래[0-9]*[년뇬]|개\s*같은\s*(년|뇬)|개같은(년|뇬)|엿 먹어|ㅗ|[지즤]([0-9]*|[0-9]+ *)[랄뢀]|또라이|[섊좆좇졷좄좃좉졽썅춍]|ㅅㅣㅂㅏㄹ?|ㅂ[0-9]*ㅅ|[ㅄᄲᇪᄺᄡᄣᄦᇠ]|[ㅅㅆᄴ][0-9]*[ㄲㅅㅆᄴㅂ]|[존좉좇][0-9 ]*나|[자보][0-9]+지|보빨|[봊봋봇봈볻봁봍] *[빨이]|[후훚훐훛훋훗훘훟훝훑][장앙]|후빨|[엠앰]창|애[미비]|애자|[^탐]색기|([샊샛세쉐쉑쉨쉒객갞갟갯갰갴겍겎겏겤곅곆곇곗곘곜걕걖걗걧걨걬] *[끼키퀴])|새 *[키퀴]|[병븅]신|미친[가-닣닥-힣]|[믿밑]힌|[염옘]병|[샊샛샜샠섹섺셋셌셐셱솃솄솈섁섂섓섔섘]기|[섹섺섻쎅쎆쎇쎽쎾쎿섁섂섃썍썎썏][스쓰]|지랄|니[애에]미|갈[0-9]*보[^가-힣]|[뻐뻑뻒뻙뻨][0-9]*[뀨큐킹낑)|꼬추|곧휴|[가-힣]슬아치|자박꼼|[병븅]딱|빨통|[사싸](이코|가지|까시)|육시[랄럴]|육실[알얼할헐]|즐[^가-힣]|찌(질이|랭이)|찐따|찐찌버거|창[녀놈]|[가-힣]{2,}충[^가-힣]|[가-힣]{2,}츙|부녀자|화냥년|환[양향]년|호[구모]|조[선센][징]|조센|[쪼쪽쪾]([발빨]이|[바빠]리)|盧|무현|찌끄[레래]기|(하악){2,}|하[앍앜]|[낭당랑앙항남담람암함][ ]?[가-힣]+[띠찌]|느[금급]마|文在|在寅|(?<=[^\n])[家哥]|속냐|[tT]l[qQ]kf|Wls',
    caseSensitive: false,
  );

  /// 사용 예시
  bool containsBadWords(String text) {
    return englishFilter.hasProfanity(text) ||
        koreanFilter.hasProfanity(text) ||
        koreanBadWordPattern.hasMatch(text);
  }

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

    if (containsBadWords(_nicknameController.text) ||
        containsBadWords(_titleController.text) ||
        containsBadWords(_contentController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('욕설이나 부적절한 내용이 포함되어 있습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirestoreService.uploadPost(
        category: widget.category,
        nickname: _nicknameController.text,
        password: _passwordController.text,
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: null,
        deviceUid: _deviceUid!,
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 글이 성공적으로 작성되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('업로드 시간이 너무 오래 걸립니다. 네트워크 상태를 확인해주세요.')),
        );
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
            color: AppColors.redPrimary,
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
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.redPrimary),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: '내용',
                        alignLabelWithHint: true,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.redPrimary),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 1),
                        ),
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
