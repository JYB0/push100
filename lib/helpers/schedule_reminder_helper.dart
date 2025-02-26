import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:push100/main.dart'; // 알림 플러그인 접근을 위해 필요

void scheduleWorkoutReminder(bool isTestMode) async {
  tz.initializeTimeZones(); // 📌 타임존 초기화

  // 📌 현재 시간 가져오기
  final now = tz.TZDateTime.now(tz.local);

  // 📌 2일 뒤 날짜 계산
  final scheduledDate = now.add(const Duration(seconds: 30));

  // 📌 알림 메시지 설정 (isTestMode 여부에 따라 다르게 설정)
  String title = isTestMode ? "테스트 진행할 시간이에요!" : "운동할 시간이에요!";
  String body = isTestMode ? "최대 개수를 측정하세요!" : "오늘 운동을 완료하세요!";

  int notificationId = 2000;

  // ✅ 알림 상세 설정 (Android)
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'workout_reminder_channel', // 고유 채널 ID
    'Workout Reminder', // 채널 이름
    channelDescription: '2일 뒤 운동 알림', // 채널 설명
    importance: Importance.max, // 중요도 (최상)
    priority: Priority.max, // 우선순위 높음
    icon: 'transparent',
    color: AppColors.greenPrimary,
    largeIcon: DrawableResourceAndroidBitmap('large_notification_icon'),
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  // ✅ 알림 예약 (앱 종료 후에도 유지됨)
  await flutterLocalNotificationsPlugin.zonedSchedule(
    notificationId, // 알림 ID
    title, // ✅ isTestMode 여부에 따라 다른 제목
    body, // ✅ isTestMode 여부에 따라 다른 메시지
    scheduledDate,
    platformDetails,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // 특정 날짜 & 시간
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}
