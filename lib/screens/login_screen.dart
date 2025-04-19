import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:push100/helpers/auth_helper.dart';
// import 'package:push100/helpers/firebase_sync_helper.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/data_sync_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:push100/widgets/google_sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleLogin(BuildContext context) async {
    try {
      UserCredential? userCredential;

      if (Platform.isIOS) {
        userCredential = await AuthHelper.signInWithApple();
      } else {
        userCredential = await AuthHelper.signInWithGoogle();
      }

      if (userCredential != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 로그인 성공!')),
          );
        }

        // ✅ 로그인만 처리하고 이전 화면으로 돌아감
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const DataSyncScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  child: child,
                );
              },
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ 로그인 취소 또는 실패')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 중 오류 발생!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);
    double dynamicButtonHeight = 48 * (screenWidth / 400).clamp(0.9, 1.2);
    double dynamicButtonFontSize = 16 * (screenWidth / 400).clamp(0.9, 1.2);

    return Scaffold(
      appBar: AppBar(),
      body: Align(
        alignment: const Alignment(0, -0.4), // -1.0은 맨 위, 0은 가운데, 1.0은 맨 아래
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Push100',
                  style: GoogleFonts.bebasNeue(
                    fontSize: dynamicFontSize * 2.4,
                    fontWeight: FontWeight.bold,
                    color: AppColors.redPrimary,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Text(
                  '데이터를 연동하고 기기를 바꿔도\n운동 기록을 안전하게 보관하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: dynamicFontSize * 1.1, color: Colors.grey),
                ),
                SizedBox(height: screenHeight * 0.3),
                SizedBox(
                  width: Platform.isIOS ? 320 : screenWidth * 0.7,
                  child: Platform.isIOS
                      ? SignInWithAppleButton(
                          onPressed: () => _handleLogin(context),
                          style: SignInWithAppleButtonStyle.black,
                          borderRadius: BorderRadius.circular(8),
                          height: dynamicButtonHeight,
                        )
                      : GoogleSignInButton(
                          onPressed: () => _handleLogin(context),
                          height: dynamicButtonHeight,
                          fontSize: dynamicButtonFontSize,
                          width: 320,
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  '계속 진행 시 개인정보 처리방침에 동의하게 됩니다.',
                  style: TextStyle(
                      fontSize: dynamicFontSize * 0.8, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
