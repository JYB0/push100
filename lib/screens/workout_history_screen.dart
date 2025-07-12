import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';
import 'package:push100/main.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _recordsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final future = SharedPreferencesHelper.getWorkoutRecords();
    setState(() {
      _recordsFuture = future;
    });
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true); // ⬅️ 로딩 시작
    try {
      await SharedPreferencesHelper.deleteWorkoutRecordByContent(record);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("✅ 기록이 삭제되었습니다.")),
      );

      await _loadRecords();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("❌ 기록 삭제 중 오류 발생: $e")),
      );
    } finally {
      setState(() => _isLoading = false); // ⬅️ 로딩 종료
    }
  }

  Future<void> _confirmDeleteRecord(
      BuildContext context, Map<String, dynamic> record) async {
    final date = record['date'] ?? '';
    final week = record['week'];
    final day = record['day'];
    final level = record['level'];

    final message =
        '$date (Week $week, Day $day, $level)의\n운동 기록을 삭제하시겠습니까?\n삭제시 되돌릴 수 없습니다.';

    final result = await showModalActionSheet<bool>(
      context: context,
      title: '기록 삭제',
      message: message,
      cancelLabel: '취소',
      actions: [
        const SheetAction(
          label: '삭제',
          key: true, // 삭제를 나타냄
          isDestructiveAction: true,
        ),
      ],
    );

    // 사용자가 "삭제"를 선택한 경우에만 삭제 진행
    if (result == true) {
      // 삭제 작업 수행
      await _deleteRecord(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final itemSize = (screenWidth - (12 * 4) - 32) / 5;

    double baseFontSize = 16.0;
    double dynamicFontSize = baseFontSize * (screenWidth / 400);

    return Scaffold(
      appBar: AppBar(title: const Text("운동 기록")),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _recordsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "저장된 운동 기록이 없습니다.",
                    style: TextStyle(fontSize: dynamicFontSize),
                  ),
                );
              }

              final records = snapshot.data!;
              int totalPushupsSum = records.fold<int>(0, (sum, r) {
                final userReps = r['userReps'] as List<int>;
                return sum + userReps.fold<int>(0, (s, reps) => s + reps);
              });

              int totalDuration = records.fold<int>(0, (sum, r) {
                final raw = r['durationSeconds'];
                final duration = (raw is int)
                    ? raw
                    : int.tryParse(raw?.toString() ?? '0') ?? 0;
                return sum + duration;
              });

              final durationMinutes = totalDuration ~/ 60;
              final durationSeconds = totalDuration % 60;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, left: 16, top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "총 푸쉬업: $totalPushupsSum개",
                          style: TextStyle(
                            fontSize: dynamicFontSize * 0.95,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "총 운동 시간: "
                          "${durationMinutes > 0 ? '$durationMinutes분 ' : ''}"
                          "${durationSeconds > 0 ? '$durationSeconds초' : ''}",
                          style: TextStyle(
                            fontSize: dynamicFontSize * 0.9,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        // final originalIndex = index;
                        final record = records[index];
                        final date = record['date'];
                        final plannedReps = record['plannedReps'] as List<int>;
                        final userReps = record['userReps'] as List<int>;
                        final week = record['week'];
                        final day = record['day'];
                        final level = record['level'];
                        final totalPushups =
                            userReps.fold<int>(0, (sum, reps) => sum + reps);

                        final durationSeconds = record['durationSeconds'] ?? 0;
                        final durationMinutes = durationSeconds ~/ 60;

                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom: 16.0, left: 16, right: 16, top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$date",
                                          style: TextStyle(
                                            fontSize: dynamicFontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Week $week, Day $day, $level",
                                          style: TextStyle(
                                            fontSize: dynamicFontSize * 0.8,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "총 푸쉬업 갯수 : $totalPushups개",
                                          style: TextStyle(
                                            fontSize: dynamicFontSize * 0.85,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        if (durationSeconds != null &&
                                            durationSeconds > 0)
                                          Text(
                                            durationSeconds >= 60
                                                ? "운동 시간 : $durationMinutes분"
                                                : "운동 시간 : $durationSeconds초",
                                            style: TextStyle(
                                              fontSize: dynamicFontSize * 0.8,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: AppColors.redPrimary,
                                        size: dynamicFontSize * 1.5,
                                      ),
                                      onPressed: () async {
                                        await _confirmDeleteRecord(
                                            context, record);
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children:
                                      List.generate(plannedReps.length, (i) {
                                    final planned = plannedReps[i];
                                    final user = userReps[i];
                                    final percent = user / planned;

                                    return Container(
                                      width: itemSize,
                                      height: itemSize,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: percent >= 1.0
                                              ? AppColors.greenPrimary
                                              : AppColors.redPrimary,
                                          width: itemSize * 0.05,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          "$user/$planned",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: itemSize * 0.3,
                                            fontWeight: FontWeight.bold,
                                            color: percent >= 1.0
                                                ? AppColors.greenPrimary
                                                : AppColors.redPrimary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          if (_isLoading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
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
