import 'package:flutter/services.dart';

class NativePostureService {
  static const MethodChannel _channel =
      MethodChannel("jjibudung/posture_service");

  static Future<void> start(double baseline, String mode) async {
    await _channel.invokeMethod("startService", {
      "baselineAngle": baseline,
      "mode": mode,
    });
  }

  static Future<void> stop() async {
    await _channel.invokeMethod("stopService");
  }

  static Future<Map> getTimes() async {
    return await _channel.invokeMethod("getTimes");
  }

  static Future<void> reset() async {
    await _channel.invokeMethod("resetTimes");
  }
}