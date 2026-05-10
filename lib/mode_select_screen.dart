import 'package:flutter/material.dart';
import 'angle_calibration_screen.dart';
import 'played_screen.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  void _goToAngleCalibration(BuildContext context, String mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AngleCalibrationScreen(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("근무 모드 선택"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayedScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "현재 작업 자세를 선택해주세요",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 30),

            // 앉아서 근무 카드
            _buildModeCard(
              context,
              title: "앉아서 근무",
              icon: Icons.chair_alt,
              color: Colors.blueAccent,
              mode: "sit",
            ),

            const SizedBox(height: 20),

            // 서서 근무 카드
            _buildModeCard(
              context,
              title: "서서 근무",
              icon: Icons.accessibility_new,
              color: Colors.green,
              mode: "stand",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required String mode,
      }) {
    return GestureDetector(
      onTap: () => _goToAngleCalibration(context, mode),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.4), width: 1.4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}