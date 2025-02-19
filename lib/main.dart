import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/bottom_navigation.dart';
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
  final Map<String, dynamic> progress =
      await SharedPreferencesHelper.getProgress();
  final bool isTestMode = await SharedPreferencesHelper.getIsTestMode();

  runApp(
    MyApp(
      isInitialTestSet: isInitialTestSet,
      initialWeek: progress['currentWeek'],
      initialDay: progress['currentDay'],
      initialLevel: progress['level'],
      isTestMode: isTestMode,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isInitialTestSet;
  final int initialWeek;
  final int initialDay;
  final String initialLevel;
  final bool isTestMode;

  const MyApp({
    super.key,
    required this.isInitialTestSet,
    required this.initialWeek,
    required this.initialDay,
    required this.initialLevel,
    required this.isTestMode,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.greyPrimary,
        canvasColor: AppColors.greyPrimary,
        fontFamily: "Pretendard",
        appBarTheme: AppBarTheme(
          toolbarHeight:
              screenWidth > 600 ? dynamicFontSize * 2.5 : dynamicFontSize * 3.5,
          backgroundColor: AppColors.greyPrimary,
          titleTextStyle: GoogleFonts.bebasNeue(
            fontSize: screenWidth > 600
                ? dynamicFontSize * 1.2
                : dynamicFontSize * 1.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          iconTheme: IconThemeData(
            size: screenWidth > 600
                ? dynamicFontSize * 1.2
                : dynamicFontSize * 1.5,
            color: Colors.black,
          ),
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.redPrimary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
                vertical: dynamicFontSize * 0.5, horizontal: dynamicFontSize),
            textStyle: TextStyle(
              inherit: true,
              fontWeight: FontWeight.bold,
              fontSize: dynamicFontSize,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
              dynamicFontSize * 1.5,
            )),
          ),
        ),
      ),
      home: isInitialTestSet
          ? BottomNavigation(
              initialWeek: initialWeek,
              initialLevel: initialLevel,
              isTestMode: isTestMode,
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
  static const Color greenPrimary = Color(0xFF007B55);
  static const Color yellowPrimary = Color(0xFFFFC107);
  static const Color bluePrimary = Color(0xFF0165E1);
  static const Color greyPrimary = Color(0xFFF4F4F4);
  static const Color darkGreyPrimary = Color(0xFF212121);

  static const Color redLight = Color(0x80D81F26);
  static const Color greenLight = Color(0x80007B55);
  static const Color blueLight = Color(0x800165E1);
  static const Color greyLight = Color(0x80F4F4F4);
  static const Color yellowLight = Color(0x80FFC107);
}
