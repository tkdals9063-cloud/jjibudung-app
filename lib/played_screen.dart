import 'package:flutter/material.dart';
import 'point_manager.dart';

class PlayedScreen extends StatefulWidget {
  const PlayedScreen({super.key});

  @override
  State<PlayedScreen> createState() => _PlayedScreenState();
}

class _PlayedScreenState extends State<PlayedScreen> {
  int _selectedTab = 0;
  int _totalPoints = 0;

  // 추후 실제 데이터로 교체
  final List<Map<String, int>> _dayData = List.generate(24, (_) => {'good': 0, 'bad': 0});
  final List<Map<String, int>> _weekData = List.generate(7, (_) => {'good': 0, 'bad': 0});
  final List<Map<String, int>> _monthData = List.generate(31, (_) => {'good': 0, 'bad': 0});

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PointManager.getTotalPoints();
    setState(() => _totalPoints = p);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = "${today.year}년 ${today.month}월 ${today.day}일";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF725AC1),
        title: const Text("기록"),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: () {
              showDatePicker(
                context: context,
                initialDate: today,
                firstDate: DateTime(today.year, 1, 1),
                lastDate: today,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            const Text("오늘", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            _tabButtons(),
            const SizedBox(height: 20),

            _buildChart(),
            const SizedBox(height: 16),

            Row(
              children: [
                _legend(Colors.green, "좋은 자세"),
                const SizedBox(width: 20),
                _legend(Colors.redAccent, "나쁜 자세"),
              ],
            ),
            const SizedBox(height: 28),

            _statCard(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              label: "보유 포인트",
              value: "$_totalPoints pt",
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButtons() {
    final tabs = ["일", "주", "월"];
    return Row(
      children: List.generate(3, (i) {
        final selected = _selectedTab == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedTab = i),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF725AC1) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Text(
              tabs[i],
              style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChart() {
    switch (_selectedTab) {
      case 0:
        return _barChart(
          data: _dayData,
          labels: List.generate(24, (i) {
            if (i == 0) return "0시";
            if (i == 6) return "6시";
            if (i == 12) return "12시";
            if (i == 18) return "18시";
            return "";
          }),
        );
      case 1:
        return _barChart(
          data: _weekData,
          labels: ["월", "화", "수", "목", "금", "토", "일"],
        );
      case 2:
        return _barChart(
          data: _monthData,
          labels: List.generate(31, (i) {
            if (i == 0) return "1";
            if (i == 9) return "10";
            if (i == 19) return "20";
            if (i == 30) return "31";
            return "";
          }),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _barChart({
    required List<Map<String, int>> data,
    required List<String> labels,
  }) {
    final maxVal = data.fold<int>(
      1,
      (prev, e) => (e['good']! + e['bad']!) > prev ? e['good']! + e['bad']! : prev,
    );
    const chartHeight = 160.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: SizedBox(
        height: chartHeight + 24,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.length, (i) {
            final total = data[i]['good']! + data[i]['bad']!;
            final goodH = total == 0 ? 0.0 : (data[i]['good']! / maxVal) * chartHeight;
            final badH = total == 0 ? 0.0 : (data[i]['bad']! / maxVal) * chartHeight;
            final label = i < labels.length ? labels[i] : "";

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: goodH,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                      Container(
                        height: badH > 0 ? badH : 6,
                        decoration: BoxDecoration(
                          color: total == 0 ? Colors.grey.withOpacity(0.15) : Colors.redAccent,
                          borderRadius: goodH == 0
                              ? BorderRadius.circular(3)
                              : const BorderRadius.vertical(bottom: Radius.circular(3)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF725AC1)),
          ),
        ],
      ),
    );
  }
}
