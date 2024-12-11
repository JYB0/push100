import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:push100/screens/age_selection_screen.dart';

class InitialTestScreen extends StatefulWidget {
  const InitialTestScreen({super.key});

  @override
  _InitialTestScreenState createState() => _InitialTestScreenState();
}

class _InitialTestScreenState extends State<InitialTestScreen> {
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

  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "푸시업 초기 테스트",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  "정자세로 푸시업을 한 뒤 푸시업 개수를 설정하세요.",
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
                          RegExp(r'^[0-9]{0,2}$')),
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) {
                          // 99 이상의 값을 제한
                          if (int.tryParse(newValue.text) != null &&
                              int.parse(newValue.text) > 99) {
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
                  onPressed: () {
                    _dismissKeyboard();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AgeSelectionScreen(pushupCount: pushupCount),
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
