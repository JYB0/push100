import 'package:flutter/material.dart';

import 'package:push100/screens/home_screen.dart';
import 'package:push100/screens/initial_test_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
      theme: ThemeData(
        primarySwatch: Colors.blue, // 전체 앱의 색상 테마 설정
      ),
      home: const InitialTestScreen(), // 첫 화면으로 HomeScreen 설정
    );
  }
}
