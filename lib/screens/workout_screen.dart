import 'dart:async';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:push100/helpers/ad_helper.dart';
import 'package:push100/helpers/schedule_reminder_helper.dart';
import 'package:push100/screens/daily_workout_complete_screen.dart';
import 'package:vibration/vibration.dart';

import 'package:push100/main.dart';
import 'package:push100/helpers/workout_helper.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
// import 'package:push100/screens/home_screen.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class WorkoutScreen extends StatefulWidget {
  final String level;
  final int week;
  final int day;

  const WorkoutScreen({
    super.key,
    required this.level,
    required this.week,
    required this.day,
  });

  @override
  WorkoutScreenState createState() => WorkoutScreenState();
}

class WorkoutScreenState extends State<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  late List<int> sets;
  late ScrollController _scrollController;
  bool _isMotivationDialogVisible = false; // class에 선언

  int currentSet = 0;
  int restTime = 0;
  int elapsedSeconds = 0;
  int currentTargetReps = 0;

  Timer? timer;
  bool isResting = false;
  List<int> userReps = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    sets = [];
    userReps = [];
    _loadWorkoutPlan();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true); // 🔥 무한 반복 (깜박깜박)

    // ✅ 배경색 변경 애니메이션 (밝아졌다가 어두워짐)
    _colorAnimation = ColorTween(
      begin: Colors.white, // 밝은 색
      end: const Color.fromARGB(67, 246, 211, 105), // 어두운 색 (강조 효과)
    ).animate(_animationController);

    AdHelper.loadRewardedInterstitialAd();
  }

  void _increaseReps() {
    setState(() {
      if (currentSet == sets.length - 1) {
        // 마지막 세트는 제한 없이 증가 가능
        currentTargetReps++;
      } else if (currentTargetReps < sets[currentSet]) {
        // 다른 세트는 sets[currentSet] 이하로 제한
        currentTargetReps++;
      }
    });
  }

  void _decreaseReps() {
    setState(() {
      if (currentTargetReps > 0) {
        currentTargetReps--;
      }
    });
  }

  void _loadWorkoutPlan() {
    final plan =
        getPlanByLevelWeekAndDay(widget.level, widget.week, widget.day);
    if (plan != null) {
      sets = plan.sets;
      restTime = plan.restTime;
      userReps = List<int>.from(sets);
      currentTargetReps = sets.isNotEmpty ? sets[0] : 0;
    } else {
      sets = [];
      restTime = 60; // 기본값
      userReps = [];
      currentTargetReps = 0;
    }
    setState(() {});
  }

  void _startRestTimer() {
    if (timer != null) {
      timer!.cancel();
    }

    setState(() {
      elapsedSeconds = 0;
      isResting = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds += 1;
      });

      if (elapsedSeconds == restTime) {
        _showRestCompleteNotification();
      }
    });
  }

  void _scrollToCurrentSet() {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    final double spacing = screenWidth * 0.04; // 간격
    final double circleSize = screenWidth * 0.15; // 원 크기
    // final double fontSize = circleSize * 0.35; // 글자 크기도 비례 설정
    final double itemWidth = circleSize + spacing;

    if (_scrollController.hasClients) {
      final position = currentSet * itemWidth - (itemWidth * 2); // 중앙 근처에 표시
      _scrollController.animateTo(
        position.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showRestCompleteNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rest_complete_channel',
      'Rest Complete',
      channelDescription: 'Notification for rest completion',
      importance: Importance.max,
      priority: Priority.max,
      icon: 'transparent',
      color: AppColors.greenPrimary,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ping'),
      largeIcon: DrawableResourceAndroidBitmap('large_notification_icon'),
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      sound: 'ping.wav',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '휴식 완료',
      '다음 세트를 시작할 시간이에요!\n필요하면 더 쉬어도 괜찮아요.',
      platformChannelSpecifics,
    );

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }

  void _showMotivationDialog() {
    if (_isMotivationDialogVisible) return;

    _isMotivationDialogVisible = true;

    final List<String> messages = [
      "절반이나 해냈어! 남은 반도 충분히 할 수 있어 🔥",
      "지금 포기하면 어제와 똑같아. 오늘의 널 믿어!",
      "세트 반 완료! 이 정도면 이미 멋져 💪",
      "여기까지 온 너, 진심으로 대단해 👏",
      "포기하지 않는 너, 매일 성장 중이야!",
      "이 순간도 넌 더 강해지고 있어 🔥",
      "할 수 있어, 넌 이미 시작했고 절반을 넘었잖아!",
      "지금의 땀은 미래의 너를 웃게 해줄 거야 😊",
      "힘들수록 성장하는 거야. 넌 잘하고 있어!",
      "혼자가 아니야. 응원할게, 끝까지 함께 가자!",
    ];

    final message = (messages..shuffle()).first;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Motivation',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeOutBack.transform(animation.value) - 1.0;

        // ✅ 딜레이 후 안전하게 닫기
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 4), () {
            if (_isMotivationDialogVisible && dialogContext.mounted) {
              Navigator.of(dialogContext).maybePop();
              _isMotivationDialogVisible = false;
            }
          });
        });

        return Transform.translate(
          offset: Offset(0, curvedValue * -50),
          child: Opacity(
            opacity: animation.value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Material(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  elevation: 10,
                  child: GestureDetector(
                    onTap: () {
                      if (_isMotivationDialogVisible) {
                        Navigator.of(dialogContext).pop();
                        _isMotivationDialogVisible = false;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.flash_on,
                              size: 28, color: AppColors.redPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isMotivationDialogVisible = false; // 팝업이 닫히면 플래그 초기화
    });
  }

  Widget _buildSetCircles() {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    final double spacing = screenWidth * 0.03; // 간격
    final double circleSize = screenWidth * 0.15; // 원 크기
    final double fontSize = circleSize * 0.35; // 글자 크기도 비례 설정

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal, // 가로 스크롤 활성화
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing / 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(
            sets.length,
            (index) {
              bool isCurrentSet = index == currentSet;
              bool isFutureSet = index > currentSet;

              Color borderColor;
              Color textColor;
              double textWidth;

              if (isCurrentSet) {
                borderColor = AppColors.greyPrimary;
                textColor = Colors.grey;
                textWidth = 3;
              } else if (isFutureSet) {
                borderColor = AppColors.greyPrimary; // 미래의 세트는 회색
                textColor = Colors.grey;
                textWidth = 1;
              } else if (userReps[index] >= sets[index]) {
                borderColor = AppColors.greenPrimary; // 목표 이상 수행한 경우 초록색
                textColor = Colors.white;
                textWidth = 3;
              } else {
                borderColor = AppColors.redPrimary; // 목표보다 적게 수행한 경우 빨간색
                textColor = Colors.white;
                textWidth = 3;
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor,
                    border: Border.all(
                      color: borderColor,
                      width: textWidth,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${userReps[index]}",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _completeWorkout() async {
    final nextDay = widget.day + 1;
    final isTestWeek = (widget.week == 2 ||
        widget.week == 4 ||
        widget.week == 5 ||
        widget.week == 6);

    _animationController.stop();

    final totalPushups = userReps.reduce((a, b) => a + b);

    if (widget.week == 1 && widget.day == 3) {
      // ✅ 1주차 3일차 완료 시 1주차의 운동 기록 검토
      bool needToRetry = await _checkLatestWeekOneCompletion();

      if (needToRetry) {
        await _showRetryWeekOneDialog();
        return;
      }
    }

    if (widget.week == 3 && widget.day == 3) {
      bool needToRetryWeek3 = await _checkLatestWeekThreeCompletion();

      if (needToRetryWeek3) {
        await _showRetryWeekThreeDialog();
        return;
      }
    }

    if (nextDay > 3 && isTestWeek) {
      // 테스트 주차의 마지막 날인 경우 테스트 모드로 전환
      await SharedPreferencesHelper.saveProgress(widget.week, 3, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(true);

      scheduleWorkoutReminder(true);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              DailyWorkoutCompleteScreen(
            totalPushups: totalPushups,
            week: widget.week,
            day: widget.day,
            level: widget.level,
            isTestMode: true, // 테스트 모드 활성화
          ),
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
    } else if (nextDay > 3) {
      // 일반 주차의 마지막 날인 경우 다음 주차로 이동
      final nextWeek = widget.week + 1;

      await SharedPreferencesHelper.saveProgress(nextWeek, 1, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);

      scheduleWorkoutReminder(false);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              DailyWorkoutCompleteScreen(
            totalPushups: totalPushups,
            week: nextWeek,
            day: 1,
            level: widget.level,
            isTestMode: false,
          ),
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
    } else {
      // 같은 주차의 다음 날로 이동
      await SharedPreferencesHelper.saveProgress(
          widget.week, nextDay, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);

      scheduleWorkoutReminder(false);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              DailyWorkoutCompleteScreen(
            totalPushups: totalPushups,
            week: widget.week,
            day: widget.day,
            level: widget.level,
            isTestMode: false,
          ),
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
  }

  Future<void> _completeSet() async {
    if (currentSet < sets.length - 1) {
      setState(() {
        userReps[currentSet] = currentTargetReps;
        currentSet += 1;

        if (currentSet < sets.length) {
          currentTargetReps = userReps[currentSet]; // 다음 세트 목표 로드
          _startRestTimer();
        }
      });
      if (currentSet == sets.length) {
        _saveWorkoutRecord(); // 운동 기록 저장
      }
      _scrollToCurrentSet();
      _animationController.reset();
      _animationController.repeat(reverse: true);
      // if (mounted) _showMotivationDialog();

      if (currentSet == (sets.length / 2).ceil()) {
        if (AdHelper.isRewardedInterstitialAdLoaded) {
          AdHelper.showRewardedInterstitialAd(() {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _showMotivationDialog();
            });
          });
        } else {
          AdHelper.loadRewardedInterstitialAd();
        }
      }
    } else {
      userReps[currentSet] = currentTargetReps;
      _saveWorkoutRecord();
      await _completeWorkout();
      // _showWorkoutCompleteNotification();
      // if (AdHelper.isRewardedAdLoaded) {
      //   // 마지막 세트 끝나고 광고 한번만 나오게
      //   AdHelper.showRewardedAd(
      //     () async {
      //       // 광고 시청 완료 후 다시 광고 로드
      //       AdHelper.loadRewardedAd();
      //       await _completeWorkout();
      //     },
      //   );
      // } else {
      //   await _completeWorkout();
      // }
    }
  }

  // Future<bool> _checkWeekOneCompletion() async {
  //   final records = await SharedPreferencesHelper.getWorkoutRecords();

  //   for (var record in records) {
  //     if (record['week'] == 1 && record['day'] <= 3) {
  //       List<int> plannedReps = List<int>.from(record['plannedReps']);
  //       List<int> userReps = List<int>.from(record['userReps']);

  //       // 목표 개수를 하나라도 못 채운 경우가 있으면 재진행 필요
  //       for (int i = 0; i < plannedReps.length; i++) {
  //         if (userReps[i] < plannedReps[i]) {
  //           return true;
  //         }
  //       }
  //     }
  //   }
  //   return false; // 모든 날 목표 달성했으면 재진행 필요 없음
  // }

  Future<bool> _checkLatestWeekOneCompletion() async {
    final records = await SharedPreferencesHelper.getWorkoutRecords();

    // 1주차 1~3일차 최근 기록 가져오기
    for (int day = 1; day <= 3; day++) {
      final dayRecords = records
          .where((record) => record['week'] == 1 && record['day'] == day)
          .toList();

      if (dayRecords.isEmpty) {
        return true; // 기록이 없으면 실패로 간주
      }

      // 최신 기록으로 정렬
      dayRecords.sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      final latest = dayRecords.first;

      final plannedReps = List<int>.from(latest['plannedReps']);
      final userReps = List<int>.from(latest['userReps']);

      for (int i = 0; i < plannedReps.length; i++) {
        if (userReps[i] < plannedReps[i]) {
          return true;
        }
      }
    }
    return false;
  }

  static Future<bool> _checkLatestWeekThreeCompletion() async {
    final records = await SharedPreferencesHelper.getWorkoutRecords();

    // 3주차 1~3일차 최근 기록 가져오기
    for (int day = 1; day <= 3; day++) {
      final dayRecords = records
          .where((record) => record['week'] == 3 && record['day'] == day)
          .toList();

      if (dayRecords.isEmpty) {
        return true; // 기록이 없으면 실패로 간주
      }

      // 최신 기록 정렬
      dayRecords.sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
      final latest = dayRecords.first;

      final plannedReps = List<int>.from(latest['plannedReps']);
      final userReps = List<int>.from(latest['userReps']);

      for (int i = 0; i < plannedReps.length; i++) {
        if (userReps[i] < plannedReps[i]) {
          return true;
        }
      }
    }
    return false;
  }

  /// 🔥 `showOkCancelAlertDialog`를 이용한 1주차 재진행 여부 확인
  Future<void> _showRetryWeekOneDialog() async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: "1주차 재진행",
      message: "1주차에서 목표 개수를\n달성하지 못한 날이 있습니다.\n"
          "1주차를 다시 진행하시겠습니까?",
      okLabel: "네",
      cancelLabel: "아니요",
      isDestructiveAction: true,
    );

    if (!mounted) return;

    if (result == OkCancelResult.ok) {
      // ✅ 1주차 1일차부터 다시 시작
      await SharedPreferencesHelper.saveProgress(1, 1, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);

      scheduleWorkoutReminder(false);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      _navigateToDailyWorkoutCompleteNavigation(
          isTestMode: false, nextWeek: 1, nextDay: 1);
    } else {
      // ✅ 그냥 진행
      const nextWeek = 2;
      await SharedPreferencesHelper.saveProgress(nextWeek, 1, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);

      scheduleWorkoutReminder(false);

      await Future.delayed(const Duration(milliseconds: 100)); // 🔥 딜레이 추가
      if (!mounted) return;

      _navigateToDailyWorkoutCompleteNavigation(
        isTestMode: false,
        nextWeek: nextWeek,
        nextDay: 1,
      );
    }
  }

  Future<void> _showRetryWeekThreeDialog() async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: "3주차 재진행",
      message: "3주차에서 목표 개수를\n 달성하지 못한 기록이 있습니다.\n"
          "3주차를 다시 진행하시겠습니까?",
      okLabel: "네",
      cancelLabel: "아니요",
      isDestructiveAction: true,
    );

    if (!mounted) return;

    if (result == OkCancelResult.ok) {
      // 3주차 1일차부터 다시 시작
      await SharedPreferencesHelper.saveProgress(3, 1, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);
      scheduleWorkoutReminder(false);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      _navigateToDailyWorkoutCompleteNavigation(
          isTestMode: false, nextWeek: 3, nextDay: 1);
    } else {
      // 그냥 4주차로 넘어감
      const nextWeek = 4;
      await SharedPreferencesHelper.saveProgress(nextWeek, 1, widget.level);
      await SharedPreferencesHelper.saveIsTestMode(false);
      scheduleWorkoutReminder(false);

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      _navigateToDailyWorkoutCompleteNavigation(
          isTestMode: false, nextWeek: nextWeek, nextDay: 1);
    }
  }

  void _navigateToDailyWorkoutCompleteNavigation(
      {required bool isTestMode, int? nextWeek, int? nextDay}) {
    final totalPushups = userReps.reduce((a, b) => a + b);

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DailyWorkoutCompleteScreen(
          totalPushups: totalPushups,
          week: nextWeek ?? widget.week,
          day: nextDay ?? 1,
          level: widget.level,
          isTestMode: isTestMode,
        ),
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

  // Future<int> _getWorkoutCountForWeek(int week) async {
  //   final records = await SharedPreferencesHelper.getWorkoutRecords();
  //   int count = 0;

  //   for (var record in records) {
  //     if (record['week'] == week) {
  //       count++;
  //     }
  //   }
  //   return count;
  // }

  // void _showWorkoutCompleteNotification() async {
  //   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //       FlutterLocalNotificationsPlugin();

  //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //       AndroidNotificationDetails(
  //     'workout_complete_channel',
  //     'Workout Complete',
  //     channelDescription: 'Notification for workout completion',
  //     importance: Importance.max,
  //     priority: Priority.max,
  //     icon: 'transparent',
  //     color: AppColors.greenPrimary,
  //     // largeIcon: DrawableResourceAndroidBitmap('large_notification_icon'),
  //   );

  //   const NotificationDetails platformChannelSpecifics =
  //       NotificationDetails(android: androidPlatformChannelSpecifics);

  //   await flutterLocalNotificationsPlugin.show(
  //     1,
  //     '운동 완료',
  //     '오늘의 훈련을 완료했습니다!',
  //     platformChannelSpecifics,
  //   );

  //   if (await Vibration.hasVibrator() ?? false) {
  //     Vibration.vibrate(duration: 1000);
  //   }
  // }

  Future<void> _saveWorkoutRecord() async {
    final now = DateTime.now();
    final date = "${now.year}-${now.month}-${now.day}";

    await SharedPreferencesHelper.saveWorkoutRecord(
      date,
      sets, // 계획된 세트 목표
      userReps, // 사용자가 수행한 세트
      widget.week,
      widget.day,
      widget.level,
    );

    // 저장 후 홈 화면으로 이동
    // await Future.delayed(const Duration(milliseconds: 100));
    // if (!mounted) return;
    // Navigator.of(context).pushAndRemoveUntil(
    //   PageRouteBuilder(
    //     transitionDuration: const Duration(milliseconds: 500),
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         DailyWorkoutCompleteNavigation(
    //       initialWeek: widget.week,
    //       initialLevel: widget.level,
    //       isTestMode: false, // 테스트 모드 활성화
    //     ),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return SharedAxisTransition(
    //         animation: animation,
    //         secondaryAnimation: secondaryAnimation,
    //         transitionType: SharedAxisTransitionType.horizontal,
    //         child: child,
    //       );
    //     },
    //   ),
    //   (route) => false,
    // );
  }

  @override
  void dispose() {
    timer?.cancel();
    _scrollController.dispose();

    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double circleSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.45;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Week ${widget.week}, Day ${widget.day}",
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            /// ✅ 메인 UI
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenHeight * 0.01),
                  child: _buildSetCircles(),
                ),

                /// 🔹 **목표 푸시업 UI**
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: screenHeight * 0.1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _decreaseReps,
                            icon: Icon(Icons.remove, size: circleSize * 0.25),
                          ),
                          SizedBox(width: circleSize * 0.05),
                          GestureDetector(
                            onTap: _completeSet,
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Container(
                                  width: circleSize,
                                  height: circleSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _colorAnimation.value,
                                    border: Border.all(
                                      color: AppColors.yellowPrimary,
                                      width: circleSize * 0.03,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$currentTargetReps",
                                    style: TextStyle(
                                      fontSize: circleSize * 0.35,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: circleSize * 0.05),
                          IconButton(
                            onPressed: _increaseReps,
                            icon: Icon(Icons.add, size: circleSize * 0.25),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// 🔹 **버튼 (항상 화면 안에 보이도록 설정)**
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 16.0),
                //   child: ElevatedButton(
                //     onPressed: _completeSet,
                //     style: ElevatedButton.styleFrom(
                //       padding: EdgeInsets.symmetric(
                //           horizontal: screenWidth * 0.3,
                //           vertical: screenWidth * 0.04),
                //     ),
                //     child: Text(
                //       currentSet < sets.length - 1 ? "세트 완료" : "운동 완료",
                //       style: TextStyle(
                //           fontSize: dynamicFontSize * 1.2,
                //           fontWeight: FontWeight.bold),
                //     ),
                //   ),
                // ),

                /// 🔹 버튼과 하단 공간 추가
                // SizedBox(height: screenHeight * 0.1),
              ],
            ),

            /// 🔥 **휴식 중 팝업 (버튼 위에 겹치지 않도록 Positioned 사용)**
            Positioned(
              bottom: 20, // 버튼과 겹치지 않도록 설정
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300), // ✅ 등장 & 사라짐 속도
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3), // 아래에서 위로 올라옴
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: isResting
                    ? Container(
                        key:
                            const ValueKey("restingPopup"), // 애니메이션 동작을 위한 키 설정
                        margin:
                            EdgeInsets.symmetric(horizontal: dynamicFontSize),
                        padding: EdgeInsets.all(dynamicFontSize),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// ✅ 휴식 타이머
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${elapsedSeconds ~/ 60}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}",
                                      style: GoogleFonts.firaCode(
                                        fontSize: dynamicFontSize * 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Text(
                                      "휴식 중...",
                                      style: TextStyle(
                                        fontSize: dynamicFontSize * 1.1,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                /// ✅ 닫기 버튼 (클릭 시 애니메이션 적용)
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: dynamicFontSize * 1.5,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isResting = false; // ✅ 애니메이션 트리거
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            /// ✅ 프로그레스 바
                            LinearProgressIndicator(
                              borderRadius: BorderRadius.circular(3),
                              value: elapsedSeconds / restTime,
                              backgroundColor: Colors.grey[300],
                              color: elapsedSeconds <= restTime
                                  ? AppColors.redPrimary
                                  : AppColors.greenPrimary,
                              minHeight: 10,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
                    : null, // ✅ isResting == false일 때 자연스럽게 사라짐
              ),
            ),
          ],
        ),
      ),
    );
  }
}
