import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/daily_log_model.dart';

final logProvider = StateNotifierProvider<LogNotifier, AsyncValue<void>>((ref) {
  return LogNotifier(ref);
});

class LogNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  LogNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> saveLog(DailyLog log) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load existing logs
      final existing = prefs.getString('daily_logs');
      final Map<String, dynamic> logsMap = existing != null
          ? Map<String, dynamic>.from(jsonDecode(existing))
          : {};

      // Save/overwrite log for that day
      logsMap[log.id] = log.toFirestore();
      await prefs.setString('daily_logs', jsonEncode(logsMap));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<DailyLog>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('daily_logs');
      if (existing == null) return [];

      final Map<String, dynamic> logsMap =
          Map<String, dynamic>.from(jsonDecode(existing));

      final logs =
          logsMap.entries.map((e) => DailyLog.fromMap(e.key, e.value)).toList();

      // Sort by date descending
      logs.sort((a, b) => b.date.compareTo(a.date));
      return logs.take(90).toList();
    } catch (e) {
      return [];
    }
  }
}
