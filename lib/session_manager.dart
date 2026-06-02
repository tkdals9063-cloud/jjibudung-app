import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _key = 'sessions';

  static String _dateKey(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  static Future<Map<String, dynamic>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> _saveAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<void> addHourData(DateTime date, int hour, int goodSecs, int badSecs) async {
    if (goodSecs == 0 && badSecs == 0) return;
    final all = await _loadAll();
    final dateKey = _dateKey(date);
    if (!all.containsKey(dateKey)) all[dateKey] = {};
    final hourKey = hour.toString();
    final existing = (all[dateKey][hourKey] as Map<String, dynamic>?) ?? {'good': 0, 'bad': 0};
    all[dateKey][hourKey] = {
      'good': (existing['good'] as int) + goodSecs,
      'bad': (existing['bad'] as int) + badSecs,
    };
    await _saveAll(all);
  }

  static Future<List<Map<String, int>>> getDayData(DateTime date) async {
    final all = await _loadAll();
    final dateKey = _dateKey(date);
    final dayData = (all[dateKey] as Map<String, dynamic>?) ?? {};
    return List.generate(24, (i) {
      final h = (dayData[i.toString()] as Map<String, dynamic>?) ?? {'good': 0, 'bad': 0};
      return {'good': h['good'] as int, 'bad': h['bad'] as int};
    });
  }

  static Future<List<Map<String, int>>> getWeekData(DateTime anyDay) async {
    final monday = anyDay.subtract(Duration(days: anyDay.weekday - 1));
    final all = await _loadAll();
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final dateKey = _dateKey(day);
      final dayData = (all[dateKey] as Map<String, dynamic>?) ?? {};
      int good = 0, bad = 0;
      dayData.forEach((_, v) {
        final m = v as Map<String, dynamic>;
        good += (m['good'] as int? ?? 0);
        bad += (m['bad'] as int? ?? 0);
      });
      return {'good': good, 'bad': bad};
    });
  }

  static Future<List<Map<String, int>>> getMonthData(int year, int month) async {
    final all = await _loadAll();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(31, (i) {
      if (i >= daysInMonth) return {'good': 0, 'bad': 0};
      final day = DateTime(year, month, i + 1);
      final dateKey = _dateKey(day);
      final dayData = (all[dateKey] as Map<String, dynamic>?) ?? {};
      int good = 0, bad = 0;
      dayData.forEach((_, v) {
        final m = v as Map<String, dynamic>;
        good += (m['good'] as int? ?? 0);
        bad += (m['bad'] as int? ?? 0);
      });
      return {'good': good, 'bad': bad};
    });
  }
}
