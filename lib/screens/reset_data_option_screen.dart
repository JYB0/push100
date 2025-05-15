import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/initial_test_screen.dart';
import 'package:push100/main.dart';

class ResetDataOptionScreen extends StatefulWidget {
  const ResetDataOptionScreen({super.key});

  @override
  State<ResetDataOptionScreen> createState() => _ResetDataOptionScreenState();
}

class _ResetDataOptionScreenState extends State<ResetDataOptionScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dynamicFontSize = 16.0 * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text("데이터 초기화")),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    "원하는 초기화 방식을 선택하세요",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: dynamicFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "⏱ 진행 상태만 초기화하거나\n🗑 모든 데이터를 삭제할 수 있어요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: dynamicFontSize * 0.9,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.refresh,
                      size: dynamicFontSize,
                      color: Colors.white,
                    ),
                    label: Text(
                      "진행 상태만 초기화",
                      style: TextStyle(fontSize: dynamicFontSize),
                    ),
                    onPressed: _resetProgressOnly,
                  ),
                  SizedBox(height: dynamicFontSize),
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.delete_forever,
                      size: dynamicFontSize,
                      color: Colors.white,
                    ),
                    label: Text(
                      "모든 데이터 삭제",
                      style: TextStyle(fontSize: dynamicFontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.redPrimary,
                    ),
                    onPressed: () => _resetAllData(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: const Color(0x4D000000),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.redPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _resetProgressOnly() async {
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    await SharedPreferencesHelper.saveInitialTest(0);

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'initialPushupCount': 0}, SetOptions(merge: true));
    }
    setState(() => _isProcessing = false);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
          pageBuilder: (context, animation, secondaryAnimation) =>
              const InitialTestScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal, // 가로 방향 이동
              child: child,
            );
          },
        ),
        (route) => false, // ✅ 기존 모든 화면 제거 후 `InitialTestScreen()`만 남김
      );
    }
  }

  Future<void> _resetAllData(BuildContext context) async {
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;

    final message = user == null
        ? "모든 훈련 기록과 설정이 삭제됩니다.\n정말 삭제하시겠습니까?"
        : "이 작업은 기기에 저장된 \n모든 훈련 기록과 설정을 삭제하며,\n\n"
            "서버에 백업된 데이터도 함께 삭제됩니다.\n정말 삭제하시겠습니까?";

    final result = await showOkCancelAlertDialog(
      context: context,
      title: "모든 데이터 삭제",
      message: message,
      okLabel: "삭제",
      cancelLabel: "취소",
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      await SharedPreferencesHelper.clearAllData();

      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("서버에 있는 데이터를 삭제하지 못했습니다."),
              ),
            );
          }
        }
      }
      setState(() => _isProcessing = false);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration:
                const Duration(milliseconds: 500), // 애니메이션 지속 시간
            pageBuilder: (context, animation, secondaryAnimation) =>
                const InitialTestScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal, // 가로 방향 이동
                child: child,
              );
            },
          ),
          (route) => false, // ✅ 기존 모든 화면 제거 후 `InitialTestScreen()`만 남김
        );
      }
    }
  }
}
