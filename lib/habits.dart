import 'package:hive_flutter/hive_flutter.dart';
import 'models/meal_log.dart';

const leadMinutes = 10; // remind this long before your usual time

/// Typical time of day (minutes after midnight) for a meal,
/// or null if there isn't enough data yet.
int? typicalMinutes(MealType type, {int days = 14, int minLogs = 3}) {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  final mins = Hive.box('meals')
      .values
      .map((m) => MealLog.fromMap(m as Map))
      .where((m) => m.type == type && m.time.isAfter(cutoff))
      .map((m) => m.time.hour * 60 + m.time.minute)
      .toList()
    ..sort();
  if (mins.length < minLogs) return null;
  return mins[mins.length ~/ 2]; // the median
}

String formatMinutes(int mins) {
  final h = mins ~/ 60;
  final m = mins % 60;
  final suffix = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $suffix';
}