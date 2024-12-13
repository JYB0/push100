import 'package:flutter/material.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/home_screen.dart';

import 'package:push100/screens/initial_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isInitialTestset = await checkInitialTest();
  runApp(MyApp(isInitialTestSet: isInitialTestset));
}

class MyApp extends StatelessWidget {
  final bool isInitialTestSet;

  const MyApp({super.key, required this.isInitialTestSet});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버그 배너 숨기기
      theme: ThemeData(
        primarySwatch: Colors.blue, // 전체 앱의 색상 테마 설정
      ),
      home: isInitialTestSet
          ? const HomeScreen(
              pushupCount: 0, // 기본값 전달 (필요시 수정)
              week: 1, // 기본 주차 전달 (필요시 수정)
              level: "초급", // 기본 단계 전달 (필요시 수정)
            )
          : const InitialTestScreen(), // 초기 설정 화면
    );
  }
}

// 초기 테스트 여부 확인 함수
Future<bool> checkInitialTest() async {
  final pushupCount = await SharedPreferencesHelper.getInitialPushupCount();
  return pushupCount > 0; // 푸시업 개수가 0보다 크면 초기 설정이 완료된 것으로 간주
}
