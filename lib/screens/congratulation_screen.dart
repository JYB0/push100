import 'dart:async';
import 'dart:io';
import 'package:animations/animations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/bottom_navigation.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({super.key});

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  ConfettiController? _controller1;
  ConfettiController? _controller2;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isDone = false;
  int progress = 0;
  late Timer _timer;

  final ScreenshotController _screenshotController = ScreenshotController();
  bool _showButtons = true;
  bool isCapturing = false;

  @override
  void initState() {
    super.initState();
    _startConfettiEffect(); // 🎉 화면이 나타나면 자동 실행
    _playCompletionSound();
  }

  /// ✅ Confetti 효과 시작
  void _startConfettiEffect() {
    const colors = [
      AppColors.greenPrimary,
      AppColors.redPrimary,
      AppColors.yellowPrimary
    ];

    int frameTime = 1000 ~/ 24;
    int total = 2 * 1000 ~/ frameTime;

    _timer = Timer.periodic(Duration(milliseconds: frameTime), (timer) {
      progress++;

      if (progress >= total) {
        timer.cancel();
        isDone = true;
        return;
      }
      if (_controller1 == null) {
        _controller1 = Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 3,
            angle: 60,
            spread: 55,
            x: 0,
            colors: colors,
          ),
          onFinished: (overlayEntry) {
            if (isDone) {
              overlayEntry.remove();
            }
          },
        );
      } else {
        _controller1!.launch();
      }

      if (_controller2 == null) {
        _controller2 = Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 2,
            angle: 120,
            spread: 55,
            x: 1,
            colors: colors,
          ),
          onFinished: (overlayEntry) {
            if (isDone) {
              overlayEntry.remove();
            }
          },
        );
      } else {
        _controller2!.launch();
      }
    });
  }

  Future<void> _playCompletionSound() async {
    await _audioPlayer.play(AssetSource('sounds/finish.wav'));
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller1 = null; // ✅ null로 설정하여 메모리 해제
    _controller2 = null; // ✅ null로 설정하여 메모리 해제
    _audioPlayer.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    _audioPlayer.stop();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500), // 애니메이션 지속 시간
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BottomNavigation(
          initialWeek: 7, // ✅ 7주차로 설정하여 홈 화면에서 nextPlan 안 보이게
          initialLevel: "초보", // ✅ 기존 레벨 유지
          isTestMode: false, // ✅ 테스트 모드 해제
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
      (route) => false, // ✅ 기존 모든 화면 제거하고 `BottomNavigation`만 남김
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

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
              : const Text("🎉 축하합니다!"),
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
                  Icons.military_tech,
                  color: AppColors.yellowPrimary,
                  size: screenWidth * 0.3,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "푸시업 챌린지를 \n성공했습니다!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: dynamicFontSize * 2,
                      fontWeight: FontWeight.bold),
                ),
                // SizedBox(height: screenHeight * 0.01),
                // ElevatedButton(
                //   onPressed: _navigateToHome,
                //   child: const Text("홈으로 가기"),
                // ),
                SizedBox(height: screenHeight * 0.25),
                if (_showButtons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            "💪 Push100 앱으로 함께 푸쉬업 100개 도전해봐요!\n 저는 푸쉬업 챌린지 성공했어요!\n📲 iOS 다운로드: https://apps.apple.com/kr/app/push100/id6742874163\n📲 안드로이드 다운로드: https://play.google.com/store/apps/details?id=com.morebetterlifeapp.push100",
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
