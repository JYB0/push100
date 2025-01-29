import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:push100/main.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/home_screen.dart';

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

class WorkoutScreenState extends State<WorkoutScreen> {
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
    const double circleSize = 50;
    const double spacing = 16;
    const double itemWidth = circleSize + spacing;

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
    const double spacing = 16; // 간격
    const double circleSize = 50; // 원 크기

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal, // 가로 스크롤 활성화
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: spacing / 2),
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
                padding: const EdgeInsets.symmetric(horizontal: spacing / 2),
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
                      fontSize: 16,
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            pushupCount: 0,
            week: widget.week,
            level: widget.level,
            isTestMode: true, // 테스트 모드 활성화
          ),
        ),
        (route) => false,
      );
    } else if (nextDay > 3) {
      // 일반 주차의 마지막 날인 경우 다음 주차로 이동
      final nextWeek = widget.week + 1;

      await SharedPreferencesHelper.saveProgress(nextWeek, 1, widget.level);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            pushupCount: 0,
            week: nextWeek,
            level: widget.level,
            isTestMode: false, // 테스트 모드 비활성화
          ),
        ),
        (route) => false,
      );
    } else {
      // 같은 주차의 다음 날로 이동
      await SharedPreferencesHelper.saveProgress(
          widget.week, nextDay, widget.level);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            pushupCount: 0,
            week: widget.week,
            level: widget.level,
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
      _scrollToCurrentSet();
      _startRestTimer();
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          pushupCount: userReps.reduce((a, b) => a + b), // 총 수행 푸시업
          week: widget.week,
          level: widget.level,
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
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double circleSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.45;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Week ${widget.week}, Day ${widget.day}"),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    _buildSetCircles(),
                    // const SizedBox(height: 30),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // const Text(
                          //   "현재 목표 푸시업",
                          //   style: TextStyle(
                          //       fontSize: 18, fontWeight: FontWeight.bold),
                          // ),
                          SizedBox(
                            height: screenHeight * 0.1,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _decreaseReps,
                                icon: Icon(
                                  Icons.remove,
                                  size: circleSize * 0.25,
                                ),
                              ),
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  // color: AppColors.yellowPrimary,
                                  border: Border.all(
                                    color: AppColors.yellowPrimary,
                                    width: 5,
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
                              ),
                              IconButton(
                                onPressed: _increaseReps,
                                icon: Icon(
                                  Icons.add,
                                  size: circleSize * 0.25,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.1),
                          ElevatedButton(
                            onPressed: _completeSet,
                            child: Text(
                              currentSet < sets.length - 1 ? "세트 완료" : "운동 완료",
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Opacity(
                        opacity: isResting ? 1.0 : 0.0,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(25, 0, 0, 0),
                                  blurRadius: 10.0,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "${elapsedSeconds ~/ 60}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}",
                                          style: GoogleFonts.firaCode(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "휴식 중...",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          isResting = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
