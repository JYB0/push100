import 'package:flutter/material.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text("📌 앱 가이드")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.01),
            Text(
              "1. 오늘의 목표 운동을 수행하세요.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "2. 푸시업을 한 날로부터 2일 후에 푸시업(혹은 테스트)을 시작해주세요.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "3. 테스트를 한 날로부터 2일 후에 푸시업을 진행해주세요.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "4. 테스트 통과 기준에 못 미치면 해당 주차는 반복됩니다.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "5. 6주간 프로그램 진행 후 푸시업 100개를 성공하면 끝입니다! 축하드립니다!",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
          ],
        ),
      ),
    );
  }
}
