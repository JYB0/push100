import 'dart:async';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/bottom_navigation.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({super.key});

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  ConfettiController? _controller1;
  ConfettiController? _controller2;
  bool isDone = false;
  int progress = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startConfettiEffect(); // 🎉 화면이 나타나면 자동 실행
  }

  /// ✅ Confetti 효과 시작
  void _startConfettiEffect() {
    const colors = [
      AppColors.greenPrimary,
      AppColors.redPrimary,
      AppColors.yellowLight
    ];

    int frameTime = 1000 ~/ 24;
    int total = 5 * 1000 ~/ frameTime;

    _timer = Timer.periodic(Duration(milliseconds: frameTime), (timer) {
      progress++;

      if (progress >= total) {
        timer.cancel();
        isDone = true;
        return;
      }
      if (_controller1 == null) {
        _controller1 = Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 3,
            angle: 60,
            spread: 55,
            x: 0,
            colors: colors,
          ),
          onFinished: (overlayEntry) {
            if (isDone) {
              overlayEntry.remove();
            }
          },
        );
      } else {
        _controller1!.launch();
      }

      if (_controller2 == null) {
        _controller2 = Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 2,
            angle: 120,
            spread: 55,
            x: 1,
            colors: colors,
          ),
          onFinished: (overlayEntry) {
            if (isDone) {
              overlayEntry.remove();
            }
          },
        );
      } else {
        _controller2!.launch();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller1 = null; // ✅ null로 설정하여 메모리 해제
    _controller2 = null; // ✅ null로 설정하여 메모리 해제
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BottomNavigation(
          initialWeek: 7, // ✅ 7주차로 설정하여 홈 화면에서 nextPlan 안 보이게
          initialLevel: "초보", // ✅ 기존 레벨 유지
          isTestMode: false, // ✅ 테스트 모드 해제
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal, // 가로 방향 이동
            child: child,
          );
        },
      ),
      (route) => false, // ✅ 기존 모든 화면 제거하고 `BottomNavigation`만 남김
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("🎉 축하합니다!"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _navigateToHome, icon: const Icon(Icons.close))
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                height: screenHeight * 0.1,
              ),
              Text(
                "푸시업 챌린지를 \n성공했습니다!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: dynamicFontSize * 2, fontWeight: FontWeight.bold),
              ),
              // SizedBox(height: screenHeight * 0.01),
              // ElevatedButton(
              //   onPressed: _navigateToHome,
              //   child: const Text("홈으로 가기"),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
