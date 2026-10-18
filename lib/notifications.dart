import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'habits.dart';
import 'models/meal_log.dart';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  try {
    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      windows: const WindowsInitializationSettings(
        appName: 'Nibble',
        appUserModelId: 'Nibble.MealReminder.App.1',
        guid: 'b3f1c2a4-5d6e-4f70-8a91-2c3d4e5f6a7b',
      ),
    );
    await _plugin.initialize(settings: settings);
  } catch (e) {
    debugPrint('Notification setup failed: $e');
  }
}

Future<void> showLateWarning(String time) async {
  try {
    await _plugin.show(
      id: 1,
      title: 'Late-night meal spotted',
      body: '$time is a late time to eat. This is a habit worth changing.',
      notificationDetails: NotificationDetails(
        android: const AndroidNotificationDetails(
          'late_night',
          'Late-night warnings',
          importance: Importance.high,
        ),
        windows: const WindowsNotificationDetails(),
      ),
    );
  } catch (e) {
    debugPrint('Could not show notification: $e');
  }
}

Future<void> requestNotificationPermission() async {
  try {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  } catch (e) {
    debugPrint('Permission request failed: $e');
  }
}

NotificationDetails _mealDetails() => NotificationDetails(
      android: const AndroidNotificationDetails(
        'meal_reminders',
        'Meal reminders',
        importance: Importance.high,
      ),
      windows: const WindowsNotificationDetails(),
    );

Future<void> scheduleReminders() async {
  try {
    final now = DateTime.now();
    final loggedToday = Hive.box('meals')
        .values
        .map((m) => MealLog.fromMap(m as Map))
        .where((m) =>
            m.time.year == now.year &&
            m.time.month == now.month &&
            m.time.day == now.day)
        .map((m) => m.type)
        .toSet();

    for (final type in [MealType.breakfast, MealType.lunch, MealType.dinner]) {
      final typical = typicalMinutes(type);
      for (var day = 0; day < 3; day++) {
        final id = 100 + type.index * 10 + day;
        await _plugin.cancel(id: id);
        if (typical == null) continue;
        if (day == 0 && loggedToday.contains(type)) continue;

        final base = DateTime(now.year, now.month, now.day + day);
        final when = base.add(Duration(minutes: typical - leadMinutes));
        if (!when.isAfter(now)) continue;

        await _plugin.zonedSchedule(
          id: id,
          title: 'Time for ${type.name}',
          body: 'You usually eat around ${formatMinutes(typical)}.',
          scheduledDate: tz.TZDateTime.from(when, tz.UTC),
          notificationDetails: _mealDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  } catch (e) {
    debugPrint('Scheduling failed: $e');
  }
}

/// Debug helper: a reminder 1 minute from now.
Future<void> scheduleTest() async {
  try {
    await _plugin.zonedSchedule(
      id: 999,
      title: 'Test reminder',
      body: 'Scheduled notifications are working.',
      scheduledDate: tz.TZDateTime.from(
          DateTime.now().add(const Duration(minutes: 1)), tz.UTC),
      notificationDetails: _mealDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  } catch (e) {
    debugPrint('Test scheduling failed: $e');
  }
}