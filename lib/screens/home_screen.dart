import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/workout_history_screen.dart';
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

  Future<void> _confirmWorkout(BuildContext context, int nextDay) async {
    final result = await showModalActionSheet<bool>(
      context: context,
      title: '운동 시작',
      message: 'Day $nextDay 운동을 진행하시겠습니까?',
      cancelLabel: '취소',
      actions: [
        const SheetAction(
          label: '운동 시작',
          key: true,
        ),
      ],
    );

    if (result == true) {
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
    }
  }

  Future<void> _confirmTest(BuildContext context) async {
    final result = await showModalActionSheet<bool>(
      context: context,
      title: '테스트 시작',
      message: '${widget.week}주차 테스트를 진행하시겠습니까?',
      cancelLabel: '취소',
      actions: [
        const SheetAction(
          label: '테스트 시작',
          key: true, // "테스트 시작"을 선택하면 true 반환
        ),
      ],
    );

    if (result == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestScreen(
            week: widget.week,
            currentLevel: widget.level,
          ),
        ),
      );
    }
  }

  String _formatPushupText(List<int> sets) {
    if (sets.length <= 5) {
      // 세트 개수가 5개 이하이면 그냥 한 줄
      return sets.map((e) => "$e개").join(" x ");
    } else {
      int midIndex = (sets.length / 2).ceil(); // 전체 개수를 2로 나누고 올림 처리 (홀수 고려)

      final firstLine = sets.sublist(0, midIndex).map((e) => "$e개").join(" x ");
      final secondLine = sets.sublist(midIndex).map((e) => "$e개").join(" x ");

      return "$firstLine\n$secondLine"; // 줄바꿈 적용
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayPlan =
        getPlanByLevelWeekAndDay(widget.level, widget.week, currentDay);

    const int totalDays = 6 * 3;

    final int completedDays = ((widget.week - 1) * 3) + (currentDay - 1);
    final double progress = completedDays / totalDays;

    final progressColor =
        Color.lerp(AppColors.redPrimary, AppColors.greenPrimary, progress);

    final isTestDay = widget.isTestMode;

    // final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
              SizedBox(height: screenHeight * 0.025),

              // 진행 상황 요약
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutHistoryScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          widget.isTestMode
                              ? "Week ${widget.week} Test Day"
                              : "Week ${widget.week}, Day $currentDay (${widget.level})",
                          style: const TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        LinearProgressIndicator(
                          value: progress,
                          color: progressColor,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}% 완료",
                          style: const TextStyle(
                              fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // 오늘의 훈련 목표 또는 테스트 시작
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: todayPlan != null
                      ? Column(
                          children: [
                            const Text(
                              "오늘의 목표",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              isTestDay
                                  ? "테스트를 시작하세요!"
                                  : _formatPushupText(todayPlan.sets),
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.02),
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
                          child: ListTile(
                            title: Text("${widget.week}주차 테스트"),
                            subtitle: Text("${widget.week}주차 테스트를 시작하세요!"),
                            onTap: () {
                              _confirmTest(context);
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
                            child: ListTile(
                              title: Text("Day $nextDay 목표"),
                              subtitle: Text(_formatPushupText(nextPlan.sets)),
                              onTap: () {
                                _confirmWorkout(context, nextDay);
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
