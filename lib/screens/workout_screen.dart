import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push100/helpers/workout_helper.dart';

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
    setState(() {}); // 화면 갱신
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

    // Show the bottom sheet for visual effect
    _showRestBottomSheet();
  }

  void _showRestBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "휴식 중...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<int>(
                    stream: Stream.periodic(
                        const Duration(seconds: 1), (tick) => elapsedSeconds),
                    builder: (context, snapshot) {
                      final currentTime = snapshot.data ?? elapsedSeconds;
                      return Column(
                        children: [
                          Text(
                            "${currentTime ~/ 60}:${(currentTime % 60).toString().padLeft(2, '0')}",
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: currentTime <= restTime
                                ? currentTime / restTime
                                : 1.0, // restTime 경과 후에도 프로그레스바 유지
                            backgroundColor: Colors.grey[300],
                            color: currentTime <= restTime
                                ? Colors.red
                                : Colors.green, // restTime 경과 후 색상 변경
                            minHeight: 10,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the bottom sheet
                      setState(() {
                        isResting = false;
                      });
                    },
                    child: const Text("휴식 종료"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  void _completeSet() {
    if (currentSet < sets.length - 1) {
      setState(() {
        currentSet += 1;
      });
      _startRestTimer();
    } else {
      _showWorkoutCompleteNotification();
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "세트 ${currentSet + 1} / ${sets.length}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    );
  }
}
