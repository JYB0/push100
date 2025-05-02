import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:push100/helpers/schedule_reminder_helper.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettingScreen extends StatefulWidget {
  const ReminderSettingScreen({super.key});

  @override
  State<ReminderSettingScreen> createState() => _ReminderSettingScreenState();
}

class _ReminderSettingScreenState extends State<ReminderSettingScreen> {
  Time _selectedTime = Time(hour: 18, minute: 0);
  int _intervalDays = 2;
  bool _reminderEnabled = true;
  bool _hasCustomTime = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour') ?? 18;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    final interval = prefs.getInt('reminder_interval') ?? 2;
    final enabled = prefs.getBool('reminder_enabled') ?? true;

    setState(() {
      _selectedTime = Time(hour: hour, minute: minute); // ✅ 수정된 부분
      _intervalDays = interval;
      _reminderEnabled = enabled;
      _hasCustomTime = prefs.containsKey('reminder_hour') &&
          prefs.containsKey('reminder_minute');
    });
  }

  Future<void> _showIntervalPicker() async {
    final result = await showConfirmationDialog<String>(
      context: context,
      title: '알림 주기를 선택해주세요',
      actions: [
        const AlertDialogAction(label: '매일', key: '1'),
        const AlertDialogAction(label: '2일(권장)', key: '2'),
        const AlertDialogAction(label: '3일', key: '3'),
      ],
    );

    if (result != null) {
      setState(() {
        _intervalDays = int.parse(result);
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_hour', _selectedTime.hour);
      await prefs.setInt('reminder_minute', _selectedTime.minute);
      await prefs.setInt('reminder_interval', _intervalDays);
      await prefs.setBool('reminder_enabled', _reminderEnabled);

      final isTestMode = await SharedPreferencesHelper.getIsTestMode();

      if (_reminderEnabled) {
        scheduleWorkoutReminder(isTestMode); // ✅ 알림 예약
      } else {
        await flutterLocalNotificationsPlugin.cancel(2000); // ✅ 알림 취소
      }

      if (mounted) {
        Navigator.of(context).pop(); // ✅ 설정 저장 후 뒤로가기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림 설정이 저장되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(
                '운동 알림 받기',
                style: TextStyle(fontSize: dynamicFontSize),
              ),
              subtitle: Text(
                _reminderEnabled ? '설정된 시간에 알림을 받습니다' : '설정된 시간에 알림을 받지 않습니다',
                style: TextStyle(
                  fontSize: dynamicFontSize * 0.8,
                ),
              ),
              trailing: Icon(
                _reminderEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _reminderEnabled ? AppColors.redPrimary : Colors.grey,
                size: dynamicFontSize * 1.2,
              ),
              onTap: () {
                setState(() {
                  _reminderEnabled = !_reminderEnabled;
                });
              },
            ),
            ListTile(
              title: Text('알림 시간', style: TextStyle(fontSize: dynamicFontSize)),
              subtitle: Text(
                _hasCustomTime ? _selectedTime.format(context) : '아직 설정되지 않았어요',
                style: TextStyle(fontSize: dynamicFontSize * 0.8),
              ),
              trailing: Icon(
                Icons.access_time,
                size: dynamicFontSize * 1.2,
              ),
              onTap: () {
                Navigator.of(context).push(
                  showPicker(
                    context: context,
                    value: _selectedTime,
                    onChange: (newTime) {
                      setState(() => _selectedTime = newTime);
                    },
                    is24HrFormat: false,
                    accentColor: AppColors.redPrimary,
                    iosStylePicker: true,
                    amLabel: '오전',
                    pmLabel: '오후',
                    hourLabel: '시',
                    minuteLabel: '분',
                    cancelText: '취소',
                    okText: '확인',
                  ),
                );
              },
            ),
            ListTile(
              title: Text('알림 주기', style: TextStyle(fontSize: dynamicFontSize)),
              subtitle: Text(
                _intervalDays == 1 ? '매일' : '$_intervalDays일',
                style: TextStyle(fontSize: dynamicFontSize * 0.8),
              ),
              trailing:
                  Icon(Icons.arrow_drop_down, size: dynamicFontSize * 1.2),
              onTap: _showIntervalPicker,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text('저장', style: TextStyle(fontSize: dynamicFontSize)),
            ),
          ],
        ),
      ),
    );
  }
}
