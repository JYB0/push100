import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/bottom_navigation.dart';

class InitialTestScreen extends StatefulWidget {
  const InitialTestScreen({super.key});

  @override
  InitialTestScreenState createState() => InitialTestScreenState();
}

class InitialTestScreenState extends State<InitialTestScreen> {
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

  double calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  void _saveInitialTest(int pushupCount) async {
    await SharedPreferencesHelper.saveInitialTest(pushupCount);
  }

  void _navigateWithAnimation(BuildContext context, Widget targetScreen) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    final textStyle = TextStyle(
      fontSize: dynamicFontSize * 4,
      fontWeight: FontWeight.bold,
      color: AppColors.redPrimary,
    );

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text(
            "Initial Test",
          ),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const Text(
                  //   "푸시업 초기 테스트",
                  //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  // ),
                  SizedBox(height: screenHeight * 0.05),
                  Text(
                    "정자세로 푸시업을 한 뒤 푸시업 개수를 설정하세요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: dynamicFontSize),
                  ),
                  SizedBox(height: screenHeight * 0.1),
                  SizedBox(
                    width: screenWidth * 0.7,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      showCursor: false,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.yellowPrimary,
                            width: 2.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.yellowPrimary,
                            width: 3,
                          ),
                        ),
                      ),
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
                  SizedBox(height: screenHeight * 0.05),
                  ElevatedButton(
                    onPressed: () async {
                      _dismissKeyboard();
                      final initialPlan = determineInitialPlan(pushupCount);
                      final int week = initialPlan['week'];
                      final String level = initialPlan['level'];
                      _saveInitialTest(pushupCount);

                      _navigateWithAnimation(
                        context,
                        BottomNavigation(
                          initialWeek: week,
                          initialLevel: level,
                          isTestMode: false,
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
      ),
    );
  }
}
