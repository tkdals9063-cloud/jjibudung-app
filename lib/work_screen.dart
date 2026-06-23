// lib/work_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

import 'point_manager.dart';
import 'result_screen.dart';
import 'native_service.dart';
import 'posture_type.dart';
import 'session_manager.dart';

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

class _WorkScreenState extends State<WorkScreen>
    with SingleTickerProviderStateMixin {
  static const double _angleThreshold = 15.0;
  static const int _badThresholdSeconds = 1800;

  StreamSubscription<AccelerometerEvent>? _sensorSub;
  StreamSubscription<int>? _proximitySub;
  Timer? _timer;

  int _totalSeconds = 0;
  int _badTotalSeconds = 0;
  int _badContinuousSeconds = 0;

  bool _isBad = false;
  bool _isPaused = false;
  bool _isVibrating = false;

  int _anteriorBadSeconds = 0;
  int _posteriorBadSeconds = 0;
  double _lastAngleDiff = 0;

  int _currentHour = DateTime.now().hour;
  int _hourGoodSeconds = 0;
  int _hourBadSeconds = 0;

  bool _sleepMode = false;

  // 🌙 애니메이션 컨트롤러
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    _startMonitoring();
    NativePostureService.start(widget.baselineAngle, widget.mode);
    _startProximitySensor();

    // 🔥 절전 애니메이션: fade + scale
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(_animController);
  }

  // -------------------------
  // 근접 센서 
  // -------------------------
  void _startProximitySensor() {
    if (!Platform.isAndroid) return;
    _proximitySub = ProximitySensor.events.listen((int event) {
      final isNear = event > 0;
      if (isNear && !_sleepMode) {
        WakelockPlus.disable();
        _toggleSleepMode();
      } else if (!isNear && _sleepMode) {
        WakelockPlus.enable();
        _toggleSleepMode();
      }
    });
  }

  // -------------------------
  // 센서 + 타이머
  // -------------------------
  void _startMonitoring() {
    _sensorSub = accelerometerEventStream().listen(
      (event) {
        final angle = event.y * 10;
        final diff = angle - widget.baselineAngle;

        if (!mounted) return;
        setState(() {
          _lastAngleDiff = diff;
          _isBad = !_isPaused && diff.abs() >= _angleThreshold;
        });
      },
      onError: (e) => debugPrint('Accelerometer error: $e'),
      cancelOnError: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _isPaused) return;

    final now = DateTime.now();

    if (now.hour != _currentHour) {
      SessionManager.addHourData(
        DateTime(now.year, now.month, now.day, _currentHour),
        _currentHour,
        _hourGoodSeconds,
        _hourBadSeconds,
      );
      _currentHour = now.hour;
      _hourGoodSeconds = 0;
      _hourBadSeconds = 0;
    }

    setState(() {
      _totalSeconds += 1;

      if (_isBad) {
        _badTotalSeconds += 1;
        _badContinuousSeconds += 1;
        _hourBadSeconds += 1;
        if (_lastAngleDiff > 0) {
          _anteriorBadSeconds += 1;
        } else {
          _posteriorBadSeconds += 1;
        }
      } else {
        _badContinuousSeconds = 0;
        _hourGoodSeconds += 1;
      }
    });

    _updateVibration();
  }

  // -------------------------
  // 30분 나쁜 자세 → 진동
  // -------------------------
  Future<void> _updateVibration() async {
    if (_isBad &&
        !_isPaused &&
        _badContinuousSeconds >= _badThresholdSeconds &&
        !_isVibrating) {
      _isVibrating = true;

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 800, 400, 800], repeat: -1);
      }
    }

    if ((!_isBad || _isPaused) && _isVibrating) {
      _isVibrating = false;
      Vibration.cancel();
    }
  }

  // -------------------------
  // 절전모드 토글
  // -------------------------
  void _toggleSleepMode() {
    setState(() => _sleepMode = !_sleepMode);

    if (_sleepMode) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  // -------------------------
  // 근무 종료
  // -------------------------
  Future<void> _endWork() async {
    _timer?.cancel();
    await _sensorSub?.cancel();
    NativePostureService.stop();

    if (_isVibrating) Vibration.cancel();
    WakelockPlus.disable();

    final now = DateTime.now();
    await SessionManager.addHourData(
      DateTime(now.year, now.month, now.day, _currentHour),
      _currentHour,
      _hourGoodSeconds,
      _hourBadSeconds,
    );

    final workPoints = await PointManager.addWorkPoints(_totalSeconds);
    if (!mounted) return;

    final postureType = _anteriorBadSeconds >= _posteriorBadSeconds
        ? PostureType.anteriorTilt
        : PostureType.posteriorTilt;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          totalSeconds: _totalSeconds,
          badSeconds: _badTotalSeconds,
          workPoints: workPoints,
          postureType: postureType,
        ),
      ),
    );
  }

  String _format(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;

    if (h > 0) return "$h시간 ${m}분 ${s}초";
    if (m > 0) return "$m분 ${s}초";
    return "${s}초";
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _timer?.cancel();
    _sensorSub?.cancel();
    _proximitySub?.cancel();
    if (_isVibrating) Vibration.cancel();
    NativePostureService.stop();
    _animController.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isSit = widget.mode == "sit";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF725AC1),
        title: Text(isSit ? "앉아서 근무 중" : "서서 근무 중"),
        centerTitle: true,
        actions: [
          // 🔥 오른쪽 상단 🌙 버튼
          IconButton(
            icon: const Icon(Icons.nightlight_round, color: Colors.white),
            onPressed: _toggleSleepMode,
          )
        ],
      ),

      body: Stack(
        children: [
          _mainUI(),

          // 🔥 절전모드 오버레이(Fade & Scale)
          AnimatedBuilder(
            animation: _animController,
            builder: (_, __) {
              return IgnorePointer(
                ignoring: !_sleepMode,
                child: Opacity(
                  opacity: _fadeAnim.value,
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: GestureDetector(
                          onTap: _toggleSleepMode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "해제",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: !_sleepMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF725AC1),
                onPressed: _endWork,
                icon: const Icon(Icons.stop),
                label: const Text("근무 종료"),
              ),
            )
          : null,
    );
  }

  // -------------------------
  // 📌 메인 카드 UI
  // -------------------------
  Widget _mainUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 10),

          _buildCard(title: "총 근무 시간", content: _format(_totalSeconds)),
          const SizedBox(height: 20),

          _buildCard(title: "나쁜 자세 누적", content: _format(_badTotalSeconds)),
          const SizedBox(height: 32),

          Text(
            _isPaused
                ? "일시 정지 중"
                : _isBad
                    ? "⚠ 나쁜 자세 감지!"
                    : "😊 좋은 자세 유지 중",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: _isPaused
                  ? Colors.grey
                  : _isBad
                      ? Colors.red
                      : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required String content}) {
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
              style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF725AC1),
            ),
          ),
        ],
      ),
    );
  }
}