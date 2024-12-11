import 'package:flutter/material.dart';
import 'home_screen.dart';

class AgeSelectionScreen extends StatefulWidget {
  final int pushupCount;

  const AgeSelectionScreen({super.key, required this.pushupCount});

  @override
  _AgeSelectionScreenState createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  String? selectedAgeRange;

  final List<String> ageRanges = [
    "40세 이하",
    "40세 이상 ~ 55세 이하",
    "55세 이상",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "나이를 선택하세요",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...ageRanges.map((ageRange) {
                return RadioListTile<String>(
                  title: Text(ageRange),
                  value: ageRange,
                  groupValue: selectedAgeRange,
                  onChanged: (value) {
                    setState(() {
                      selectedAgeRange = value;
                    });
                  },
                );
              }),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  if (selectedAgeRange != null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(
                          pushupCount: widget.pushupCount,
                          ageRange: selectedAgeRange!,
                        ),
                      ),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("연령대를 선택하세요!"),
                      ),
                    );
                  }
                },
                child: const Text("완료"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
