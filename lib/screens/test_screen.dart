import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/screens/home_screen.dart';

class TestScreen extends StatefulWidget {
  final int week;
  final String currentLevel;

  const TestScreen({
    super.key,
    required this.week,
    required this.currentLevel,
  });

  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isEditing = false;
  int pushupCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.text = pushupCount.toString();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _saveTestResult(int pushupCount) async {
    await SharedPreferencesHelper.saveTestResult(widget.week, pushupCount);
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    );

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Week ${widget.week} 테스트"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${widget.week}주차 테스트",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  "정자세로 푸시업을 한 뒤 개수를 설정하세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: textStyle,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // 숫자만 허용
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]{0,3}$')), // 최대 3자리 허용
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) {
                          // 999 이상의 값을 제한
                          if (int.tryParse(newValue.text) != null &&
                              int.parse(newValue.text) > 999) {
                            return oldValue;
                          }
                          return newValue;
                        },
                      ),
                    ],
                    onTap: () {
                      if (_controller.text == "0") {
                        _controller.clear();
                      }
                    },
                    onChanged: (value) {
                      setState(() {
                        pushupCount = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    _dismissKeyboard();
                    _saveTestResult(pushupCount);

                    // 테스트 결과에 따라 플랜 업데이트
                    final updatedPlan = determineUpdatedPlan(
                        widget.week, pushupCount, widget.currentLevel);
                    final int nextWeek = updatedPlan['week'];
                    final String level = updatedPlan['level'];

                    await SharedPreferencesHelper.saveProgress(
                        nextWeek, 1, level);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          pushupCount: pushupCount,
                          week: nextWeek,
                          level: level,
                        ),
                      ),
                    );
                  },
                  child: const Text("테스트 완료"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
