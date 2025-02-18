import 'package:flutter/material.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("앱 사용법")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📌 앱 사용법",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("1. 하루 목표 운동을 수행하세요."),
            const Text("2. 운동이 끝나면 '완료' 버튼을 눌러 기록하세요."),
            const Text("3. 주차별 테스트를 진행하며 점진적으로 성장하세요!"),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("확인"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
