import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool backgroundAllowed = false;
  bool batteryAllowed = false;

  static const MethodChannel _channel =
      MethodChannel("jjibudung/posture_service");

  // 🔧 백그라운드 설정
  Future<void> _openBackgroundSettings() async {
    await openAppSettings();
  }

  // 🔧 배터리 최적화 해제 요청
  Future<void> _requestBatteryOptimization() async {
    await _channel.invokeMethod("requestIgnoreBatteryOptimization");
  }

  void _next() {
    if (!backgroundAllowed || !batteryAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("두 항목 모두 체크해야 진행할 수 있습니다."),
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, "/welcome");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("시작하기 전에 필요한 설정"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📌 찌뿌둥이 정확하게 작동하려면 아래 설정이 필요합니다.",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // 카드 1
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: CheckboxListTile(
                  value: backgroundAllowed,
                  onChanged: (v) {
                    setState(() => backgroundAllowed = v ?? false);
                    _openBackgroundSettings();
                  },
                  title: const Text("백그라운드 실행 허용"),
                  subtitle: const Text("앱이 화면을 꺼도 자세를 감지할 수 있도록 해요."),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 카드 2
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: CheckboxListTile(
                  value: batteryAllowed,
                  onChanged: (v) {
                    setState(() => batteryAllowed = v ?? false);
                    _requestBatteryOptimization();
                  },
                  title: const Text("배터리 최적화 제외"),
                  subtitle: const Text("갤럭시 사용자의 경우 필수 설정입니다."),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "설정 완료하고 시작하기",
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}