import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/home_screen.dart';
import 'package:push100/screens/initial_test_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 알림 초기화
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {},
  );

  // 2. 초기 설정 확인
  final bool isInitialTestSet = await checkInitialTest();

  runApp(MyApp(isInitialTestSet: isInitialTestSet));
}

class MyApp extends StatelessWidget {
  final bool isInitialTestSet;

  const MyApp({super.key, required this.isInitialTestSet});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isInitialTestSet
          ? const HomeScreen(
              pushupCount: 0,
              week: 1,
              level: "초급",
            )
          : const InitialTestScreen(),
    );
  }
}

Future<bool> checkInitialTest() async {
  final pushupCount = await SharedPreferencesHelper.getInitialPushupCount();
  return pushupCount > 0;
}
