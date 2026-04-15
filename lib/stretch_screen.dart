// lib/stretch_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'point_manager.dart';

class StretchItem {
  final String name;      // 화면에 보여줄 이름 (한글)
  final String gifPath;   // assets 안에 있는 GIF 경로
  final bool isStretch;   // true: 스트레칭, false: 운동

  const StretchItem({
    required this.name,
    required this.gifPath,
    required this.isStretch,
  });
}

class StretchScreen extends StatefulWidget {
  final int basePoints; // ResultScreen 에서 넘어온 근무 포인트

  const StretchScreen({
    super.key,
    required this.basePoints,
  });

  @override
  State<StretchScreen> createState() => _StretchScreenState();
}

class _StretchScreenState extends State<StretchScreen> {
  final _random = Random();

  // ✅ 스트레칭 4개
  final List<StretchItem> _stretchList = const [
    StretchItem(
      name: "스탠딩 햄스트링 스트레칭",
      gifPath: "assets/stretch/standing_hamstring_stretch.gif",
      isStretch: true,
    ),
    StretchItem(
      name: "토래식 월 익스텐션 스트레칭",
      gifPath: "assets/stretch/thoracic_wall_extension_stretch.gif",
      isStretch: true,
    ),
    StretchItem(
      name: "펙 스트레칭",
      gifPath: "assets/stretch/pec_stretch.gif",
      isStretch: true,
    ),
    StretchItem(
      name: "힙 플랙서 스트레칭",
      gifPath: "assets/stretch/hip_flexor_stretch.gif",
      isStretch: true,
    ),
  ];

  // ✅ 운동 4개
  final List<StretchItem> _exerciseList = const [
    StretchItem(
      name: "스탠딩 토래식 익스텐션",
      gifPath: "assets/exercise/standing_thoracic_extension.gif",
      isStretch: false,
    ),
    StretchItem(
      name: "스탠딩 힙힌지",
      gifPath: "assets/exercise/standing_hip_hinge.gif",
      isStretch: false,
    ),
    StretchItem(
      name: "스탠딩 힙 익스텐션",
      gifPath: "assets/exercise/standing_hip_extension.gif",
      isStretch: false,
    ),
    StretchItem(
      name: "토래식 딜테이션 엑서사이즈",
      gifPath: "assets/exercise/thoracic_dilatation_exercise.gif",
      isStretch: false,
    ),
  ];

  late List<StretchItem> _todayRoutine;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateTodayRoutine();
  }

  // 리스트에서 n개 랜덤 선택
  List<T> _pickRandom<T>(List<T> list, int n) {
    final temp = List<T>.from(list);
    temp.shuffle(_random);
    return temp.take(n).toList();
  }

  void _generateTodayRoutine() {
    final stretches = _pickRandom(_stretchList, 2);
    final exercises = _pickRandom(_exerciseList, 2);

    setState(() {
      // 스트레칭 2개 + 운동 2개
      _todayRoutine = [...stretches, ...exercises];
    });
  }

  Future<void> _completeRoutine() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    // 🔢 보너스 계산 (근무 포인트의 20%, 최소 10점, 최대 100점)
    int bonus = (widget.basePoints * 0.2).round();
    if (bonus < 10) bonus = 10;
    if (bonus > 100) bonus = 100;

    // 총 포인트에 보너스 더하기
    await PointManager.addBonusPoints(bonus);

    if (!mounted) return;
    Navigator.pop<int>(context, bonus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("스트레칭 / 운동 추천"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "아래 스트레칭 2개 + 운동 2개를 따라 해보세요!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "오늘 근무 포인트: ${widget.basePoints} pt",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            // 🔁 다시 뽑기 버튼
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isSaving ? null : _generateTodayRoutine,
                icon: const Icon(Icons.refresh),
                label: const Text("다른 동작으로 다시 뽑기"),
              ),
            ),

            const SizedBox(height: 8),

            // 리스트 영역
            Expanded(
              child: ListView.separated(
                itemCount: _todayRoutine.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _todayRoutine[index];
                  return _buildExerciseCard(item);
                },
              ),
            ),

            const SizedBox(height: 12),

            // 완료 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _completeRoutine,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "스트레칭 / 운동 완료하고 보너스 받기",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(StretchItem item) {
    final tagText = item.isStretch ? "스트레칭" : "운동";
    final tagColor = item.isStretch ? Colors.blue : Colors.green;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 + 이름
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tagText,
                    style: TextStyle(
                      fontSize: 12,
                      color: tagColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // GIF
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  item.gifPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    // GIF 아직 없을 때 에러 안나게
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          "GIF 파일을 assets 폴더에 넣어주세요",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}