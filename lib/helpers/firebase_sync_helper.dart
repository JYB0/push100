import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';

/// ✅ SharedPreferences → Firestore 업로드 (백업: 서버 데이터를 덮어씀)
Future<void> syncLocalDataToFirebase(User user) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  // 1. SharedPreferences 데이터 가져오기
  final initialCount = await SharedPreferencesHelper.getInitialPushupCount();
  final progress = await SharedPreferencesHelper.getProgress();
  final isTestMode = await SharedPreferencesHelper.getIsTestMode();
  final workoutRecords = await SharedPreferencesHelper.getWorkoutRecords();

  // 2. 사용자 프로필 정보 저장
  await userDoc.set({
    'initialPushupCount': initialCount,
    'currentWeek': progress['currentWeek'],
    'currentDay': progress['currentDay'],
    'level': progress['level'],
    'isTestMode': isTestMode,
    'records': workoutRecords,
    'lastUpdated': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // // 3. 서버 운동 기록 전체 삭제 후 로컬 데이터 업로드
  // final recordsRef = userDoc.collection('workoutRecords');
  // final snapshot = await recordsRef.get();
  // for (final doc in snapshot.docs) {
  //   await doc.reference.delete();
  // }

  // for (final record in workoutRecords) {
  //   await recordsRef.add({
  //     'date': record['date'],
  //     'week': record['week'],
  //     'day': record['day'],
  //     'level': record['level'],
  //     'plannedReps': record['plannedReps'],
  //     'userReps': record['userReps'],
  //     'durationSeconds': record['durationSeconds'] ?? 0,
  //   });
  // }
}

/// ✅ Firestore → SharedPreferences 복원 (복원: 중복 제외하고 병합)
Future<void> restoreDataFromFirebase(User user) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snapshot = await userDoc.get();

  if (!snapshot.exists) return;

  final data = snapshot.data()!;
  final int initialPushupCount =
      (data['initialPushupCount'] as num?)?.toInt() ?? 0;
  final int currentWeek = (data['currentWeek'] as num?)?.toInt() ?? 1;
  final int currentDay = (data['currentDay'] as num?)?.toInt() ?? 1;
  final String level = data['level'] as String? ?? '초급';
  final bool isTestMode = data['isTestMode'] as bool? ?? false;

  await SharedPreferencesHelper.saveInitialTest(initialPushupCount);
  await SharedPreferencesHelper.saveProgress(currentWeek, currentDay, level);
  await SharedPreferencesHelper.saveIsTestMode(isTestMode);

  // // 1. 서버에서 가져온 운동 기록 가져오기
  // final recordsSnapshot = await userDoc.collection('workoutRecords').get();
  // final serverRecords = recordsSnapshot.docs.map((doc) => doc.data()).toList();

  // // 2. 로컬 기록 불러오기 (중복 체크를 위해)
  // final localRecords = await SharedPreferencesHelper.getWorkoutRecords();

  // for (final serverRecord in serverRecords) {
  //   final isDuplicate = localRecords.any((local) =>
  //       local['date'] == serverRecord['date'] &&
  //       local['week'] == serverRecord['week'] &&
  //       local['day'] == serverRecord['day'] &&
  //       local['level'] == serverRecord['level']);

  //   if (!isDuplicate) {
  //     await SharedPreferencesHelper.saveWorkoutRecord(
  //       serverRecord['date'],
  //       List<int>.from(serverRecord['plannedReps']),
  //       List<int>.from(serverRecord['userReps']),
  //       serverRecord['week'],
  //       serverRecord['day'],
  //       serverRecord['level'],
  //       serverRecord['durationSeconds'] ?? 0, // ✅ 추가
  //     );
  //   }
  // }

  final serverRecords = (data['records'] as List<dynamic>? ?? [])
      .whereType<Map>()
      .map((record) => Map<String, dynamic>.from(record))
      .toList();
  final localRecords = await SharedPreferencesHelper.getWorkoutRecords();

  for (final record in serverRecords) {
    final isDuplicate = localRecords.any((local) =>
        local['date'] == record['date'] &&
        local['week'] == record['week'] &&
        local['day'] == record['day'] &&
        local['level'] == record['level'] &&
        local['durationSeconds'] == record['durationSeconds']);

    if (!isDuplicate) {
      final plannedReps = (record['plannedReps'] as List<dynamic>? ?? [])
          .map((rep) => (rep as num).toInt())
          .toList();
      final userReps = (record['userReps'] as List<dynamic>? ?? [])
          .map((rep) => (rep as num).toInt())
          .toList();

      if (record['date'] == null ||
          plannedReps.isEmpty ||
          userReps.isEmpty ||
          record['week'] == null ||
          record['day'] == null ||
          record['level'] == null) {
        continue;
      }

      await SharedPreferencesHelper.saveWorkoutRecord(
        record['date'] as String,
        plannedReps,
        userReps,
        (record['week'] as num).toInt(),
        (record['day'] as num).toInt(),
        record['level'] as String,
        (record['durationSeconds'] as num?)?.toInt() ?? 0,
      );
    }
  }
}
