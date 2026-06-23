// lib/angle_calibration_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

import 'work_screen.dart';

class AngleCalibrationScreen extends StatefulWidget {
  final String mode; // "sit" or "stand"

  const AngleCalibrationScreen({super.key, required this.mode});

  @override
  State<AngleCalibrationScreen> createState() => _AngleCalibrationScreenState();
}

class _AngleCalibrationScreenState extends State<AngleCalibrationScreen> {
  // 센서에서 읽은 현재 각도(실제로는 y 가속도 값)
  double _currentAngle = 0.0;

  // 최종 기준 각도
  double? _baselineAngle;

  // 센서 스트림 / 타이머
  StreamSubscription<AccelerometerEvent>? _sensorSub;
  Timer? _timer;

  // 측정 상태
  bool _isMeasuring = true;
  int _goodPostureSeconds = 0;

  // 기준자세로 본다고 보는 허용 오차 (y 값 기준)
  // 대략 ±15도 정도에 해당(대략적인 값)
  static const double _calibrationThreshold = 1.5;

  @override
  void initState() {
    super.initState();
    _listenSensor();
    _startTimer();
  }

  /// 가속도 센서 구독
  void _listenSensor() {
    _sensorSub = accelerometerEventStream().listen(
      (event) {
        final angle = event.y;
        if (!mounted) return;
        setState(() {
          _currentAngle = angle;
        });
      },
      onError: (e) { debugPrint('Accelerometer error: $e'); },
      cancelOnError: false,
    );
  }

  /// 1초마다 기준자세 유지 시간을 체크
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMeasuring) return;

      // 아직 기준 각도가 없다면 현재 값을 기준으로 삼음
      _baselineAngle ??= _currentAngle;

      final diff = (_currentAngle - _baselineAngle!).abs();

      if (diff <= _calibrationThreshold) {
        // 기준자세 범위 안에 있음 → 유지 시간 +1
        _goodPostureSeconds++;
      } else {
        // 기준자세에서 벗어남 → 다시 시도
        _goodPostureSeconds = 0;
        // 새 자세를 기준으로 삼도록 baseline 을 갱신
        _baselineAngle = _currentAngle;
      }

      if (_goodPostureSeconds >= 3) {
        // 3초 연속 유지 성공
        _finishMeasurement();
      }

      if (!mounted) return;
      setState(() {});
    });
  }

  /// 기준자세 측정 완료 → 진동 + WorkScreen 으로 이동
  Future<void> _finishMeasurement() async {
    if (!_isMeasuring) return;

    setState(() {
      _isMeasuring = false;
    });

    // 강한 진동 1회
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 800);
    }

    if (!mounted) return;

    final baseline = _baselineAngle ?? _currentAngle;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkScreen(
          mode: widget.mode,
          baselineAngle: baseline,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면에 보일 때만 각도를 "도"처럼 보기 좋게 10배 해서 표시
    final displayAngle = (_currentAngle * 10).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("앵글 보정"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "기준 자세로 3초 유지하세요!",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),

            Text(
              "현재 각도: $displayAngle°",
              style: const TextStyle(fontSize: 28),
            ),

            const SizedBox(height: 20),

            Text(
              "유지 시간: $_goodPostureSeconds / 3초",
              style: TextStyle(
                fontSize: 18,
                color: _goodPostureSeconds >= 3
                    ? Colors.green
                    : Colors.grey[700],
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              "휴대폰을 주머니에 넣고\n가만히 기준 자세를 유지해주세요.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}