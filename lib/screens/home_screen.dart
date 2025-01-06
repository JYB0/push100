import 'package:flutter/material.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/screens/workout_screen.dart';
import 'package:push100/screens/test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final int pushupCount;
  final int week;
  final String level;
  final bool isTestMode;

  const HomeScreen({
    super.key,
    required this.pushupCount,
    required this.week,
    required this.level,
    this.isTestMode = false, // 기본값 설정
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

  @override
  Widget build(BuildContext context) {
    // 오늘의 운동 플랜 가져오기
    final todayPlan =
        getPlanByLevelWeekAndDay(widget.level, widget.week, currentDay);

    // 진행률 계산 (6주 기준)
    final double progress = widget.week / 6;

    // 테스트 조건 확인
    final isTestDay = widget.isTestMode;

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

              // 오늘의 훈련 목표 또는 테스트 시작
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
                              isTestDay
                                  ? "테스트를 시작하세요!"
                                  : "${todayPlan.sets.join("개 x ")}개",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (isTestDay) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TestScreen(
                                        week: widget.week,
                                        currentLevel: widget.level,
                                      ),
                                    ),
                                  );
                                } else {
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
                                }
                              },
                              child: Text(isTestDay ? "테스트 시작" : "운동 시작"),
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
              Expanded(
                child: ListView.builder(
                  itemCount: (3 - currentDay) + 1, // 3일차 이후 테스트 카드를 포함한 총 항목 수
                  itemBuilder: (context, index) {
                    // 테스트 카드가 맨 마지막에 위치하도록 설정
                    if (index == (3 - currentDay)) {
                      // 테스트 조건 설정
                      final isTestWeek = (widget.week == 2 ||
                          widget.week == 4 ||
                          widget.week == 5);
                      if (isTestWeek && !isTestDay) {
                        return Card(
                          elevation: 4,
                          child: ListTile(
                            title: Text("${widget.week}주차 테스트"),
                            subtitle: Text("${widget.week}주차 테스트를 시작하세요!"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestScreen(
                                    week: widget.week,
                                    currentLevel: widget.level,
                                  ), // 테스트 화면으로 이동
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return const SizedBox(); // 테스트 주차가 아닌 경우 아무것도 표시하지 않음
                      }
                    }

                    // 운동 목표 카드
                    final nextDay = currentDay + index + 1;
                    final nextPlan = getPlanByLevelWeekAndDay(
                        widget.level, widget.week, nextDay);

                    return nextPlan != null
                        ? Card(
                            elevation: 4,
                            child: ListTile(
                              title: Text("Day $nextDay 목표"),
                              subtitle: Text("${nextPlan.sets.join("개 x ")}개"),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutScreen(
                                      level: widget.level,
                                      week: widget.week,
                                      day: nextDay,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : const SizedBox();
                  },
                ),
              ),

              // 하단 동기 부여 문구
              const Text(
                "꾸준한 도전이 당신을 더 강하게 만듭니다!",
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
