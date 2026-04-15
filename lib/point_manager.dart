import 'package:shared_preferences/shared_preferences.dart';

class PointManager {
  static const String key = "total_points";

  static Future<int> addWorkPoints(int sec) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getInt(key) ?? 0;
    final gain = sec ~/ 60;
    final total = old + gain;
    await prefs.setInt(key, total);
    return gain;
  }

  static Future<int> addBonusPoints(int bonus) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getInt(key) ?? 0;
    final newTotal = old + bonus;
    await prefs.setInt(key, newTotal);
    return bonus;
  }

  static Future<int> getTotalPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }
}