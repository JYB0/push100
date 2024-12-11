import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:push100/screens/home_screen.dart';

class InitialTestScreen extends StatefulWidget {
  const InitialTestScreen({super.key});

  @override
  _InitialTestScreenState createState() => _InitialTestScreenState();
}

class _InitialTestScreenState extends State<InitialTestScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isEditing = false; // 숫자를 편집 중인지 여부
  int pushupCount = 0; // 푸시업 개수를 저장하는 변수

  @override
  void initState() {
    super.initState();
    _controller.text = pushupCount.toString(); // 초기값 설정
  }

  // 키보드 닫기 함수
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus(); // 현재 포커스 해제
  }

  // 텍스트 너비 계산 함수
  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width; // 텍스트의 실제 너비 반환
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    );

    return GestureDetector(
      onTap: _dismissKeyboard, // 키보드 외부 터치 시 닫기
      child: Scaffold(
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

                // 숫자와 동적 언더바
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isEditing = true; // 클릭 시 편집 모드로 전환
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isEditing
                          ? TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              // textInputAction: TextInputAction.done, // 확인 버튼 설정
                              style: textStyle,
                              autofocus: true, // 자동으로 키보드 표시
                              decoration: const InputDecoration(
                                border: InputBorder.none, // 기본 테두리 제거
                              ),
                              onChanged: (value) {
                                setState(() {
                                  pushupCount = int.tryParse(value) ?? 0;
                                });
                              },
                              onSubmitted: (value) {
                                setState(() {
                                  pushupCount = int.tryParse(value) ?? 0;
                                  isEditing = false; // 입력 완료 후 편집 모드 해제
                                  _dismissKeyboard(); // 키보드 닫기
                                });
                              },
                            )
                          : Text(
                              "$pushupCount",
                              style: textStyle,
                            ),
                      const SizedBox(height: 8), // 숫자와 언더바 사이 간격
                      Container(
                        height: 2,
                        width: _calculateTextWidth(
                          "$pushupCount",
                          textStyle,
                        ), // 텍스트 길이에 맞춘 언더바
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 저장 및 다음 화면으로 이동 버튼
                ElevatedButton(
                  onPressed: () {
                    _dismissKeyboard(); // 버튼 클릭 시 키보드 닫기
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()));
                  },
                  child: const Text("테스트 완료 및 시작"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
