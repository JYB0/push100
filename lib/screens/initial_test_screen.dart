import 'package:flutter/material.dart';
import 'package:wheel_slider/wheel_slider.dart';

class InitialTestScreen extends StatefulWidget {
  const InitialTestScreen({super.key});

  @override
  _InitialTestScreenState createState() => _InitialTestScreenState();
}

class _InitialTestScreenState extends State<InitialTestScreen> {
  int pushupCount = 0; // 푸시업 개수를 저장하는 변수

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Initial Test"),
      //   centerTitle: true,
      // ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 타이틀 및 안내 문구
              const Text(
                "푸시업 초기 테스트",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "정자세로 푸시업을 한 뒤 푸시업 개수를 설정하세요.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),

              // WheelSlider를 사용한 푸시업 설정
              WheelSlider.number(
                horizontal: false,
                totalCount: 100, // 최대 100개 설정 가능
                initValue: pushupCount, // 초기값 설정
                unSelectedNumberStyle: const TextStyle(
                  fontSize: 20.0,
                  color: Colors.black54,
                ),
                selectedNumberStyle: const TextStyle(
                  fontSize: 30,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                isInfinite: false,
                currentIndex: pushupCount,
                onValueChanged: (value) {
                  setState(() {
                    pushupCount = value; // 사용자가 선택한 값을 저장
                  });
                },
                perspective: 0.005, // 깊이감
                hapticFeedbackType: HapticFeedbackType.heavyImpact,
              ),

              const SizedBox(height: 20),

              // 선택된 푸시업 개수를 보여주는 텍스트
              Text(
                "테스트 푸시업 개수: $pushupCount",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 40),

              // 저장 및 다음 화면으로 이동 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NextScreen(pushupCount: pushupCount),
                    ),
                  );
                },
                child: const Text("테스트 완료 및 시작"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 다음 화면 예제
class NextScreen extends StatelessWidget {
  final int pushupCount; // 이전 화면에서 받은 푸시업 개수

  const NextScreen({super.key, required this.pushupCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Next Screen")),
      body: Center(
        child: Text(
          "당신은 $pushupCount개의 푸시업을 설정했습니다!",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
