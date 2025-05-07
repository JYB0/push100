import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/bottom_navigation.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class DailyWorkoutCompleteScreen extends StatefulWidget {
  final int totalPushups; // ✅ 오늘 수행한 총 푸시업 개수
  final int week;
  final int day;
  final String level;
  final bool isTestMode;
  final int durationSeconds;

  const DailyWorkoutCompleteScreen({
    super.key,
    required this.totalPushups,
    required this.week,
    required this.day,
    required this.level,
    required this.isTestMode,
    required this.durationSeconds,
  });

  @override
  State<DailyWorkoutCompleteScreen> createState() =>
      _DailyWorkoutCompleteScreenState();
}

class _DailyWorkoutCompleteScreenState
    extends State<DailyWorkoutCompleteScreen> {
  ConfettiController? _confettiController;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _showButtons = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isDone = false;
  int progress = 0;
  late Timer _timer;

  bool isCapturing = false;

  final List<String> _motivationMessages = [
    "🔥 꾸준함이 강해지는 비결입니다!",
    "💪 오늘의 작은 성취가 큰 변화를 만듭니다!",
    "🎯 당신은 점점 강해지고 있습니다!",
    "🚀 목표에 한 걸음 더 가까워졌어요!",
    "🏆 멈추지 마세요! 계속 도전하세요!"
  ];

  @override
  void initState() {
    super.initState();
    _startConfettiEffect(); // 🎉 화면이 나타나면 자동 실행
    _playCompletionSound();
  }

  /// ✅ Confetti(폭죽) 효과 실행
  void _startConfettiEffect() {
    const colors = [
      AppColors.greenPrimary,
      AppColors.redPrimary,
      AppColors.yellowPrimary,
    ];

    int frameTime = 1000 ~/ 24;
    int total = 2 * 1000 ~/ frameTime; // 2초 동안 Confetti

    _timer = Timer.periodic(Duration(milliseconds: frameTime), (timer) {
      progress++;

      if (progress >= total) {
        timer.cancel();
        isDone = true;
        return;
      }
      if (_confettiController == null) {
        _confettiController = Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 3,
            angle: 90,
            spread: 60,
            x: 0.5,
            colors: colors,
          ),
          onFinished: (overlayEntry) {
            if (isDone) {
              overlayEntry.remove();
            }
          },
        );
      } else {
        _confettiController!.launch();
      }
    });
  }

  Future<void> _playCompletionSound() async {
    await _audioPlayer.play(AssetSource('sounds/finish.wav'));
  }

  @override
  void dispose() {
    _timer.cancel();
    _confettiController = null;
    _audioPlayer.dispose();
    super.dispose();
  }

  /// ✅ 홈 화면으로 이동
  void _navigateToHome() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable() &&
        ((widget.week == 2 && widget.day == 3) ||
            (widget.week == 4 && widget.day == 3))) {
      await inAppReview.requestReview();
    }

    _audioPlayer.stop();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              BottomNavigation(
            initialWeek: widget.week, // ✅ 기존 주차 유지
            initialLevel: widget.level, // ✅ 기존 레벨 유지
            isTestMode: widget.isTestMode, // ✅ 테스트 모드 유지
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal, // 가로 방향 이동
              child: child,
            );
          },
        ),
        (route) => false, // ✅ 기존 모든 화면 제거하고 홈 화면만 남김
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    final String motivationMessage =
        _motivationMessages[Random().nextInt(_motivationMessages.length)];

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: isCapturing
              ? Text(
                  "PUSH100",
                  style: GoogleFonts.bebasNeue(color: AppColors.redPrimary),
                )
              : const Text("🎉 운동 완료!"),
          backgroundColor: Colors.white,
          actions: isCapturing
              ? []
              : [
                  IconButton(
                      onPressed: _navigateToHome, icon: const Icon(Icons.close))
                ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),

                // 🎉 운동 완료 아이콘 (애니메이션 제거)
                Icon(
                  Icons.emoji_events,
                  color: AppColors.yellowPrimary,
                  size: screenWidth * 0.3,
                ),
                SizedBox(height: screenHeight * 0.02),

                // 🏆 메인 축하 메시지
                Text(
                  "${widget.totalPushups}개 푸시업을 수행했습니다!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dynamicFontSize * 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                // 💪 랜덤 동기부여 메시지
                Text(
                  motivationMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dynamicFontSize * 1.1,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer,
                        size: dynamicFontSize, color: Colors.grey),
                    Text(
                      widget.durationSeconds >= 60
                          ? "${widget.durationSeconds ~/ 60}분"
                          : " ${widget.durationSeconds % 60}초",
                      style: TextStyle(
                        fontSize: dynamicFontSize,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.25),

                if (_showButtons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            "💪 Push100 앱으로 함께 푸쉬업 100개 도전해봐요!\n 저는 지금 ${widget.totalPushups}개 했어요!\n📲 iOS 다운로드: https://apps.apple.com/kr/app/push100/id6742874163\n📲 안드로이드 다운로드: https://play.google.com/store/apps/details?id=com.morebetterlifeapp.push100",
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redPrimary, // ✅ 메인 색깔 적용
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.2,
                              vertical: dynamicFontSize * 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.ios_share,
                          color: Colors.white,
                          size: dynamicFontSize * 1.2,
                        ),
                        label: Text(
                          '공유하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: dynamicFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _showButtons = false;
                            isCapturing = true;
                          });

                          await Future.delayed(
                              const Duration(milliseconds: 300)); // 버튼 사라질 시간

                          final image = await _screenshotController.capture();
                          if (image != null) {
                            // ✅ 저장 권한 요청
                            PermissionStatus status;
                            if (Platform.isAndroid) {
                              status = await Permission.photos.request();
                            } else {
                              status = await Permission.storage.request();
                            }

                            if (status.isGranted) {
                              await ImageGallerySaverPlus.saveImage(
                                image,
                                quality: 100,
                                name:
                                    'push100_${DateTime.now().millisecondsSinceEpoch}',
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("📸 갤러리에 저장되었어요!")),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("❗ 저장 권한이 필요합니다.")),
                                );
                              }
                            }
                          }

                          setState(() {
                            _showButtons = true;
                            isCapturing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: dynamicFontSize * 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: dynamicFontSize * 1.3),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
