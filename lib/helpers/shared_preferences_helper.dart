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

  static Future<void> saveIsTestMode(bool isTestMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTestMode', isTestMode);
  }

  static Future<bool> getIsTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isTestMode') ?? false; // 기본값 false
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

  // Get all workout records
  static Future<List<Map<String, dynamic>>> getWorkoutRecords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList('workoutRecords') ?? [];

    // return records.map((record) {
    //   final parts = record.split(':');
    //   return {
    //     'date': parts[0], // 날짜
    //     'week': int.parse(parts[1]),
    //     'day': int.parse(parts[2]),
    //     'level': parts[3],
    //     'plannedReps': parts[4].split(',').map(int.parse).toList(), // 주어진 세트
    //     'userReps': parts[5].split(',').map(int.parse).toList(), // 사용자가 수행한 세트
    //   };
    // }).toList();

    List<Map<String, dynamic>> parsedRecords = records.map((record) {
      final parts = record.split(':');
      return {
        'date': parts[0],
        'week': int.parse(parts[1]),
        'day': int.parse(parts[2]),
        'level': parts[3],
        'plannedReps': parts[4].split(',').map(int.parse).toList(),
        'userReps': parts[5].split(',').map(int.parse).toList(),
        'durationSeconds':
            parts.length > 6 ? int.tryParse(parts[6]) ?? 0 : 0, // 🔥 여기가 핵심
      };
    }).toList();

    parsedRecords.sort((a, b) {
      final dateA = DateTime.tryParse(a['date']) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['date']) ?? DateTime(2000);
      final compareDate = dateB.compareTo(dateA);
      if (compareDate != 0) return compareDate;

      final weekA = a['week'] as int;
      final weekB = b['week'] as int;
      final compareWeek = weekB.compareTo(weekA);
      if (compareWeek != 0) return compareWeek;

      final dayA = a['day'] as int;
      final dayB = b['day'] as int;
      return dayB.compareTo(dayA); // 마지막으로 day 기준 비교
    });

    return parsedRecords;
  }

  static Future<void> setDateFixed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDateFixed', true);
  }

  static Future<bool> getDateFixed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDateFixed') ?? false;
  }

  static Future<void> fixStoredDates() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList('workoutRecords') ?? [];

    List<String> fixedRecords = records.map((record) {
      final parts = record.split(':');
      String date = parts[0];

      // 날짜 포맷 수정 (yyyy-MM-dd 형식으로 맞추기)
      List<String> dateParts = date.split('-');
      if (dateParts.length == 3) {
        String year = dateParts[0];
        String month = dateParts[1].padLeft(2, '0');
        String day = dateParts[2].padLeft(2, '0');
        date = '$year-$month-$day';
      }

      parts[0] = date;
      return parts.join(':');
    }).toList();

    await prefs.setStringList('workoutRecords', fixedRecords);
  }

// Save workout record (date, completed sets, reps, user reps)
  static Future<void> saveWorkoutRecord(
    String date,
    List<int> plannedReps,
    List<int> userReps,
    int week,
    int day,
    String level,
    int durationSeconds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList('workoutRecords') ?? [];

    final dateParts = date.split('-');
    final year = dateParts[0];
    final month = dateParts[1].padLeft(2, '0');
    final dayString = dateParts[2].padLeft(2, '0');
    final fixedDate = '$year-$month-$dayString';

    // Save as a single string (e.g., "2024-12-27:3,5,3,5,5:3,5,3,5,1")
    final record =
        '$fixedDate:$week:$day:$level:${plannedReps.join(",")}:${userReps.join(",")}:$durationSeconds';
    records.add(record);
    await prefs.setStringList('workoutRecords', records);
  }

  // Delete a workout record by index
  static Future<void> deleteWorkoutRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList('workoutRecords') ?? [];

    if (index >= 0 && index < records.length) {
      records.removeAt(index); // 해당 인덱스 기록 삭제
      await prefs.setStringList('workoutRecords', records);
    }
  }

  // 튜토리얼(예: 세트 완료 안내)을 봤는지 여부 저장
  static Future<void> setWorkoutTutorialSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('workoutTutorialSeen', seen);
  }

// 튜토리얼을 봤는지 여부 불러오기
  static Future<bool> getWorkoutTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('workoutTutorialSeen') ?? false; // 기본값: 안 봄
  }
}
