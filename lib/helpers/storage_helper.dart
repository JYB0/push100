import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static Future<void> saveInitialData(
      int pushupCount, int week, String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pushupCount', pushupCount);
    await prefs.setInt('week', week);
    await prefs.setString('level', level);
  }

  static Future<Map<String, dynamic>> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'pushupCount': prefs.getInt('pushupCount') ?? 0,
      'week': prefs.getInt('week') ?? 1,
      'level': prefs.getString('level') ?? '초급',
    };
  }
}
