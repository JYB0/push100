import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:push100/main.dart';
import 'package:vibration/vibration.dart'; // 알림 플러그인 접근을 위해 필요

Future<void> scheduleRestCompleteNotification(int secondsFromNow) async {
  // ✅ 타임존 초기화
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // ✅ 알림 울릴 시간 설정
  final scheduledDate =
      tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow));

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'rest_complete_channel', // 고유 채널 ID
    'Rest Complete', // 채널 이름
    channelDescription: '세트 간 휴식 타이머 알림', // 채널 설명
    importance: Importance.max,
    priority: Priority.max,
    icon: 'transparent',
    color: AppColors.greenPrimary,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('ping'),
    largeIcon: DrawableResourceAndroidBitmap('large_notification_icon'),
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    sound: 'ping.wav',
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails, iOS: iosDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    1000, // 알림 ID (다른 ID와 겹치지 않도록 고유하게)
    '휴식 완료',
    '필요하면 더 쉬어도 괜찮아요.',
    scheduledDate,
    platformDetails,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );

  if (await Vibration.hasVibrator() ?? false) {
    Vibration.vibrate(duration: 500);
  }
}

void scheduleWorkoutReminder(bool isTestMode) async {
  tz.initializeTimeZones(); // 📌 타임존 초기화
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  final prefs = await SharedPreferences.getInstance();
  final bool hasCustomTime = prefs.containsKey('reminder_hour') &&
      prefs.containsKey('reminder_minute');

  final isEnabled = prefs.getBool('reminder_enabled') ?? true;
  if (!isEnabled) return; // 🔴 알림 꺼져 있으면 종료

  final hour = prefs.getInt('reminder_hour') ?? 18;
  final minute = prefs.getInt('reminder_minute') ?? 0;
  final intervalDays = prefs.getInt('reminder_interval') ?? 2;

  // 📌 현재 시간 가져오기
  final now = tz.TZDateTime.now(tz.local);

  final scheduledDate = hasCustomTime
      ? tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).add(Duration(days: intervalDays))
      : now.add(Duration(days: intervalDays));

  // 📌 2일 뒤 날짜 계산
  // final scheduledDate = now.add(const Duration(days: 2));

  // 📌 알림 메시지 설정 (isTestMode 여부에 따라 다르게 설정)
  String title = isTestMode ? "테스트 진행할 시간이에요!" : "운동할 시간이에요!";
  String body = isTestMode ? "최대 개수를 측정하세요!" : "오늘 운동을 완료하세요!";

  int notificationId = 2000;
  await flutterLocalNotificationsPlugin.cancel(notificationId);

  // ✅ 알림 상세 설정 (Android)
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'workout_reminder_channel', // 고유 채널 ID
    'Workout Reminder', // 채널 이름
    channelDescription: '설정한 주기에 따라 운동 알림', // 채널 설명
    importance: Importance.max, // 중요도 (최상)
    priority: Priority.max, // 우선순위 높음
    icon: 'transparent',
    color: AppColors.greenPrimary,
    largeIcon: DrawableResourceAndroidBitmap('large_notification_icon'),
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  // ✅ 알림 예약 (앱 종료 후에도 유지됨)
  if (intervalDays == 1) {
    // ✅ 매일 반복 알림
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간 반복
    );
  } else {
    // ✅ 하루 이상 주기 → 한 번만 알림
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      platformDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
