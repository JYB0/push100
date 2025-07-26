import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/bottom_navigation.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TutorialScreen extends StatefulWidget {
  final int? initialWeek;
  final String? initialLevel;
  final bool? isTestMode;

  const TutorialScreen({
    super.key,
    this.initialWeek,
    this.initialLevel,
    this.isTestMode,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  bool _showStartButton = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    _checkIfTutorialSeen();
    super.initState();
  }

  Future<void> _checkIfTutorialSeen() async {
    final seen = await SharedPreferencesHelper.getAppTutorialSeen();
    if (!seen) {
      setState(() {
        _showStartButton = true;
      });
    }
  }

  Future<void> _completeTutorial() async {
    await SharedPreferencesHelper.setAppTutorialSeen(true);

    if (!mounted) return;

    if (widget.initialWeek == null ||
        widget.initialLevel == null ||
        widget.isTestMode == null) {
      Navigator.pop(context); // 설정에서 진입한 경우
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            BottomNavigation(
          initialWeek: widget.initialWeek!,
          initialLevel: widget.initialLevel!,
          isTestMode: widget.isTestMode!,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  Widget _buildTutorialContent(double fontSize) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("1. 오늘의 목표 운동을 수행하세요.", style: TextStyle(fontSize: fontSize)),
        Text("2. 한 세트를 완료한 후, 노란색 원을 터치하면 해당 세트가 완료됩니다.",
            style: TextStyle(fontSize: fontSize)),
        Text("3. 정해진 개수를 채우지 못했다면 - 버튼을 눌러 횟수를 조정한 후, 세트를 완료하세요.",
            style: TextStyle(fontSize: fontSize)),
        Text("4. 마지막 세트에서는 최대한 많은 푸시업을 수행하세요. (목표 이상 가능)",
            style: TextStyle(fontSize: fontSize)),
        Text("5. 푸시업을 수행한 후 2일 뒤 다시 훈련(또는 테스트)을 진행하세요.",
            style: TextStyle(fontSize: fontSize)),
        Text("6. 테스트를 진행한 후 2일 뒤 푸시업 훈련을 시작하세요.",
            style: TextStyle(fontSize: fontSize)),
        Text("7. 테스트 통과 기준에 미치지 못하면 해당 주차가 반복됩니다.",
            style: TextStyle(fontSize: fontSize)),
        Text("8. 6주간 프로그램을 완료하고 푸시업 100개를 달성하면 챌린지가 끝납니다! 🎉 축하합니다!",
            style: TextStyle(fontSize: fontSize)),
      ],
    );
  }

  Widget _buildFAQContent(double fontSize) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("자주 묻는 질문 (FAQ)",
            style: TextStyle(
                fontSize: fontSize * 1.3, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Q. 매일 해야 하나요?",
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        Text("A. 아니요. 최소 하루는 휴식 후 운동을 진행해주세요. 예를 들어 월요일에 운동을 했다면 수요일에 하시면 됩니다.",
            style: TextStyle(fontSize: fontSize)),
        const SizedBox(height: 8),
        Text("Q. 테스트 후 바로 운동해야 하나요?",
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        Text("A. 아니요. 테스트 후에는 최소 이틀 정도 휴식을 취한 뒤 운동을 시작하세요.",
            style: TextStyle(fontSize: fontSize)),
        const SizedBox(height: 8),
        Text("Q. 하루 운동 목표를 못 채우면 어떻게 되나요?",
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        Text("A. 괜찮습니다. 해당 주차에 목표를 채우지 못한 날이 있거나 테스트 기준 미달 시 해당 주차를 반복합니다.",
            style: TextStyle(fontSize: fontSize)),
        const SizedBox(height: 8),
        Text("Q. 무릎 대고 푸시업 해도 되나요?",
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        Text("A. 네, 무릎을 대고 해도 됩니다. 다만 가능한 한 정자세로 수행할 수 있는 만큼은 정자세로 해주세요.",
            style: TextStyle(fontSize: fontSize)),
        const SizedBox(height: 8),
        Text("Q. 세트 도중에 쉬고 다시 푸쉬업해도 성공인가요?",
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        Text(
            "A. 손이 바닥에서 떨어지지 않았다면 정자세 푸시업을 연속으로 카운트할 수 있습니다. 예를 들어서 푸쉬업 15개를 하고 손을 떼지 않은 채로 잠시 쉬었다가 10개를 더 했으면 총 25개로 카운트하시면 됩니다.",
            style: TextStyle(fontSize: fontSize)),
        const SizedBox(height: 8),
        Text("Q. 세트 사이에 얼마나 쉬어야하나요?",
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
        Text("A. 휴식 타이머가 초록색으로 바뀌면 운동을 다시 시작하시면 됩니다. 더 쉬고 싶다면 더 쉬어도 괜찮습니다.",
            style: TextStyle(fontSize: fontSize)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text("📌 앱 가이드")),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildTutorialContent(dynamicFontSize),
          _buildFAQContent(dynamicFontSize),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 2,
                effect: const WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 12,
                  activeDotColor: AppColors.redPrimary,
                ),
              ),
            ),
            if (_showStartButton &&
                widget.initialWeek != null &&
                widget.initialLevel != null &&
                widget.isTestMode != null &&
                _currentPage == 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeTutorial,
                    child: const Text("시작하기"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
