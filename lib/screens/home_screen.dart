import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   // title: const Text("Push 100"),
      //   // centerTitle: true,
      // ),
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
                        "Week 3, Day 2",
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(value: 0.7), // 진행률
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
                  child: Column(
                    children: [
                      const Text(
                        "오늘의 목표",
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      const Text("20개 x 5세트"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          // 훈련 화면으로 이동
                        },
                        child: const Text("훈련 시작"),
                      ),
                    ],
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
