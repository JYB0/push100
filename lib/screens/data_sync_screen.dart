import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:push100/helpers/firebase_sync_helper.dart';
import 'package:push100/screens/setting_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSyncScreen extends StatefulWidget {
  const DataSyncScreen({super.key});

  @override
  State<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends State<DataSyncScreen> {
  String? _lastBackupTimeFormatted;
  String? _lastRestoreTimeFormatted;

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
    _loadLastRestoreTime();
  }

  Future<void> _loadLastRestoreTime() async {
    final prefs = await SharedPreferences.getInstance();
    final restoreString = prefs.getString('lastRestoreTime');
    if (restoreString != null) {
      final restoreTime = DateTime.tryParse(restoreString);
      if (restoreTime != null) {
        final formatted = DateFormat('yyyy-MM-dd HH:mm').format(restoreTime);
        setState(() {
          _lastRestoreTimeFormatted = formatted;
        });
      }
    }
  }

  Future<void> _handleRestore(User user) async {
    try {
      await restoreDataFromFirebase(user);
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('lastRestoreTime', now.toIso8601String());

      setState(() {
        _lastRestoreTimeFormatted = DateFormat('yyyy-MM-dd HH:mm').format(now);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 복원이 완료되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 복원 중 오류 발생: $e')),
        );
      }
    }
  }

  Future<void> _loadLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupString = prefs.getString('lastBackupTime');

    if (lastBackupString != null) {
      final lastBackup = DateTime.tryParse(lastBackupString);
      if (lastBackup != null) {
        final formatted = DateFormat('yyyy-MM-dd HH:mm').format(lastBackup);
        setState(() {
          _lastBackupTimeFormatted = formatted;
        });
      }
    }
  }

  Future<void> _handleBackup(User user) async {
    try {
      await syncLocalDataToFirebase(user); // 여기가 성공해야 아래 로직 실행

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('lastBackupTime', now.toIso8601String());

      setState(() {
        _lastBackupTimeFormatted = DateFormat('yyyy-MM-dd HH:mm').format(now);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 백업이 완료되었습니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 백업 중 오류 발생: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndSignOut(BuildContext context) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      title: '로그아웃 하시겠어요?',
      message: '연결된 계정에서 로그아웃됩니다.',
      okLabel: '로그아웃',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                SettingScreen(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('👋 로그아웃 되었습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터 연동'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => _confirmAndSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔝 현재 계정 (상단)
              Text(
                '현재 계정: ${user?.email ?? '익명 사용자'}',
                style: TextStyle(
                    fontSize: dynamicFontSize * 0.8, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_lastBackupTimeFormatted != null) ...[
                const SizedBox(height: 8),
                Text(
                  '마지막 백업: $_lastBackupTimeFormatted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: dynamicFontSize * 0.8, color: Colors.grey),
                ),
              ],
              if (_lastRestoreTimeFormatted != null) ...[
                const SizedBox(height: 4),
                Text(
                  '마지막 복원: $_lastRestoreTimeFormatted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: dynamicFontSize * 0.8, color: Colors.grey),
                ),
              ],

              const Spacer(), // 👇 아래쪽으로 밀어냄

              // 🔽 하단 안내 및 버튼
              Text(
                '원하는 작업을 선택하세요:',
                style: TextStyle(
                    fontSize: dynamicFontSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.upload,
                  color: Colors.white,
                  size: dynamicFontSize,
                ),
                label: Text(
                  '서버로 데이터 내보내기 (백업)',
                  style: TextStyle(fontSize: dynamicFontSize),
                ),
                onPressed: () async {
                  if (user != null) await _handleBackup(user);
                  // await syncLocalDataToFirebase(user!);
                  // if (context.mounted) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(content: Text('✅ 백업이 완료되었습니다!')),
                  //   );
                  // }
                },
              ),
              SizedBox(height: dynamicFontSize),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.download,
                  color: Colors.white,
                  size: dynamicFontSize,
                ),
                label: Text(
                  '서버에서 데이터 가져오기 (복원)',
                  style: TextStyle(
                    fontSize: dynamicFontSize,
                  ),
                ),
                onPressed: () async {
                  if (user != null) await _handleRestore(user);
                  // await restoreDataFromFirebase(user!);
                  // if (context.mounted) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(content: Text('✅ 복원이 완료되었습니다!')),
                  //   );
                  // }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
