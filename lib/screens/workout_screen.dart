import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import 'package:push100/main.dart';
import 'package:push100/screens/bottom_navigation.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
// import 'package:push100/screens/home_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final String level;
  final int week;
  final int day;

  const WorkoutScreen({
    super.key,
    required this.level,
    required this.week,
    required this.day,
  });

  @override
  WorkoutScreenState createState() => WorkoutScreenState();
}

class WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  late List<int> sets;
  late ScrollController _scrollController;

  int currentSet = 0;
  int restTime = 0;
  int elapsedSeconds = 0;
  int currentTargetReps = 0;

  Timer? timer;
  bool isResting = false;
  List<int> userReps = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    sets = [];
    userReps = [];
    _loadWorkoutPlan();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true); // 🔥 무한 반복 (깜박깜박)

    // ✅ 배경색 변경 애니메이션 (밝아졌다가 어두워짐)
    _colorAnimation = ColorTween(
      begin: Colors.white, // 밝은 색
      end: const Color.fromARGB(67, 246, 211, 105), // 어두운 색 (강조 효과)
    ).animate(_animationController);
  }

  void _increaseReps() {
    setState(() {
      if (currentSet == sets.length - 1) {
        // 마지막 세트는 제한 없이 증가 가능
        currentTargetReps++;
      } else if (currentTargetReps < sets[currentSet]) {
        // 다른 세트는 sets[currentSet] 이하로 제한
        currentTargetReps++;
      }
    });
  }

  void _decreaseReps() {
    setState(() {
      if (currentTargetReps > 0) {
        currentTargetReps--;
      }
    });
  }

  void _loadWorkoutPlan() {
    final plan =
        getPlanByLevelWeekAndDay(widget.level, widget.week, widget.day);
    if (plan != null) {
      sets = plan.sets;
      restTime = plan.restTime;
      userReps = List<int>.from(sets);
      currentTargetReps = sets.isNotEmpty ? sets[0] : 0;
    } else {
      sets = [];
      restTime = 60; // 기본값
      userReps = [];
      currentTargetReps = 0;
    }
    setState(() {});
  }

  void _startRestTimer() {
    if (timer != null) {
      timer!.cancel();
    }

    setState(() {
      elapsedSeconds = 0;
      isResting = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds += 1;
      });

      if (elapsedSeconds == restTime) {
        _showRestCompleteNotification();
      }
    });
  }

  void _scrollToCurrentSet() {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    final double spacing = screenWidth * 0.04; // 간격
    final double circleSize = screenWidth * 0.15; // 원 크기
    // final double fontSize = circleSize * 0.35; // 글자 크기도 비례 설정
    final double itemWidth = circleSize + spacing;

    if (_scrollController.hasClients) {
      final position = currentSet * itemWidth - (itemWidth * 2); // 중앙 근처에 표시
      _scrollController.animateTo(
        position.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showRestCompleteNotification() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rest_complete_channel',
      'Rest Complete',
      channelDescription: 'Notification for rest completion',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      '휴식 완료',
      '다음 세트를 진행하세요!',
      platformChannelSpecifics,
    );

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }

  Widget _buildSetCircles() {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    final double spacing = screenWidth * 0.03; // 간격
    final double circleSize = screenWidth * 0.15; // 원 크기
    final double fontSize = circleSize * 0.35; // 글자 크기도 비례 설정

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal, // 가로 스크롤 활성화
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing / 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            sets.length,
            (index) {
              bool isCurrentSet = index == currentSet;
              bool isFutureSet = index > currentSet;

              Color borderColor;
              Color textColor;
              double textWidth;

              if (isCurrentSet) {
                borderColor = AppColors.greyPrimary;
                textColor = Colors.grey;
                textWidth = 3;
              } else if (isFutureSet) {
                borderColor = AppColors.greyPrimary; // 미래의 세트는 회색
                textColor = Colors.grey;
                textWidth = 1;
              } else if (userReps[index] >= sets[index]) {
                borderColor = AppColors.greenPrimary; // 목표 이상 수행한 경우 초록색
                textColor = Colors.white;
                textWidth = 3;
              } else {
                borderColor = AppColors.redPrimary; // 목표보다 적게 수행한 경우 빨간색
                textColor = Colors.white;
                textWidth = 3;
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor,
                    border: Border.all(
                      color: borderColor,
                      width: textWidth,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${userReps[index]}",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _completeWorkout() async {
    final nextDay = widget.day + 1;
    final isTestWeek =
        (widget.week == 2 || widget.week == 4 || widget.week == 5);

    if (nextDay > 3 && isTestWeek) {
      // 테스트 주차의 마지막 날인 경우 테스트 모드로 전환
      await SharedPreferencesHelper.saveProgress(widget.week, 3, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(true);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigation(
            initialWeek: widget.week,
            initialLevel: widget.level,
            isTestMode: true, // 테스트 모드 활성화
          ),
        ),
        (route) => false,
      );
    } else if (nextDay > 3) {
      // 일반 주차의 마지막 날인 경우 다음 주차로 이동
      final nextWeek = widget.week + 1;

      await SharedPreferencesHelper.saveProgress(nextWeek, 1, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigation(
            initialWeek: nextWeek,
            initialLevel: widget.level,
            isTestMode: false, // 테스트 모드 비활성화
          ),
        ),
        (route) => false,
      );
    } else {
      // 같은 주차의 다음 날로 이동
      await SharedPreferencesHelper.saveProgress(
          widget.week, nextDay, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => BottomNavigation(
            initialWeek: widget.week,
            initialLevel: widget.level,
            isTestMode: false, // 테스트 모드 아님
          ),
        ),
        (route) => false,
      );
    }
  }

  void _completeSet() {
    if (currentSet < sets.length - 1) {
      setState(() {
        userReps[currentSet] = currentTargetReps;
        currentSet += 1;

        if (currentSet < sets.length) {
          currentTargetReps = userReps[currentSet]; // 다음 세트 목표 로드
        }
      });
      if (currentSet == sets.length) {
        _saveWorkoutRecord(); // 운동 기록 저장
      }
      _startRestTimer();
      _scrollToCurrentSet();
      _animationController.reset();
      _animationController.repeat(reverse: true);
    } else {
      userReps[currentSet] = currentTargetReps;
      _saveWorkoutRecord();
      _showWorkoutCompleteNotification();
      _completeWorkout();
    }
  }

  void _showWorkoutCompleteNotification() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'workout_complete_channel',
      'Workout Complete',
      channelDescription: 'Notification for workout completion',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      1,
      '운동 완료',
      '오늘의 훈련을 완료했습니다!',
      platformChannelSpecifics,
    );

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }
  }

  Future<void> _saveWorkoutRecord() async {
    final now = DateTime.now();
    final date = "${now.year}-${now.month}-${now.day}";

    await SharedPreferencesHelper.saveWorkoutRecord(
      date,
      sets, // 계획된 세트 목표
      userReps, // 사용자가 수행한 세트
      widget.week,
      widget.day,
      widget.level,
    );

    // 저장 후 홈 화면으로 이동
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => BottomNavigation(
          initialWeek: widget.week,
          initialLevel: widget.level,
          isTestMode: false,
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _scrollController.dispose();
    super.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double circleSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.45;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Week ${widget.week}, Day ${widget.day}",
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            /// ✅ 메인 UI
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenHeight * 0.01),
                  child: _buildSetCircles(),
                ),

                /// 🔹 **목표 푸시업 UI**
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: screenHeight * 0.1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _decreaseReps,
                            icon: Icon(Icons.remove, size: circleSize * 0.25),
                          ),
                          SizedBox(width: circleSize * 0.05),
                          GestureDetector(
                            onTap: _completeSet,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Container(
                                  width: circleSize,
                                  height: circleSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _colorAnimation.value,
                                    border: Border.all(
                                      color: AppColors.yellowPrimary,
                                      width: circleSize * 0.03,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$currentTargetReps",
                                    style: TextStyle(
                                      fontSize: circleSize * 0.35,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: circleSize * 0.05),
                          IconButton(
                            onPressed: _increaseReps,
                            icon: Icon(Icons.add, size: circleSize * 0.25),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// 🔹 **버튼 (항상 화면 안에 보이도록 설정)**
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 16.0),
                //   child: ElevatedButton(
                //     onPressed: _completeSet,
                //     style: ElevatedButton.styleFrom(
                //       padding: EdgeInsets.symmetric(
                //           horizontal: screenWidth * 0.3,
                //           vertical: screenWidth * 0.04),
                //     ),
                //     child: Text(
                //       currentSet < sets.length - 1 ? "세트 완료" : "운동 완료",
                //       style: TextStyle(
                //           fontSize: dynamicFontSize * 1.2,
                //           fontWeight: FontWeight.bold),
                //     ),
                //   ),
                // ),

                /// 🔹 버튼과 하단 공간 추가
                // SizedBox(height: screenHeight * 0.1),
              ],
            ),

            /// 🔥 **휴식 중 팝업 (버튼 위에 겹치지 않도록 Positioned 사용)**
            Positioned(
              bottom: 20, // 버튼과 겹치지 않도록 설정
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300), // ✅ 등장 & 사라짐 속도
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3), // 아래에서 위로 올라옴
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: isResting
                    ? Container(
                        key:
                            const ValueKey("restingPopup"), // 애니메이션 동작을 위한 키 설정
                        margin:
                            EdgeInsets.symmetric(horizontal: dynamicFontSize),
                        padding: EdgeInsets.all(dynamicFontSize),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// ✅ 휴식 타이머
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${elapsedSeconds ~/ 60}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}",
                                      style: GoogleFonts.firaCode(
                                        fontSize: dynamicFontSize * 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Text(
                                      "휴식 중...",
                                      style: TextStyle(
                                        fontSize: dynamicFontSize * 1.1,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                /// ✅ 닫기 버튼 (클릭 시 애니메이션 적용)
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: dynamicFontSize * 1.5,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isResting = false; // ✅ 애니메이션 트리거
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            /// ✅ 프로그레스 바
                            LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(3),
                              value: elapsedSeconds / restTime,
                              backgroundColor: Colors.grey[300],
                              color: elapsedSeconds <= restTime
                                  ? AppColors.redPrimary
                                  : AppColors.greenPrimary,
                              minHeight: 10,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                    : null, // ✅ isResting == false일 때 자연스럽게 사라짐
              ),
            ),
          ],
        ),
      ),
    );
  }
}
