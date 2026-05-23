import 'package:flutter/material.dart';
import 'stretch_screen.dart';

class ResultScreen extends StatelessWidget {
  final int totalSeconds;
  final int badSeconds;
  final int workPoints;
  final PostureType postureType;

  const ResultScreen({
    super.key,
    required this.totalSeconds,
    required this.badSeconds,
    required this.workPoints,
    required this.postureType,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) return "$h시간 $m분 $s초";
    if (m > 0) return "$m분 $s초";
    return "$s초";
  }

  int get _postureScore {
    if (totalSeconds <= 0) return 0;

    final badRate = badSeconds / totalSeconds;
    final score = 100 - (badRate * 100).round();

    return score.clamp(0, 100);
  }

  String get _scoreLabel {
    if (_postureScore >= 90) return "매우 좋음";
    if (_postureScore >= 75) return "양호";
    if (_postureScore >= 60) return "주의";
    return "개선 필요";
  }

  Color get _scoreColor {
    if (_postureScore >= 90) return Colors.green;
    if (_postureScore >= 75) return Colors.blue;
    if (_postureScore >= 60) return Colors.orange;
    return Colors.redAccent;
  }

  String get _postureName {
    switch (postureType) {
      case PostureType.anteriorTilt:
        return "전방경사";
      case PostureType.posteriorTilt:
        return "후방경사";
    }
  }

  String get _postureAdvice {
    switch (postureType) {
      case PostureType.anteriorTilt:
        return "고관절 앞쪽 이완과 둔근·코어 활성화 루틴을 추천합니다.";
      case PostureType.posteriorTilt:
        return "햄스트링 긴장 완화와 허리·골반 주변 안정화 루틴을 추천합니다.";
    }
  }

  String get _sessionSummary {
    if (_postureScore >= 80) {
      return "방금 세션은 비교적 안정적이었어요. 지금 상태를 유지해보세요.";
    }
    if (_postureScore >= 60) {
      return "장시간 자세가 조금 무너졌어요. 짧은 루틴으로 바로 풀어주면 좋아요.";
    }
    return "나쁜 자세 누적이 꽤 있었어요. 지금 바로 교정 루틴을 추천합니다.";
  }

  Future<void> _goToStretch(BuildContext context) async {
    final bonus = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StretchScreen(
          basePoints: workPoints,
          postureType: postureType,
        ),
      ),
    );

    if (bonus != null && context.mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("스트레칭 완료!"),
          content: Text("보너스 포인트 +$bonus 점 지급되었습니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF725AC1),
        title: const Text("세션 결과"),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF725AC1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      postureType == PostureType.anteriorTilt
                          ? Icons.front_hand_rounded
                          : Icons.back_hand_rounded,
                      color: const Color(0xFF725AC1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$_postureName 감지",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _sessionSummary,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                  const Text(
                    "세션 자세 점수",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$_postureScore점",
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _scoreLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildCard(
              title: "총 근무 시간",
              content: _formatDuration(totalSeconds),
            ),

            const SizedBox(height: 20),

            _buildCard(
              title: "나쁜 자세 누적 시간",
              content: _formatDuration(badSeconds),
              highlight: Colors.redAccent,
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                  const Text(
                    "추천 안내",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF725AC1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _postureAdvice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

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
                  "맞춤 루틴 추천 받기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

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
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
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