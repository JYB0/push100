import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';

/// ✅ SharedPreferences → Firestore 업로드
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
  }, SetOptions(merge: true));

  // 3. 운동 기록 저장 (기존 기록 모두 삭제 후 다시 저장)
  final recordsRef = userDoc.collection('workoutRecords');
  final snapshot = await recordsRef.get();
  for (final doc in snapshot.docs) {
    await doc.reference.delete(); // 중복 저장 방지
  }

  for (final record in workoutRecords) {
    await recordsRef.add({
      'date': record['date'],
      'week': record['week'],
      'day': record['day'],
      'level': record['level'],
      'plannedReps': record['plannedReps'],
      'userReps': record['userReps'],
    });
  }
}

/// ✅ Firestore → SharedPreferences 복원
Future<void> restoreDataFromFirebase(User user) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snapshot = await userDoc.get();

  if (snapshot.exists) {
    final data = snapshot.data()!;
    await SharedPreferencesHelper.saveInitialTest(data['initialPushupCount']);
    await SharedPreferencesHelper.saveProgress(
      data['currentWeek'],
      data['currentDay'],
      data['level'],
    );
    await SharedPreferencesHelper.saveIsTestMode(data['isTestMode'] ?? false);
  }

  // 운동 기록 복원
  final recordsSnapshot = await userDoc.collection('workoutRecords').get();
  for (final doc in recordsSnapshot.docs) {
    final record = doc.data();
    await SharedPreferencesHelper.saveWorkoutRecord(
      record['date'],
      List<int>.from(record['plannedReps']),
      List<int>.from(record['userReps']),
      record['week'],
      record['day'],
      record['level'],
    );
  }
}
