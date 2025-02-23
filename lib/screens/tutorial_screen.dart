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
              "2. 한 세트를 완료한 후, 노란색 원을 터치하면 해당 세트가 완료됩니다.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "3. 정해진 개수를 채우지 못했다면 '-' 버튼을 눌러 수행한 횟수를 조정한 후, 세트를 완료하세요.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "4. 마지막 세트에서는 최대한 많은 푸시업을 수행하세요. (목표 횟수 이상 가능)",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "5. 푸시업을 수행한 후 2일 뒤 다시 훈련(또는 테스트)을 진행하세요.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "6. 테스트를 진행한 후 2일 뒤 푸시업 훈련을 시작하세요.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "7. 테스트 통과 기준에 미치지 못하면 해당 주차가 반복됩니다.",
              style: TextStyle(
                fontSize: dynamicFontSize,
              ),
            ),
            Text(
              "8. 6주간 프로그램을 완료하고 푸시업 100개를 달성하면 챌린지가 끝납니다! 🎉 축하합니다!",
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
