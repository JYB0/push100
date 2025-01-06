import 'package:push100/models/workout_plan.dart';

// 특정 단계와 주차의 모든 운동 플랜 가져오기
List<WorkoutPlan> getPlansByLevelAndWeek(String level, int week) {
  return workoutPlans
      .where((plan) => plan.level == level && plan.week == week)
      .toList();
}

// 특정 단계, 주차, 날짜의 운동 플랜 가져오기
WorkoutPlan? getPlanByLevelWeekAndDay(String level, int week, int day) {
  return workoutPlans.firstWhere(
    (plan) => plan.level == level && plan.week == week && plan.day == day,
    orElse: () => WorkoutPlan(
      week: 1,
      day: 1,
      level: "초급",
      sets: [],
      restTime: 0,
    ), // 기본값 반환
  );
}

Map<String, dynamic> determineInitialPlan(int pushupCount) {
  if (pushupCount <= 5) {
    return {'week': 1, 'level': '초급'};
  } else if (pushupCount <= 10) {
    return {'week': 1, 'level': '중급'};
  } else if (pushupCount <= 20) {
    return {'week': 1, 'level': '고급'};
  } else if (pushupCount <= 25) {
    return {'week': 3, 'level': '중급'};
  } else {
    return {'week': 3, 'level': '고급'};
  }
}

Map<String, dynamic> determineUpdatedPlan(
    int week, int pushupCount, String currentLevel) {
  if (week == 2) {
    // 2주차 테스트 결과
    if (pushupCount < 16) {
      return {'week': 2, 'level': currentLevel}; // 2주차 재진행
    } else if (pushupCount <= 20) {
      return {'week': 3, 'level': '초급'}; // 3주차 초급
    } else if (pushupCount <= 25) {
      return {'week': 3, 'level': '중급'}; // 3주차 중급
    } else {
      return {'week': 3, 'level': '고급'}; // 3주차 고급
    }
  } else if (week == 4) {
    // 4주차 테스트 결과
    if (pushupCount < 31) {
      return {'week': 4, 'level': currentLevel}; // 4주차 재진행
    } else if (pushupCount <= 35) {
      return {'week': 5, 'level': '초급'}; // 5주차 초급
    } else if (pushupCount <= 40) {
      return {'week': 5, 'level': '중급'}; // 5주차 중급
    } else {
      return {'week': 5, 'level': '고급'}; // 5주차 고급
    }
  } else if (week == 5) {
    // 5주차 테스트 결과
    if (pushupCount < 46) {
      return {'week': 5, 'level': currentLevel}; // 5주차 재진행
    } else if (pushupCount <= 50) {
      return {'week': 6, 'level': '초급'}; // 6주차 초급
    } else if (pushupCount <= 60) {
      return {'week': 6, 'level': '중급'}; // 6주차 중급
    } else {
      return {'week': 6, 'level': '고급'}; // 6주차 고급
    }
  } else {
    // 기타 주차 (기본값)
    return {'week': week + 1, 'level': '초급'};
  }
}

// 특정 단계와 주차의 총 푸시업 개수 계산
int calculateTotalPushupsForLevelAndWeek(String level, int week) {
  final weekPlans = getPlansByLevelAndWeek(level, week);
  return weekPlans.fold(
    0,
    (total, plan) => total + plan.sets.reduce((a, b) => a + b),
  );
}

// 전체 프로그램의 총 푸시업 개수 계산 (단계별)
int calculateTotalPushupsForLevel(String level) {
  final plans = workoutPlans.where((plan) => plan.level == level).toList();
  return plans.fold(
    0,
    (total, plan) => total + plan.sets.reduce((a, b) => a + b),
  );
}

// 특정 단계와 주차의 총 휴식 시간 계산
int calculateTotalRestTimeForLevelAndWeek(String level, int week) {
  final weekPlans = getPlansByLevelAndWeek(level, week);
  return weekPlans.fold(
    0,
    (total, plan) => total + (plan.restTime * plan.sets.length),
  );
}
