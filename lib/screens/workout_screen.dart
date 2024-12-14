import 'dart:async';
import 'package:flutter/material.dart';
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
  int remainingTime = 0;

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
  }

  void _startRestTimer() {
    setState(() {
      remainingTime = restTime;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime -= 1;
      });

      if (remainingTime <= 0) {
        timer.cancel();
        _showRestCompleteDialog();
      }
    });
  }

  void _showRestCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("휴식 완료"),
        content: const Text("다음 세트를 진행하세요!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  void _completeSet() {
    if (currentSet < sets.length - 1) {
      setState(() {
        currentSet += 1;
      });
      _startRestTimer();
    } else {
      _showWorkoutCompleteDialog();
    }
  }

  void _showWorkoutCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("운동 완료"),
        content: const Text("오늘의 훈련을 완료했습니다!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 홈 화면으로 이동
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "세트 ${currentSet + 1} / ${sets.length}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "현재 세트 푸시업: ${sets[currentSet]}개",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            if (remainingTime > 0)
              Column(
                children: [
                  const Text(
                    "휴식 중...",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    "$remainingTime초 남음",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _completeSet,
                child: Text(
                  currentSet < sets.length - 1 ? "세트 완료" : "운동 완료",
                ),
              ),
          ],
        ),
      ),
    );
  }
}
