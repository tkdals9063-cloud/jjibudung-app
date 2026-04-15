// lib/result_screen.dart
import 'package:flutter/material.dart';
import 'point_manager.dart';
import 'stretch_screen.dart';

class ResultScreen extends StatelessWidget {
  final int totalSeconds;
  final int badSeconds;
  final int workPoints;

  const ResultScreen({
    super.key,
    required this.totalSeconds,
    required this.badSeconds,
    required this.workPoints,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) return "$h시간 $m분 $s초";
    if (m > 0) return "$m분 $s초";
    return "$s초";
  }

  Future<void> _goToStretch(BuildContext context) async {
    final bonus = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StretchScreen(basePoints: workPoints),
      ),
    );

    if (bonus != null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("스트레칭 완료!"),
          content: Text("보너스 포인트 +$bonus 점 지급되었습니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            )
          ],
        ),
      );
    }

    // 홈으로 이동
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("근무 결과"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "총 근무 시간: ${_formatDuration(totalSeconds)}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "나쁜 자세 누적 시간: ${_formatDuration(badSeconds)}",
              style: const TextStyle(fontSize: 18, color: Colors.redAccent),
            ),
            const SizedBox(height: 30),
            Text(
              "근무 포인트: $workPoints 점",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _goToStretch(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("스트레칭 추천 받기"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}