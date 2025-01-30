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
  // Future<List<Map<String, dynamic>>> _recordsFuture =
  //     SharedPreferencesHelper.getWorkoutRecords();

  late Future<List<Map<String, dynamic>>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    setState(() {
      _recordsFuture = SharedPreferencesHelper.getWorkoutRecords();
    });
  }

  Future<void> _deleteRecord(int index) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await SharedPreferencesHelper.deleteWorkoutRecord(index);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text("기록이 삭제되었습니다.")),
    );
    // _loadRecords();
    setState(() {
      _loadRecords();
    });
  }

  Future<void> _confirmDeleteRecord(BuildContext context, int index) async {
    final result = await showModalActionSheet<bool>(
      context: context,
      title: '기록 삭제',
      message: '이 운동 기록을 삭제하시겠습니까?',
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
      await _deleteRecord(index);
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final originalIndex = records.length - 1 - index;
              final record = records.reversed.toList()[index];
              final date = record['date'];
              final plannedReps = record['plannedReps'] as List<int>;
              final userReps = record['userReps'] as List<int>;
              final week = record['week'];
              final day = record['day'];
              final level = record['level'];

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 16.0, left: 16, right: 16, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "$date",
                                style: TextStyle(
                                  fontSize: dynamicFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: dynamicFontSize),
                              Text(
                                "Week $week, Day $day, $level",
                                style: TextStyle(
                                  fontSize: dynamicFontSize * 0.8,
                                  color: Colors.grey,
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
                                  context, originalIndex);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: List.generate(plannedReps.length, (i) {
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
          );
        },
      ),
    );
  }
}
