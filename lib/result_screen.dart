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

    Navigator.pop(context); // 홈으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FC), // ✨ 연보라 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFF725AC1),
        title: const Text("근무 결과"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // -------------------------
            //  📌 카드 1: 총 근무 시간
            // -------------------------
            _buildCard(
              title: "총 근무 시간",
              content: _formatDuration(totalSeconds),
            ),
            const SizedBox(height: 20),

            // -------------------------
            //  📌 카드 2: 나쁜 자세 누적
            // -------------------------
            _buildCard(
              title: "나쁜 자세 누적 시간",
              content: _formatDuration(badSeconds),
              highlight: Colors.redAccent,
            ),

            const Spacer(),

            // -------------------------
            //  📌 스트레칭 버튼 (위로 올림)
            // -------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _goToStretch(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF725AC1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "스트레칭 추천 받기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 30), // ← 하단 여백 확보
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ⭐ 재사용 가능한 카드 컴포넌트 — WorkScreen과 톤 맞춤
  // ================================================================
  Widget _buildCard({
    required String title,
    required String content,
    Color highlight = const Color(0xFF725AC1),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: highlight,
            ),
          ),
        ],
      ),
    );
  }
}