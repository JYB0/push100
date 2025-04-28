import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:push100/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String category;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.category,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  // final _commentFocusScopeNode = FocusScopeNode();
  final _focusNode = FocusNode();
  late Future<List<QuerySnapshot>> _reactionFutures;
  DocumentSnapshot? _postSnapshot;
  bool _isTogglingReaction = false;

  bool _isCommenting = false;
  String? _replyToCommentId;
  String? _replyToNickname;
  String? _deviceUid;

  bool get isMyPost {
    final currentUid = _deviceUid;
    final postData = _postSnapshot?.data() as Map<String, dynamic>?;
    final postUid = postData?['deviceUid'];

    return currentUid != null && postUid != null && currentUid == postUid;
  }

  late Future<DocumentSnapshot> _postFuture;
  late Future<List<QueryDocumentSnapshot>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _increaseViewCount();

    _postFuture =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
    _commentsFuture = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .get()
        .then((snapshot) => snapshot.docs);

    _loadDeviceUidAndInitReactions();
    _refreshData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showReplyTo(String commentId, String nickname) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToNickname = nickname;
      _isCommenting = true;
    });
    _focusNode.requestFocus();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();

    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .get();

    setState(() {
      _postSnapshot = snapshot; // ✅ 추가
      _commentsFuture = Future.value(commentsSnapshot.docs);
      _reactionFutures = _refreshReactions(); // 좋아요/싫어요도 같이
    });
  }

  Future<void> _reportPost() async {
    if (_deviceUid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('reports')
          .doc(_deviceUid) // 한 디바이스당 1번만 신고 가능
          .set({
        'timestamp': FieldValue.serverTimestamp(),
        'reason': '사용자가 신고 버튼을 눌렀습니다', // 필요하면 나중에 상세 사유 선택 추가 가능
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고가 접수되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고 처리 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _deletePost() async {
    final result = await showTextInputDialog(
      context: context,
      title: '게시글 삭제',
      message: '게시글을 삭제하려면 비밀번호를 입력하세요.',
      textFields: const [
        DialogTextField(
          hintText: '비밀번호',
          obscureText: true,
        ),
      ],
      okLabel: '삭제',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );

    if (result == null || result.isEmpty) return;

    final inputPassword = result.first;
    final inputHash = sha256.convert(utf8.encode(inputPassword)).toString();
    final postData = _postSnapshot?.data() as Map<String, dynamic>?;
    final postPasswordHash = postData?['passwordHash'];

    if (inputHash != postPasswordHash) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 틀렸습니다.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
      Navigator.of(context).pop(true); // 삭제 후 뒤로가기
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
      );
    }
  }

  Future<void> _loadDeviceUidAndInitReactions() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceUid = prefs.getString('device_uid');

    if (!mounted) return;

    setState(() {
      _reactionFutures = _refreshReactions(); // ✅ 여기서 반드시 초기화
    });
  }

  Future<void> _increaseViewCount() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'views': FieldValue.increment(1)});
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text.trim();

    if (content.isEmpty || nickname.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('모든 입력란을 작성해주세요.'),
            duration: Duration(milliseconds: 600)),
      );
      return;
    }

    final hash = sha256.convert(utf8.encode(password)).toString();

    if (_replyToCommentId != null) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(_replyToCommentId)
          .collection('replies')
          .add({
        'content': content,
        'nickname': nickname,
        'passwordHash': hash,
        'timestamp': Timestamp.now(),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'content': content,
        'nickname': nickname,
        'passwordHash': hash,
        'timestamp': Timestamp.now(),
      });
    }

    _commentController.clear();
    _nicknameController.clear();
    _passwordController.clear();
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({
      'commentCount': FieldValue.increment(1),
    });

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _replyToCommentId = null;
      _replyToNickname = null;
      _isCommenting = false;
    });
    await _refreshData(); // ✅ 자동 새로고침
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 작성되었습니다.')),
      );
    }
  }

  Future<void> _deleteReplyComment(
      String parentId, String replyId, String storedHash) async {
    final result = await showTextInputDialog(
      context: context,
      title: '답글 삭제',
      message: '비밀번호를 입력하세요',
      textFields: const [
        DialogTextField(
          hintText: '비밀번호',
          obscureText: true,
        ),
      ],
      okLabel: '삭제',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );

    if (result == null || result.isEmpty) return;

    final inputHash = sha256.convert(utf8.encode(result.first)).toString();

    if (inputHash == storedHash) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(parentId)
          .collection('replies')
          .doc(replyId)
          .delete();

      // 댓글 삭제 완료 후에
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'commentCount': FieldValue.increment(-1),
      });

      await _refreshData(); // ✅ 자동 새로고침
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대댓글이 삭제되었습니다.')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 틀렸습니다.')),
      );
    }
  }

  Future<void> _togglePostLike() async {
    if (_deviceUid == null || _isTogglingReaction) return;
    _isTogglingReaction = true;
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final likeRef = postRef.collection('likes').doc(_deviceUid);
    final dislikeRef = postRef.collection('dislikes').doc(_deviceUid);

    final likeSnap = await likeRef.get();
    final postData = await postRef.get();
    final currentLikesCount = (postData.data()?['likesCount'] ?? 0) as int;
    if (likeSnap.exists) {
      await likeRef.delete();
      await postRef.update({
        'likesCount': currentLikesCount > 0 ? currentLikesCount - 1 : 0,
      });
    } else {
      await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
      await postRef.update({
        'likesCount': currentLikesCount + 1,
      });
      if ((await dislikeRef.get()).exists) {
        await dislikeRef.delete();
      }
    }
    _isTogglingReaction = false;
  }

  Future<void> _togglePostDislike() async {
    if (_deviceUid == null) return;
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final likeRef = postRef.collection('likes').doc(_deviceUid);
    final dislikeRef = postRef.collection('dislikes').doc(_deviceUid);

    final dislikeSnap = await dislikeRef.get();
    if (dislikeSnap.exists) {
      await dislikeRef.delete();
    } else {
      await dislikeRef.set({'timestamp': FieldValue.serverTimestamp()});
      if ((await likeRef.get()).exists) {
        await likeRef.delete();
      }
    }
  }

  Future<void> _deleteComment(String commentId, String storedHash) async {
    final result = await showTextInputDialog(
      context: context,
      title: '댓글 삭제',
      message: '비밀번호를 입력하세요',
      textFields: const [
        DialogTextField(
          hintText: '비밀번호',
          obscureText: true,
        ),
      ],
      okLabel: '삭제',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );

    // 취소하거나 아무것도 안 입력했을 때
    if (result == null || result.isEmpty) return;

    final input = result.first;
    final inputHash = sha256.convert(utf8.encode(input)).toString();

    if (inputHash == storedHash) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // 대댓글 삭제 완료 후에
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'commentCount': FieldValue.increment(-1),
      });

      await _refreshData(); // ✅ 자동 새로고침
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 삭제되었습니다.')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 틀렸습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final commentRef = FirebaseFirestore.instance
    //     .collection('posts')
    //     .doc(widget.postId)
    //     .collection('comments')
    //     .orderBy(
    //       'timestamp',
    //       descending: false,
    //     );

    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    double bottomPadding = 0;
    if (_replyToNickname != null && keyboardHeight > 0) {
      // 대댓글 + 키보드 올라옴
      bottomPadding = 150;
    } else if (_replyToNickname != null) {
      // 대댓글 중인데 키보드는 안 떠있음
      bottomPadding = 150;
    } else if (keyboardHeight > 0) {
      // 일반 댓글 작성 중
      bottomPadding = 130;
    } else {
      bottomPadding = 70;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('${widget.category} 게시판'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () async {
              final result = await showModalActionSheet<String>(
                context: context,
                title: '게시물 옵션',
                actions: [
                  const SheetAction(label: '신고하기', key: 'report'),
                  if (isMyPost) // 본인 글일 때만 삭제 버튼
                    const SheetAction(
                        label: '삭제하기',
                        key: 'delete',
                        isDestructiveAction: true),
                ],
              );

              if (result == 'report') {
                _reportPost();
              } else if (result == 'delete') {
                _deletePost();
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _isCommenting = false;
            _replyToCommentId = null;
            _replyToNickname = null;
          });
        },
        child: CustomRefreshIndicator(
          onRefresh: () async {
            await _refreshData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('새로고침 완료!'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          offsetToArmed: 80, // 새로고침 발동 거리
          builder: (context, child, controller) {
            double progress = controller.value.clamp(0.0, 1.0); // 0~1 고정

            double minFontSize = 20;
            double maxFontSize = 40;
            double fontSize =
                minFontSize + (maxFontSize - minFontSize) * progress;
            double opacity = progress; // 점점 선명해지게

            return Stack(
              alignment: Alignment.topCenter,
              children: [
                child,
                if (controller.value > 0)
                  Positioned(
                    top: 30,
                    child: Opacity(
                      opacity: opacity, // ✨ opacity 추가
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
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                children: [
                  // 📄 글 내용 표시
                  FutureBuilder<DocumentSnapshot>(
                    future: _postFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final data = snapshot.data!;
                      final title = data['title'] ?? '제목 없음';
                      final content = data['content'] ?? '';
                      final nickname = data['nickname'] ?? '익명';
                      final timestamp = data['timestamp']?.toDate();
                      final formattedTime = timestamp != null
                          ? DateFormat('yyyy.MM.dd HH:mm')
                              .format(timestamp.toLocal())
                          : '';
                      final views = data['views'] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('$nickname'),
                            const SizedBox(height: 8),
                            Text('조회수 $views • $formattedTime'),
                            const Divider(thickness: 1),
                            const SizedBox(height: 16),
                            Text(content),
                            const SizedBox(height: 32),
                            _buildPostReactionButtons(data),
                            const Divider(height: 0),
                          ],
                        ),
                      );
                    },
                  ),

                  // 💬 댓글 목록
                  FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                          color: AppColors.redPrimary,
                        ));
                      }

                      final comments = snapshot.data!;

                      if (comments.isEmpty) {
                        return const Center(child: Text('첫 댓글을 남겨주세요.'));
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final doc = comments[index];
                          final commentId = doc.id;
                          final content = doc['content'] ?? '';
                          final nickname = doc['nickname'] ?? '익명';
                          final passwordHash = doc['passwordHash'] ?? '';
                          final timestamp =
                              (doc['timestamp'] as Timestamp?)?.toDate();
                          final formattedTime = timestamp != null
                              ? DateFormat('yyyy.MM.dd HH:mm').format(timestamp)
                              : '';

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 👤 닉네임
                                Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        nickname,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final result =
                                              await showModalActionSheet<
                                                  String>(
                                            context: context,
                                            title: '댓글 옵션',
                                            actions: [
                                              const SheetAction(
                                                  label: '답글 달기', key: 'reply'),
                                              const SheetAction(
                                                  label: '삭제하기',
                                                  key: 'delete',
                                                  isDestructiveAction: true),
                                            ],
                                          );

                                          if (result == 'reply') {
                                            _showReplyTo(commentId, nickname);
                                          } else if (result == 'delete') {
                                            _deleteComment(
                                                commentId, passwordHash);
                                          }
                                        },
                                        child: const Icon(Icons.more_horiz),
                                      )
                                    ],
                                  ),
                                ),
                                // 💬 콘텐츠
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(content),
                                ),

                                // 🕒 시간
                                Text(
                                  formattedTime,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),

                                // 대댓글
                                FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .collection('comments')
                                      .doc(commentId)
                                      .collection('replies')
                                      .orderBy('timestamp')
                                      .get(),
                                  builder: (context, replySnapshot) {
                                    if (!replySnapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }

                                    final replies = replySnapshot.data!.docs;

                                    if (replies.isEmpty) {
                                      return const SizedBox();
                                    } // 또는 null

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: replies.length,
                                      itemBuilder: (context, replyIndex) {
                                        final reply = replies[replyIndex];
                                        final replyContent =
                                            reply['content'] ?? '';
                                        final replyNickname =
                                            reply['nickname'] ?? '익명';
                                        final replyTimestamp =
                                            (reply['timestamp'] as Timestamp?)
                                                ?.toDate();
                                        final replyTimeFormatted =
                                            replyTimestamp != null
                                                ? DateFormat('yyyy.MM.dd HH:mm')
                                                    .format(replyTimestamp)
                                                : '';

                                        return Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 5),
                                              child: Container(
                                                height: 1,
                                                color: Colors.grey[300],
                                              ),
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 7),
                                                  child: Icon(
                                                    Icons
                                                        .subdirectory_arrow_right, // 또는 Icons.reply
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      right: 12,
                                                      left: 4,
                                                      top: 8,
                                                      bottom: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // 닉네임 + 아이콘
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              replyNickname,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () async {
                                                                final result =
                                                                    await showModalActionSheet<
                                                                        String>(
                                                                  context:
                                                                      context,
                                                                  title:
                                                                      '답글 옵션',
                                                                  actions: [
                                                                    const SheetAction(
                                                                      label:
                                                                          '삭제',
                                                                      key:
                                                                          'delete',
                                                                      isDestructiveAction:
                                                                          true,
                                                                    ),
                                                                  ],
                                                                );

                                                                if (result ==
                                                                    'delete') {
                                                                  _deleteReplyComment(
                                                                    commentId,
                                                                    reply.id,
                                                                    reply[
                                                                        'passwordHash'],
                                                                  );
                                                                }
                                                              },
                                                              child: const Icon(
                                                                  Icons
                                                                      .more_horiz), // 👈 more icon 사용
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(replyContent),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          replyTimeFormatted,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: _buildCommentInputArea(),
    );
  }

  Widget _buildPostReactionButtons(DocumentSnapshot postData) {
    if (_deviceUid == null) {
      return const SizedBox(); // 로딩 중일 때 아무것도 안 보여줌
    }

    return FutureBuilder<List<QuerySnapshot>>(
      future: _reactionFutures,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink(); // ❌ 로딩 인디케이터 제거
        }

        final likes = snapshot.data![0].docs.length;
        final dislikes = snapshot.data![1].docs.length;

        final hasLiked =
            snapshot.data![0].docs.any((doc) => doc.id == _deviceUid);
        final hasDisliked =
            snapshot.data![1].docs.any((doc) => doc.id == _deviceUid);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.thumb_up,
                color: hasLiked ? AppColors.redPrimary : null,
              ),
              onPressed: () async {
                await _togglePostLike();
                setState(() {
                  _reactionFutures = _refreshReactions();
                });
              },
            ),
            Text('$likes'),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                Icons.thumb_down,
                color: hasDisliked ? AppColors.bluePrimary : null,
              ),
              onPressed: () async {
                await _togglePostDislike();
                setState(() {
                  _reactionFutures = _refreshReactions();
                });
              },
            ),
            Text('$dislikes'),
          ],
        );
      },
    );
  }

  Future<List<QuerySnapshot>> _refreshReactions() {
    return Future.wait([
      FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('likes')
          .get(),
      FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('dislikes')
          .get(),
    ]);
  }

  Widget _buildCommentInputArea() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isKeyboardOpen ? 0 : MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Container(
        color: AppColors.greyPrimary,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isCommenting) ...[
              if (_replyToNickname != null)
                Container(
                  width: double.infinity,
                  // padding:
                  //     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 10),
                  // decoration: BoxDecoration(
                  //   // color: Colors.red.shade50, // 은은한 빨강 배경
                  //   borderRadius: BorderRadius.circular(8),
                  //   border: Border.all(
                  //     color: AppColors.redPrimary,
                  //     width: 0.8,
                  //   ),
                  // ),
                  child: Row(
                    children: [
                      Text(
                        '$_replyToNickname님에게 답글',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.redPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyToCommentId = null;
                            _replyToNickname = null;
                          });
                        },
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
                      )
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.redPrimary,
                              width: 1,
                            ),
                          ),
                          hintText: '닉네임',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.redPrimary,
                              width: 1,
                            ),
                          ),
                          hintText: '비밀번호',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    onTap: () {
                      setState(() {
                        _isCommenting = true;
                      });
                    },
                    minLines: 1,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.redPrimary,
                          width: 1,
                        ),
                      ),
                      hintText: '댓글 입력...',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.redPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
