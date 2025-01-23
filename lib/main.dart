import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/home_screen.dart';
import 'package:push100/screens/initial_test_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        scaffoldBackgroundColor: AppColors.greyPrimary,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.greyPrimary,
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.redPrimary,
            foregroundColor: Colors.white,
          ),
        ),
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

class AppColors {
  static const Color redPrimary = Color(0xFFD81F26);
  static const Color greenPrimary = Color(0xFF006241);
  static const Color yellowPrimary = Color(0xFFFFC107);
  static const Color bluePrimary = Color(0xFF0165E1);
  static const Color greyPrimary = Color(0xFFF4F4F4);
  static const Color darkGreyPrimary = Color(0xFF212121);

  static const Color redLight = Color(0x80D81F26);
  static const Color greenLight = Color(0x80006241);
  static const Color blueLight = Color(0x800165E1);
  static const Color greyLight = Color(0x80F4F4F4);
  static const Color yellowLight = Color(0x80FFC107);
}
