import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  final String email = "morebetterlifeapp@gmail.com";

  void _copyEmail(BuildContext context) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("이메일 주소가 복사되었습니다!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text("💬 앱 문의하기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: dynamicFontSize,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyEmail(context),
                  icon: const Icon(Icons.copy),
                  tooltip: '이메일 복사',
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "문의사항이 있으면 언제든지 이메일로 연락주세요!",
              style: TextStyle(fontSize: dynamicFontSize * 0.9),
            ),
          ],
        ),
      ),
    );
  }
}
