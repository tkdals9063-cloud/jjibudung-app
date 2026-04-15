// lib/work_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'point_manager.dart';
import 'result_screen.dart';

class WorkScreen extends StatefulWidget {
  final String mode;
  final double baselineAngle;

  const WorkScreen({
    super.key,
    required this.mode,
    required this.baselineAngle,
  });

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  static const double _angleThreshold = 15.0; // 기준 +15도
  static const int _badThresholdSeconds = 1800; // 30분

  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _sensorSub;

  int _totalSeconds = 0;
  int _badTotalSeconds = 0;
  int _badContinuousSeconds = 0;

  bool _isBad = false;
  bool _isPaused = false;
  bool _isVibrating = false;

  @override
  void initState() {
    super.initState();

    // 화면 꺼짐 방지
    WakelockPlus.enable();

    _startMonitoring();
  }

  void _startMonitoring() {
    // 센서 listen
    _sensorSub = accelerometerEvents.listen((event) {
      double angle = event.y * 10; // 통일된 계산식
      double diff = (angle - widget.baselineAngle).abs();

      if (!mounted) return;
      setState(() {
        _isBad = (!_isPaused && diff >= _angleThreshold);
      });
    });

    // 타이머 1초 주기
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) return;

      setState(() {
        _totalSeconds++;

        if (_isBad) {
          _badTotalSeconds++;
          _badContinuousSeconds++;
        } else {
          _badContinuousSeconds = 0;
        }
      });

      _updateVibration();
    });
  }

  Future<void> _updateVibration() async {
    // BAD 상태 + 30분 연속 유지 + 아직 진동 안 울리는 중
    if (_isBad &&
        !_isPaused &&
        _badContinuousSeconds >= _badThresholdSeconds &&
        !_isVibrating) {
      _isVibrating = true;

      if (await Vibration.hasVibrator() ?? false) {
        // 반복 진동 패턴
        Vibration.vibrate(pattern: [0, 800, 400, 800], repeat: -1);
      }
    }

    // GOOD 자세로 돌아오면 즉시 진동 종료
    if ((!_isBad || _isPaused) && _isVibrating) {
      _isVibrating = false;
      Vibration.cancel();
    }
  }

  Future<void> _endWork() async {
    _timer?.cancel();
    await _sensorSub?.cancel();

    if (_isVibrating) Vibration.cancel();
    WakelockPlus.disable();

    final workPoints = await PointManager.addWorkPoints(_totalSeconds);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          totalSeconds: _totalSeconds,
          badSeconds: _badTotalSeconds,
          workPoints: workPoints,
        ),
      ),
    );
  }

  void _pause() {
    setState(() => _isPaused = true);
    _updateVibration();
  }

  void _resume() {
    setState(() => _isPaused = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorSub?.cancel();
    if (_isVibrating) Vibration.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatDuration(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;

    if (h > 0) return "${h}시간 ${m}분 ${sec}초";
    if (m > 0) return "${m}분 ${sec}초";
    return "${sec}초";
  }

  @override
  Widget build(BuildContext context) {
    final modeText = widget.mode == "sit" ? "앉아서 근무 중" : "서서 근무 중";

    Color postureColor = _isPaused
        ? Colors.grey
        : _isBad
            ? Colors.red
            : Colors.green;

    String postureText = _isPaused
        ? "일시 정지"
        : _isBad
            ? "나쁜 자세 감지"
            : "좋은 자세 유지 중";

    return Scaffold(
      appBar: AppBar(
        title: Text(modeText),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("총 근무 시간", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(_formatDuration(_totalSeconds),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

            const SizedBox(height: 24),

            const Text("나쁜 자세 누적 시간", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(_formatDuration(_badTotalSeconds),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),

            const SizedBox(height: 32),

            Text(
              postureText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: postureColor,
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isPaused ? null : _pause,
                  icon: const Icon(Icons.pause),
                  label: const Text("일시 정지"),
                ),
                ElevatedButton.icon(
                  onPressed: _isPaused ? _resume : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("재시작"),
                ),
                ElevatedButton.icon(
                  onPressed: _endWork,
                  icon: const Icon(Icons.stop),
                  label: const Text("근무 종료"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}