import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int currentSet = 0;
  int restTime = 0;
  Timer? timer;
  int elapsedSeconds = 0;
  bool isResting = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
  }

  void _loadWorkoutPlan() {
    final plan =
        getPlanByLevelWeekAndDay(widget.level, widget.week, widget.day);
    if (plan != null) {
      sets = plan.sets;
      restTime = plan.restTime;
    } else {
      sets = [];
      restTime = 60; // 기본값
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

  Future<void> _completeWorkout() async {
    print(
        "Before week = ${widget.week}, day = ${widget.day}, level = ${widget.level}");

    final nextDay = widget.day + 1;
    final isTestWeek =
        (widget.week == 2 || widget.week == 4 || widget.week == 5);

    if (nextDay > 3 && isTestWeek) {
      // 테스트 주차의 마지막 날인 경우 테스트 모드로 전환
      await SharedPreferencesHelper.saveProgress(widget.week, 3, widget.level);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            pushupCount: 0,
            week: widget.week,
            level: widget.level,
            isTestMode: true, // 테스트 모드 활성화
          ),
        ),
      );
    } else if (nextDay > 3) {
      // 일반 주차의 마지막 날인 경우 다음 주차로 이동
      final nextWeek = widget.week + 1;

      await SharedPreferencesHelper.saveProgress(nextWeek, 1, widget.level);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            pushupCount: 0,
            week: nextWeek,
            level: widget.level,
            isTestMode: false, // 테스트 모드 비활성화
          ),
        ),
      );
    } else {
      // 같은 주차의 다음 날로 이동
      await SharedPreferencesHelper.saveProgress(
          widget.week, nextDay, widget.level);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            pushupCount: 0,
            week: widget.week,
            level: widget.level,
            isTestMode: false, // 테스트 모드 아님
          ),
        ),
      );
    }

    print(
        "After week = ${widget.week}, day = $nextDay, level = ${widget.level}");
  }

  void _completeSet() {
    if (currentSet < sets.length - 1) {
      setState(() {
        currentSet += 1;
      });
      _startRestTimer();
    } else {
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

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Week ${widget.week}, Day ${widget.day}"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "세트 ${currentSet + 1} / ${sets.length}",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "현재 세트 푸시업: ${sets.isNotEmpty ? sets[currentSet] : 0}개",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _completeSet,
                      child: Text(
                        currentSet < sets.length - 1 ? "세트 완료" : "운동 완료",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isResting)
              Align(
                alignment: Alignment.bottomCenter,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          value: elapsedSeconds / restTime,
                          backgroundColor: Colors.grey[300],
                          color: elapsedSeconds <= restTime
                              ? Colors.red
                              : Colors.green,
                          minHeight: 10,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
