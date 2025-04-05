import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _increaseViewCount();
  }

  Future<void> _increaseViewCount() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'views': FieldValue.increment(1)});
  }

  Future<void> _updateReaction(String field) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({field: FieldValue.increment(1)});
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text.trim();

    if (content.isEmpty || nickname.isEmpty || password.isEmpty) return;

    final hash = sha256.convert(utf8.encode(password)).toString();

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

    _commentController.clear();
    _nicknameController.clear();
    _passwordController.clear();
  }

  Future<void> _deleteComment(String commentId, String storedHash) async {
    final input = await showDialog<String>(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("댓글 삭제"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "비밀번호 입력"),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("삭제"),
            ),
          ],
        );
      },
    );

    if (input == null || input.isEmpty) return;

    final inputHash = sha256.convert(utf8.encode(input)).toString();

    if (inputHash == storedHash) {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } else {
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
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("글 상세 보기")),
      body: Column(
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
                  child: CircularProgressIndicator(),
                );
              }

              final data = snapshot.data!;
              final title = data['title'] ?? '제목 없음';
              final content = data['content'] ?? '';
              final nickname = data['nickname'] ?? '익명';
              final timestamp = data['timestamp']?.toDate();
              final views = data['views'] ?? 0;
              final likes = data['likes'] ?? 0;
              final dislikes = data['dislikes'] ?? 0;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('by $nickname • ${timestamp?.toLocal()}'),
                    const SizedBox(height: 8),
                    Text('조회수: $views'),
                    const SizedBox(height: 16),
                    Text(content),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up),
                          onPressed: () => _updateReaction('likes'),
                        ),
                        Text('$likes'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.thumb_down),
                          onPressed: () => _updateReaction('dislikes'),
                        ),
                        Text('$dislikes'),
                      ],
                    ),
                    const Divider(thickness: 1),
                  ],
                ),
              );
            },
          ),

          // 💬 댓글 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: commentRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(child: Text('아직 댓글이 없습니다.'));
                }

                return ListView(
                  children: comments.map((doc) {
                    return ListTile(
                      title: Text(doc['content']),
                      subtitle: Text(doc['nickname']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _deleteComment(doc.id, doc['passwordHash']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const Divider(),

          // ✏️ 댓글 작성 폼
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(labelText: "댓글 내용"),
                ),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: "닉네임"),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "비밀번호"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitComment,
                  child: const Text("댓글 작성"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
