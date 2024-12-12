class WorkoutPlan {
  final int week;
  final int day;
  final String level; // 단계: 초급, 중급, 고급
  final List<int> sets; // 세트별 푸시업 개수
  final int restTime; // 휴식 시간 (초 단위)

  WorkoutPlan({
    required this.week,
    required this.day,
    required this.level,
    required this.sets,
    required this.restTime,
  });
}

// 운동 플랜 데이터
final List<WorkoutPlan> workoutPlans = [
  // Week 1 - 초급
  WorkoutPlan(
      week: 1, day: 1, level: "초급", sets: [2, 3, 2, 2, 3], restTime: 60),
  WorkoutPlan(
      week: 1, day: 2, level: "초급", sets: [3, 4, 2, 3, 4], restTime: 60),
  WorkoutPlan(
      week: 1, day: 3, level: "초급", sets: [4, 5, 4, 4, 5], restTime: 60),

  // Week 1 - 중급
  WorkoutPlan(
      week: 1, day: 1, level: "중급", sets: [6, 6, 4, 4, 5], restTime: 60),
  WorkoutPlan(
      week: 1, day: 2, level: "중급", sets: [6, 8, 6, 6, 7], restTime: 60),
  WorkoutPlan(
      week: 1, day: 3, level: "중급", sets: [8, 10, 7, 7, 10], restTime: 60),

  // Week 1 - 고급
  WorkoutPlan(
      week: 1, day: 1, level: "고급", sets: [10, 12, 7, 7, 9], restTime: 60),
  WorkoutPlan(
      week: 1, day: 2, level: "고급", sets: [10, 12, 8, 8, 12], restTime: 60),
  WorkoutPlan(
      week: 1, day: 3, level: "고급", sets: [11, 15, 9, 9, 13], restTime: 60),

  // Week 2 - 초급
  WorkoutPlan(
      week: 2, day: 1, level: "초급", sets: [4, 6, 4, 4, 6], restTime: 60),
  WorkoutPlan(
      week: 2, day: 2, level: "초급", sets: [5, 6, 4, 4, 7], restTime: 90),
  WorkoutPlan(
      week: 2, day: 3, level: "초급", sets: [5, 7, 5, 5, 8], restTime: 120),

  // Week 2 - 중급
  WorkoutPlan(
      week: 2, day: 1, level: "중급", sets: [9, 11, 8, 8, 11], restTime: 60),
  WorkoutPlan(
      week: 2, day: 2, level: "중급", sets: [10, 12, 9, 9, 13], restTime: 90),
  WorkoutPlan(
      week: 2, day: 3, level: "중급", sets: [12, 13, 10, 10, 15], restTime: 120),

  // Week 2 - 고급
  WorkoutPlan(
      week: 2, day: 1, level: "고급", sets: [14, 14, 10, 10, 15], restTime: 60),
  WorkoutPlan(
      week: 2, day: 2, level: "고급", sets: [14, 16, 12, 12, 17], restTime: 90),
  WorkoutPlan(
      week: 2, day: 3, level: "고급", sets: [16, 17, 14, 14, 20], restTime: 120),

  // Week 3 - 초급
  WorkoutPlan(
      week: 3, day: 1, level: "초급", sets: [10, 12, 7, 7, 9], restTime: 60),
  WorkoutPlan(
      week: 3, day: 2, level: "초급", sets: [10, 12, 8, 8, 12], restTime: 90),
  WorkoutPlan(
      week: 3, day: 3, level: "초급", sets: [11, 13, 9, 9, 13], restTime: 120),

  // Week 3 - 중급
  WorkoutPlan(
      week: 3, day: 1, level: "중급", sets: [12, 17, 13, 13, 17], restTime: 60),
  WorkoutPlan(
      week: 3, day: 2, level: "중급", sets: [14, 19, 14, 14, 19], restTime: 90),
  WorkoutPlan(
      week: 3, day: 3, level: "중급", sets: [16, 21, 15, 15, 21], restTime: 120),

  // Week 3 - 고급
  WorkoutPlan(
      week: 3, day: 1, level: "고급", sets: [14, 18, 14, 14, 20], restTime: 60),
  WorkoutPlan(
      week: 3, day: 2, level: "고급", sets: [20, 25, 15, 15, 25], restTime: 90),
  WorkoutPlan(
      week: 3, day: 3, level: "고급", sets: [22, 30, 20, 20, 28], restTime: 120),

  // Week 4 - 초급
  WorkoutPlan(
      week: 4, day: 1, level: "초급", sets: [12, 14, 11, 10, 16], restTime: 60),
  WorkoutPlan(
      week: 4, day: 2, level: "초급", sets: [14, 16, 12, 12, 18], restTime: 90),
  WorkoutPlan(
      week: 4, day: 3, level: "초급", sets: [16, 18, 13, 13, 20], restTime: 120),

  // Week 4 - 중급
  WorkoutPlan(
      week: 4, day: 1, level: "중급", sets: [18, 22, 16, 16, 25], restTime: 60),
  WorkoutPlan(
      week: 4, day: 2, level: "중급", sets: [20, 25, 20, 20, 28], restTime: 90),
  WorkoutPlan(
      week: 4, day: 3, level: "중급", sets: [23, 28, 23, 23, 33], restTime: 120),

  // Week 4 - 고급
  WorkoutPlan(
      week: 4, day: 1, level: "고급", sets: [21, 25, 21, 21, 32], restTime: 60),
  WorkoutPlan(
      week: 4, day: 2, level: "고급", sets: [25, 29, 25, 25, 36], restTime: 90),
  WorkoutPlan(
      week: 4, day: 3, level: "고급", sets: [29, 33, 29, 29, 40], restTime: 120),

  // Week 5 - 초급
  WorkoutPlan(
      week: 5, day: 1, level: "초급", sets: [17, 19, 15, 15, 20], restTime: 60),
  WorkoutPlan(
      week: 5,
      day: 2,
      level: "초급",
      sets: [10, 10, 13, 13, 10, 10, 9, 25],
      restTime: 45),
  WorkoutPlan(
      week: 5,
      day: 3,
      level: "초급",
      sets: [13, 13, 15, 15, 12, 12, 10, 30],
      restTime: 45),

  // Week 5 - 중급
  WorkoutPlan(
      week: 5, day: 1, level: "중급", sets: [28, 35, 25, 22, 35], restTime: 60),
  WorkoutPlan(
      week: 5,
      day: 2,
      level: "중급",
      sets: [18, 18, 20, 20, 14, 14, 16, 40],
      restTime: 45),
  WorkoutPlan(
      week: 5,
      day: 3,
      level: "중급",
      sets: [18, 18, 20, 20, 17, 17, 20, 45],
      restTime: 45),

  // Week 5 - 고급
  WorkoutPlan(
      week: 5, day: 1, level: "고급", sets: [36, 40, 30, 24, 40], restTime: 60),
  WorkoutPlan(
      week: 5,
      day: 2,
      level: "고급",
      sets: [19, 19, 22, 22, 18, 18, 22, 45],
      restTime: 45),
  WorkoutPlan(
      week: 5,
      day: 3,
      level: "고급",
      sets: [20, 20, 24, 24, 20, 20, 22, 50],
      restTime: 45),

  // Week 6 - 초급
  WorkoutPlan(
      week: 6, day: 1, level: "초급", sets: [25, 30, 20, 15, 40], restTime: 60),
  WorkoutPlan(
      week: 6,
      day: 2,
      level: "초급",
      sets: [14, 14, 15, 15, 14, 14, 10, 10, 44],
      restTime: 45),
  WorkoutPlan(
      week: 6,
      day: 3,
      level: "초급",
      sets: [13, 13, 17, 17, 16, 16, 14, 14, 50],
      restTime: 45),

  // Week 6 - 중급
  WorkoutPlan(
      week: 6, day: 1, level: "중급", sets: [40, 50, 25, 25, 50], restTime: 60),
  WorkoutPlan(
      week: 6,
      day: 2,
      level: "중급",
      sets: [20, 20, 23, 23, 20, 20, 18, 18, 53],
      restTime: 45),
  WorkoutPlan(
      week: 6,
      day: 3,
      level: "중급",
      sets: [22, 22, 30, 30, 25, 25, 18, 18, 55],
      restTime: 45),

  // Week 6 - 고급
  WorkoutPlan(
      week: 6, day: 1, level: "고급", sets: [45, 55, 35, 30, 55], restTime: 60),
  WorkoutPlan(
      week: 6,
      day: 2,
      level: "고급",
      sets: [22, 22, 30, 30, 24, 24, 18, 18, 58],
      restTime: 45),
  WorkoutPlan(
      week: 6,
      day: 3,
      level: "고급",
      sets: [26, 26, 33, 33, 26, 26, 22, 22, 60],
      restTime: 45),
];
