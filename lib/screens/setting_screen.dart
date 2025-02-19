import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:push100/main.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/initial_test_screen.dart';
import 'package:push100/screens/tutorial_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  /// ✅ 기록 초기화 기능
  Future<void> _resetData(BuildContext context) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: "데이터 초기화",
      message: "모든 훈련 기록과 설정이 삭제됩니다.\n정말 초기화하시겠습니까?",
      okLabel: "초기화",
      cancelLabel: "취소",
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      await SharedPreferencesHelper.clearAllData();

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

  /// ✅ 앱 공유 기능
  // void _shareApp() {
  //   String appLink = "https://www.google.com"; // 앱 링크 있으면 추후에 넣자.
  //   String message = "🔥 푸시업 챌린지 앱을 사용해보세요! 💪\n$appLink";
  //   Share.share(message);
  // }

  /// ✅ 앱 사용법 화면 이동
  void _navigateToTutorial(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TutorialScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal, // 가로 방향 이동
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: ListView(
        children: [
          /// 🔹 기록 초기화
          ListTile(
            minVerticalPadding: dynamicFontSize,
            leading: Icon(
              Icons.delete,
              color: AppColors.redPrimary,
              size: dynamicFontSize * 1.5,
            ),
            title: Text(
              "데이터 초기화",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            onTap: () => _resetData(context),
          ),

          /// 🔹 앱 공유
          // ListTile(
          //   leading: const Icon(Icons.share, color: Colors.blue),
          //   title: const Text("앱 공유하기"),
          //   onTap: _shareApp,
          // ),

          /// 🔹 앱 사용법
          ListTile(
            minVerticalPadding: dynamicFontSize,
            leading: Icon(
              Icons.help,
              color: AppColors.greenPrimary,
              size: dynamicFontSize * 1.5,
            ),
            title: Text(
              "앱 가이드",
              style: TextStyle(fontSize: dynamicFontSize),
            ),
            onTap: () => _navigateToTutorial(context),
          ),
        ],
      ),
    );
  }
}
