import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
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

  bool _isCommenting = false;
  String? _replyToCommentId;
  String? _replyToNickname;
  String? _deviceUid;

  @override
  void initState() {
    super.initState();
    _increaseViewCount();
    _loadDeviceUid();
    // patchOldPosts();
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

  Future<void> _increaseViewCount() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'views': FieldValue.increment(1)});
  }

  // Future<void> _updateReaction(String field) async {
  //   await FirebaseFirestore.instance
  //       .collection('posts')
  //       .doc(widget.postId)
  //       .update({field: FieldValue.increment(1)});
  // }

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
        'likes': 0,
        'passwordHash': hash,
        'likedBy': [],
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
        'likes': 0,
        'likedBy': [],
        'timestamp': Timestamp.now(),
      });
    }

    _commentController.clear();
    _nicknameController.clear();
    _passwordController.clear();

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _replyToCommentId = null;
      _replyToNickname = null;
      _isCommenting = false;
    });
    // setState(() {
    //   _isCommenting = false;
    // });
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
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 틀렸습니다.')),
      );
    }
  }

  // Future<void> patchOldPosts() async {
  //   final posts = await FirebaseFirestore.instance.collection('posts').get();

  //   for (var doc in posts.docs) {
  //     final data = doc.data();
  //     final updates = <String, dynamic>{};

  //     if (!data.containsKey('likedBy')) {
  //       updates['likedBy'] = [];
  //     }
  //     if (!data.containsKey('dislikedBy')) {
  //       updates['dislikedBy'] = [];
  //     }

  //     if (updates.isNotEmpty) {
  //       await doc.reference.update(updates);
  //     }
  //   }
  // }

  Future<void> _loadDeviceUid() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceUid = prefs.getString('device_uid');
  }

  Future<void> _toggleCommentLikeByDoc(DocumentSnapshot doc) async {
    if (_deviceUid == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(doc.id);

    final likedBy = List<String>.from(doc['likedBy'] ?? []);
    final hasLiked = likedBy.contains(_deviceUid);

    await commentRef.update({
      'likes': FieldValue.increment(hasLiked ? -1 : 1),
      'likedBy': hasLiked
          ? FieldValue.arrayRemove([_deviceUid])
          : FieldValue.arrayUnion([_deviceUid]),
    });
  }

  Future<void> _toggleReplyLike({
    required String commentId,
    required String replyId,
    required List<String> likedBy,
  }) async {
    if (_deviceUid == null) return;

    final replyRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .doc(replyId);

    final hasLiked = likedBy.contains(_deviceUid);

    await replyRef.update({
      'likes': FieldValue.increment(hasLiked ? -1 : 1),
      'likedBy': hasLiked
          ? FieldValue.arrayRemove([_deviceUid])
          : FieldValue.arrayUnion([_deviceUid]),
    });
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
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 틀렸습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy(
          'timestamp',
          descending: false,
        );

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
      appBar: AppBar(title: Text('${widget.category} 게시판')),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              children: [
                // 📄 글 내용 표시
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: AppColors.redPrimary,
                        ),
                      );
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
                    // final likes = data['likes'] ?? 0;
                    // final dislikes = data['dislikes'] ?? 0;

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
                StreamBuilder<QuerySnapshot>(
                  stream: commentRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                        color: AppColors.redPrimary,
                      ));
                    }

                    final comments = snapshot.data!.docs;

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
                        final likes = doc['likes'] ?? 0;
                        final likedBy = List<String>.from(doc['likedBy'] ?? []);
                        final hasLiked =
                            _deviceUid != null && likedBy.contains(_deviceUid);

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
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _showReplyTo(commentId, nickname);
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Icon(Icons.reply, size: 18),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 18,
                                        ),
                                        GestureDetector(
                                          onTap: () =>
                                              _toggleCommentLikeByDoc(doc),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Icon(
                                                Icons.thumb_up_alt_outlined,
                                                size: 18,
                                                color: hasLiked
                                                    ? AppColors.redPrimary
                                                    : null),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 18,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _deleteComment(
                                                commentId, passwordHash);
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Icon(Icons.delete_outline,
                                                size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
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
                              likes > 0
                                  ? Row(
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.thumb_up_alt_outlined,
                                          size: 16,
                                          color: AppColors.redPrimary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$likes',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.redPrimary),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      formattedTime,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),

                              // 대댓글
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(widget.postId)
                                    .collection('comments')
                                    .doc(commentId)
                                    .collection('replies')
                                    .orderBy('timestamp')
                                    .snapshots(),
                                builder: (context, replySnapshot) {
                                  if (!replySnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  final replies = replySnapshot.data!.docs;

                                  if (replies.isEmpty) {
                                    return const SizedBox(); // 또는 null
                                  }
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
                                      final replyLikes = reply['likes'] ?? 0;
                                      final replyTimestamp =
                                          (reply['timestamp'] as Timestamp?)
                                              ?.toDate();
                                      final replyTimeFormatted =
                                          replyTimestamp != null
                                              ? DateFormat('yyyy.MM.dd HH:mm')
                                                  .format(replyTimestamp)
                                              : '';
                                      final replyLikedBy = List<String>.from(
                                          reply['likedBy'] ?? []);
                                      final hasReplyLiked =
                                          _deviceUid != null &&
                                              replyLikedBy.contains(_deviceUid);

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
                                                          Row(
                                                            children: [
                                                              GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  if (_deviceUid ==
                                                                      null) {
                                                                    return;
                                                                  }

                                                                  final replyRef = FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                          'posts')
                                                                      .doc(widget
                                                                          .postId)
                                                                      .collection(
                                                                          'comments')
                                                                      .doc(
                                                                          commentId)
                                                                      .collection(
                                                                          'replies')
                                                                      .doc(reply
                                                                          .id);

                                                                  await replyRef
                                                                      .update({
                                                                    'likes': FieldValue.increment(
                                                                        hasReplyLiked
                                                                            ? -1
                                                                            : 1),
                                                                    'likedBy': hasReplyLiked
                                                                        ? FieldValue
                                                                            .arrayRemove([
                                                                            _deviceUid
                                                                          ])
                                                                        : FieldValue
                                                                            .arrayUnion([
                                                                            _deviceUid
                                                                          ]),
                                                                  });
                                                                },
                                                                child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          4),
                                                                  child: Icon(
                                                                    Icons
                                                                        .thumb_up_alt_outlined,
                                                                    size: 18,
                                                                    color: hasReplyLiked
                                                                        ? AppColors
                                                                            .redPrimary
                                                                        : null,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 18,
                                                              ),
                                                              GestureDetector(
                                                                onTap: () =>
                                                                    _deleteReplyComment(
                                                                  commentId,
                                                                  reply.id,
                                                                  reply[
                                                                      'passwordHash'],
                                                                ),
                                                                child:
                                                                    const Padding(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          horizontal:
                                                                              4),
                                                                  child: Icon(
                                                                      Icons
                                                                          .delete_outline,
                                                                      size: 18),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(replyContent),
                                                      const SizedBox(height: 4),
                                                      replyLikes > 0
                                                          ? Row(
                                                              children: [
                                                                Text(
                                                                  replyTimeFormatted,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .grey),
                                                                ),
                                                                const SizedBox(
                                                                    width: 12),
                                                                const Icon(
                                                                  Icons
                                                                      .thumb_up_alt_outlined,
                                                                  size: 16,
                                                                  color: AppColors
                                                                      .redPrimary,
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
                                                                Text(
                                                                  '$replyLikes',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: AppColors
                                                                        .redPrimary,
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          : Text(
                                                              replyTimeFormatted,
                                                              style: const TextStyle(
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
      bottomSheet: _buildCommentInputArea(),
    );
  }

  Widget _buildPostReactionButtons(DocumentSnapshot postData) {
    final likes = postData['likes'] ?? 0;
    final dislikes = postData['dislikes'] ?? 0;
    final likedBy = List<String>.from(postData['likedBy'] ?? []);
    final dislikedBy = List<String>.from(postData['dislikedBy'] ?? []);

    final hasLiked = _deviceUid != null && likedBy.contains(_deviceUid);
    final hasDisliked = _deviceUid != null && dislikedBy.contains(_deviceUid);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.thumb_up,
            color: hasLiked ? AppColors.redPrimary : null,
          ),
          onPressed: () async {
            if (_deviceUid == null) return;

            final postRef = FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId);

            if (hasLiked) {
              // 🔴 좋아요 취소
              await postRef.update({
                'likes': FieldValue.increment(-1),
                'likedBy': FieldValue.arrayRemove([_deviceUid])
              });
            } else {
              // 🟢 좋아요 추가
              await postRef.update({
                'likes': FieldValue.increment(1),
                'likedBy': FieldValue.arrayUnion([_deviceUid])
              });

              // ❌ 동시에 싫어요 누른 적이 있다면 취소
              if (hasDisliked) {
                await postRef.update({
                  'dislikes': FieldValue.increment(-1),
                  'dislikedBy': FieldValue.arrayRemove([_deviceUid])
                });
              }
            }
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
            if (_deviceUid == null) return;

            final postRef = FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId);

            if (hasDisliked) {
              // 🔵 싫어요 취소
              await postRef.update({
                'dislikes': FieldValue.increment(-1),
                'dislikedBy': FieldValue.arrayRemove([_deviceUid])
              });
            } else {
              // 🔷 싫어요 추가
              await postRef.update({
                'dislikes': FieldValue.increment(1),
                'dislikedBy': FieldValue.arrayUnion([_deviceUid])
              });

              // ❌ 동시에 좋아요 누른 적이 있다면 취소
              if (hasLiked) {
                await postRef.update({
                  'likes': FieldValue.increment(-1),
                  'likedBy': FieldValue.arrayRemove([_deviceUid])
                });
              }
            }
          },
        ),
        Text('$dislikes'),
      ],
    );
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
