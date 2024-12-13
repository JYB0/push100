import 'package:flutter/material.dart';
import 'package:push100/helpers/workout_helper.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 현재 주차와 날짜를 계산 (예: Week 1, Day 1로 시작)
    const int week = 1;
    const int day = 1;
    final String level =
        pushupCount < 10 ? "초급" : (pushupCount < 20 ? "중급" : "고급");

    // 오늘의 운동 플랜 가져오기
    final todayPlan = getPlanByLevelWeekAndDay(level, week, day);

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
              const Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        "Week $week, Day $day",
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(value: 0.2), // 진행률 (임시 값)
                      SizedBox(height: 10),
                      Text("총 150개의 푸시업 완료!"),
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
                                // 훈련 화면으로 이동
                              },
                              child: const Text("훈련 시작"),
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
