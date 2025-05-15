import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:push100/helpers/firebase_sync_helper.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/main.dart';
import 'package:push100/screens/bottom_navigation.dart';
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
  bool _isLoading = false;
  Duration syncCooldown = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
    _loadLastRestoreTime();
  }

  Future<({bool canSync, Duration? remaining})> getSyncCooldownStatus(
      String key) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(key);

    if (lastSyncString == null) return (canSync: true, remaining: null);

    final lastSync = DateTime.tryParse(lastSyncString);
    if (lastSync == null) return (canSync: true, remaining: null);

    final elapsed = DateTime.now().difference(lastSync);
    if (elapsed > syncCooldown) return (canSync: true, remaining: null);

    final remaining = syncCooldown - elapsed;
    return (canSync: false, remaining: remaining);
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
    setState(() => _isLoading = true);

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

        final progress = await SharedPreferencesHelper.getProgress();
        final isTestMode = await SharedPreferencesHelper.getIsTestMode();

        // ✅ 홈 화면(BottomNavigation)으로 이동하며 갱신
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  BottomNavigation(
                initialWeek: progress['currentWeek'],
                initialLevel: progress['level'],
                isTestMode: isTestMode,
              ),
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
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 복원 중 오류 발생: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
    setState(() => _isLoading = true);

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
    } finally {
      setState(() => _isLoading = false);
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
      body: Stack(
        children: [
          SafeArea(
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
                  Text(
                    '☁️ 로그인된 상태에서는\n운동 기록이 자동으로 동기화됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: dynamicFontSize * 0.9,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_lastBackupTimeFormatted != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '마지막 수동 백업 시간: $_lastBackupTimeFormatted',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: dynamicFontSize * 0.8, color: Colors.grey),
                    ),
                  ],
                  if (_lastRestoreTimeFormatted != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '마지막 수동 복원 시간: $_lastRestoreTimeFormatted',
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
                      if (user == null) return;

                      final status =
                          await getSyncCooldownStatus('lastBackupTime');
                      if (!status.canSync) {
                        final seconds = status.remaining!.inSeconds;
                        final message = seconds <= 60
                            ? '⏱ 백업은 약 $seconds초 후에 다시 시도해주세요.'
                            : '⏱ 백업은 약 ${status.remaining!.inMinutes + 1}분 후에 다시 시도해주세요.';
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                        return; // ✅ 여기 안으로 들어가야 함!
                      }

                      if (context.mounted) {
                        final result = await showOkCancelAlertDialog(
                          context: context,
                          title: '서버로 데이터 백업',
                          message:
                              '이 기기의 운동 기록과 설정을\n서버에 저장합니다.\n\n※ 로그인된 사용자는\n운동 완료 시\n자동 백업됩니다.\n\n수동으로 백업하시겠습니까?',
                          okLabel: '백업하기',
                          cancelLabel: '취소',
                          isDestructiveAction: true,
                        );

                        if (result == OkCancelResult.ok) {
                          // ⏬ 쿨다운이 끝났을 경우만 실행
                          await _handleBackup(user);
                        }
                      }
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
                        if (user == null) return;

                        final status =
                            await getSyncCooldownStatus('lastRestoreTime');
                        if (!status.canSync) {
                          final seconds = status.remaining!.inSeconds;
                          final message = seconds <= 60
                              ? '⏱ 복원은 약 $seconds초 후에 다시 시도해주세요.'
                              : '⏱ 복원은 약 ${status.remaining!.inMinutes + 1}분 후에 다시 시도해주세요.';
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          final result = await showOkCancelAlertDialog(
                            context: context,
                            title: '서버에서 데이터 복원',
                            message:
                                '서버에 저장된 데이터를\n이 기기로 가져옵니다.\n\n※ 로그인된 상태에서는\n앱 실행시 자동으로 동기화됩니다.\n\n수동으로 복원하시겠습니까?',
                            okLabel: '복원하기',
                            cancelLabel: '취소',
                            isDestructiveAction: true,
                          );

                          if (result == OkCancelResult.ok) {
                            await _handleRestore(user);
                          }
                        }
                      }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: const Color(0x4D000000),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.redPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
