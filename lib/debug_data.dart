import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/meal_log.dart';

/// Fills the last 6 days (not today) with realistic-looking meals.
/// Debug use only.
void loadSampleWeek() {
  final box = Hive.box('meals');
  final rnd = Random();
  final today = DateTime.now();

  for (var back = 6; back >= 1; back--) {
    final day = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: back));

    void add(MealType type, int baseMinutes, int spread, {String? note}) {
      final mins = baseMinutes + rnd.nextInt(spread * 2 + 1) - spread;
      final time = day.add(Duration(minutes: mins));
      final id = '${time.microsecondsSinceEpoch}_${type.name}';
      final log = MealLog(
        id: id,
        time: time,
        type: type,
        rating: Rating.values[rnd.nextInt(3)],
        note: note,
      );
      box.put(id, log.toMap());
    }

    if (back != 3) add(MealType.breakfast, 8 * 60, 30); // skipped one day
    add(MealType.lunch, 12 * 60 + 30, 45);
    add(MealType.dinner, 19 * 60, 60);
    if (back == 2) add(MealType.snack, 22 * 60 + 30, 15, note: 'Late snack');
  }
}