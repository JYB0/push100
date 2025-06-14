import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:push100/firebase_options.dart';
import 'package:push100/helpers/firebase_sync_helper.dart';

// import 'package:push100/helpers/ad_helper.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/screens/bottom_navigation.dart';
import 'package:push100/screens/initial_test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await initializeUid();
  await dotenv.load(fileName: ".env");
  MobileAds.instance.initialize();

  final isDateFixed = await SharedPreferencesHelper.getDateFixed();
  if (!isDateFixed) {
    await SharedPreferencesHelper.fixStoredDates();
    await SharedPreferencesHelper.setDateFixed();
  }

  await Future.delayed(
    const Duration(milliseconds: 500),
    () {
      FlutterNativeSplash.remove();
    },
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('transparent');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {},
  );

  await requestNotificationPermissions();
  await androidRequestNotificationPermissions();

  final bool isInitialTestSet = await checkInitialTest();
  final Map<String, dynamic> progress =
      await SharedPreferencesHelper.getProgress();
  final bool isTestMode = await SharedPreferencesHelper.getIsTestMode();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await restoreDataFromFirebase(user);
  }

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

Future<void> _checkUserStatus() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await user.reload(); // 서버에서 계정 상태 확인
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await FirebaseAuth.instance.signOut(); // 자동 로그아웃
        // ❗ 로그인 화면으로 이동 등 추가 처리
      }
    }
  }
}

Future<void> initializeUid() async {
  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString('device_uid');
  if (uid == null) {
    final newUid = const Uuid().v4();
    await prefs.setString('device_uid', newUid);
  }
}

Future<void> requestNotificationPermissions() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 📌 Android 알림 권한 요청
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  try {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  } catch (e) {
    // 일부 기기나 OS에서는 예외가 발생할 수 있음
    debugPrint('requestExactAlarmsPermission error: $e');
  }

  // 📌 iOS 알림 권한 요청
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

Future<void> androidRequestNotificationPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class MyApp extends StatefulWidget {
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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
      ],
      home: widget.isInitialTestSet
          ? BottomNavigation(
              initialWeek: widget.initialWeek,
              initialLevel: widget.initialLevel,
              isTestMode: widget.isTestMode,
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
