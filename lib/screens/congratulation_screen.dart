import 'package:flutter/material.dart';
import 'package:push100/screens/bottom_navigation.dart';

class CongratulationsScreen extends StatelessWidget {
  const CongratulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("🎉 축하합니다!"),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "6주 푸시업 챌린지를 성공했습니다!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const BottomNavigation(
                        initialWeek: 7, // ✅ 7주차로 설정하여 홈 화면에서 nextPlan 안 보이게
                        initialLevel: "초보", // ✅ 기존 레벨 유지
                        isTestMode: false, // ✅ 테스트 모드 해제
                      ),
                    ),
                    (route) => false, // ✅ 기존 모든 화면 제거하고 `BottomNavigation`만 남김
                  );
                },
                child: const Text("홈으로 가기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
