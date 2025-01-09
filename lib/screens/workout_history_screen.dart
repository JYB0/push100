import 'package:flutter/material.dart';
import 'package:push100/helpers/shared_preferences_helper.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  Future<List<Map<String, dynamic>>> _recordsFuture =
      SharedPreferencesHelper.getWorkoutRecords();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _recordsFuture = SharedPreferencesHelper.getWorkoutRecords();
    setState(() {});
  }

  Future<void> _deleteRecord(int index, BuildContext context) async {
    await SharedPreferencesHelper.deleteWorkoutRecord(index);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("기록이 삭제되었습니다.")),
    );
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("운동 기록")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SharedPreferencesHelper.getWorkoutRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("저장된 운동 기록이 없습니다."));
          }

          final records = snapshot.data!;
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final date = record['date'];
              final plannedReps = record['plannedReps'] as List<int>;
              final userReps = record['userReps'] as List<int>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "날짜: $date",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _deleteRecord(index, context);
                              _loadRecords();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: List.generate(plannedReps.length, (i) {
                          final planned = plannedReps[i];
                          final user = userReps[i];
                          final percent = user / planned;

                          return Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: percent >= 1.0
                                    ? Colors.green
                                    : Colors.red, // 성공 여부에 따라 색상
                                width: 3,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$user",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: percent >= 1.0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                Text(
                                  "/$planned",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
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
