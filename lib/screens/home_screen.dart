import 'package:flutter/material.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/screens/workout_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final int pushupCount;
  final int week;
  final String level;

  const HomeScreen({
    super.key,
    required this.pushupCount,
    required this.week,
    required this.level,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int currentDay = 1;
  int currentWeek = 1;

  @override
  void initState() {
    super.initState();
    _loadProgressFromPreferences();
  }

  Future<void> _loadProgressFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentDay = prefs.getInt('currentDay') ?? 1;
      currentWeek = prefs.getInt('currentWeek') ?? 1;
    });
  }

  Future<void> _saveProgressToPreferences(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentDay', currentDay);
    await prefs.setInt('currentWeek', currentWeek);
  }

  @override
  Widget build(BuildContext context) {
    // 오늘의 운동 플랜 가져오기
    final todayPlan =
        getPlanByLevelWeekAndDay(widget.level, widget.week, currentDay);

    // 진행률 계산 (6주 기준)
    final double progress = widget.week / 6;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              const Text(
                "Push 100",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 진행 상황 요약
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Week ${widget.week}, Day $currentDay (${widget.level})",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 오늘의 훈련 목표
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: todayPlan != null
                      ? Column(
                          children: [
                            const Text(
                              "오늘의 목표",
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${todayPlan.sets.join("개 x ")}개",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutScreen(
                                      level: widget.level,
                                      week: widget.week,
                                      day: currentDay, // 현재 날짜 전달
                                    ),
                                  ),
                                );
                              },
                              child: const Text("운동 시작"),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text(
                            "오늘의 플랜을 찾을 수 없습니다.",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ),
              ),
              const Spacer(),

              // 하단 동기 부여 문구
              const Text(
                "매일의 도전이 당신을 더 강하게 만듭니다!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
