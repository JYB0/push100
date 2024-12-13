import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  // Save the current progress (week, day, level)
  static Future<void> saveProgress(int week, int day, String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentWeek', week);
    await prefs.setInt('currentDay', day);
    await prefs.setString('level', level);
  }

  // Get the current progress
  static Future<Map<String, dynamic>> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'currentWeek': prefs.getInt('currentWeek') ?? 1,
      'currentDay': prefs.getInt('currentDay') ?? 1,
      'level': prefs.getString('level') ?? '초급',
    };
  }

  // Save the initial test result
  static Future<void> saveInitialTest(int pushupCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('initialPushupCount', pushupCount);
  }

  // Get the initial test result
  static Future<int> getInitialPushupCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('initialPushupCount') ?? 0;
  }

  // Save the last test result
  static Future<void> saveTestResult(int week, int result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastTestWeek', week);
    await prefs.setInt('lastTestResult', result);
  }

  // Get the last test result
  static Future<Map<String, dynamic>> getTestResult() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'lastTestWeek': prefs.getInt('lastTestWeek') ?? 0,
      'lastTestResult': prefs.getInt('lastTestResult') ?? 0,
    };
  }

  // Update the total completed pushups
  static Future<void> updateTotalPushups(int count) async {
    final prefs = await SharedPreferences.getInstance();
    int totalPushups = prefs.getInt('totalPushupsCompleted') ?? 0;
    await prefs.setInt('totalPushupsCompleted', totalPushups + count);
  }

  // Get the total completed pushups
  static Future<int> getTotalPushups() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('totalPushupsCompleted') ?? 0;
  }

  // Clear all data (for debugging or resetting)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
