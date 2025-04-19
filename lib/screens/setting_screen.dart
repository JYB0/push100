import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:push100/main.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/data_sync_screen.dart';
import 'package:push100/screens/help_screen.dart';
import 'package:push100/screens/initial_test_screen.dart';
import 'package:push100/screens/login_screen.dart';
import 'package:push100/screens/tutorial_screen.dart';
import 'package:share_plus/share_plus.dart';

class SettingScreen extends StatelessWidget {
  SettingScreen({super.key});

  // 🔥 랜덤 문구 리스트
  final List<String> shareAppTexts = [
    "친구에게도 이 도전을 알려주세요!",
    "함께하면 더 즐거워요, 앱 공유하기 💪",
    "도전의 즐거움을 나눠보세요 🔥",
    "Push100이 마음에 들었다면 공유해주세요!",
  ];

  final List<String> rateAppTexts = [
    "앱이 마음에 드셨다면 따뜻한 리뷰 부탁드려요",
    "여러분의 리뷰는 큰 힘이 됩니다 💬",
    "한 줄 리뷰로 힘을 주세요!",
    "Push100, 어떠셨나요? 평가로 알려주세요!",
  ];

  String getRandomText(List<String> options) {
    final random = Random();
    return options[random.nextInt(options.length)];
  }

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

  Future<void> _openStoreListing() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      if (Platform.isIOS) {
        inAppReview.openStoreListing(appStoreId: dotenv.env['APPSTORE_ID']);
      } else {
        inAppReview.openStoreListing();
      }
    }
  }

  void _shareApp() {
    Share.share(
      "🔥 푸시업 100개 도전! 저도 함께 하고 있어요!\nPush100 앱으로 함께 도전해요!\n📲 iOS 다운로드: https://apps.apple.com/kr/app/push100/id6742874163\n📲 안드로이드 다운로드: https://play.google.com/store/apps/details?id=com.morebetterlifeapp.push100",
    );
  }

  void _navigateToHelp(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HelpScreen(),
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
      appBar: AppBar(
        title: const Text("설정"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          /// 🔹 기록 초기화

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
              Icons.menu_book,
              color: AppColors.greenPrimary,
              size: dynamicFontSize * 1.5,
            ),
            title: Text(
              "앱 가이드",
              style: TextStyle(fontSize: dynamicFontSize),
            ),
            onTap: () => _navigateToTutorial(context),
          ),
          ListTile(
            minVerticalPadding: dynamicFontSize,
            leading: Icon(
              Icons.ios_share,
              color: AppColors.redPrimary,
              size: dynamicFontSize * 1.5,
            ),
            title: Text(
              getRandomText(shareAppTexts),
              style: TextStyle(fontSize: dynamicFontSize),
            ),
            onTap: _shareApp,
          ),
          ListTile(
            minVerticalPadding: dynamicFontSize,
            leading: Icon(
              Icons.star_rate,
              color: AppColors.yellowPrimary,
              size: dynamicFontSize * 1.5,
            ),
            title: Text(
              getRandomText(rateAppTexts),
              style: TextStyle(fontSize: dynamicFontSize),
            ),
            onTap: _openStoreListing,
          ),
          ListTile(
            minVerticalPadding: dynamicFontSize,
            leading: Icon(
              Icons.help,
              color: AppColors.greenPrimary,
              size: dynamicFontSize * 1.5,
            ),
            title: Text(
              "앱 문의하기",
              style: TextStyle(fontSize: dynamicFontSize),
            ),
            onTap: () => _navigateToHelp(context),
          ),
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
          ListTile(
            minVerticalPadding: dynamicFontSize,
            leading: Icon(
              Icons.cloud_sync,
              color: AppColors.yellowPrimary,
              size: dynamicFontSize * 1.5,
            ),
            title: Text(
              "데이터 연동하기",
              style: TextStyle(fontSize: dynamicFontSize),
            ),
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;

              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      user == null
                          ? const LoginScreen()
                          : const DataSyncScreen(),
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
              );
            },
          ),
        ],
      ),
    );
  }
}
