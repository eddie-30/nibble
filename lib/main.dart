import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/meal_log.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox('meals');
  await Hive.openBox('settings');
  runApp(const NibbleApp());
}

class NibbleApp extends StatelessWidget {
  const NibbleApp({super.key});

  bool _hasLateMealToday(Box box) {
    final now = DateTime.now();
    return box.values
        .map((m) => MealLog.fromMap(m as Map))
        .any(
          (m) =>
              m.isLate &&
              m.time.year == now.year &&
              m.time.month == now.month &&
              m.time.day == now.day,
        );
  }

  ThemeMode _mode() {
    switch (Hive.box('settings').get('theme')) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system; // until you press the button
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Hive.box('meals').listenable(),
        Hive.box('settings').listenable(),
      ]),
      builder: (context, _) {
        final late = _hasLateMealToday(Hive.box('meals'));
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nibble',
          theme: buildTheme(late: late, brightness: Brightness.light),
          darkTheme: buildTheme(late: late, brightness: Brightness.dark),
          themeMode: _mode(),
          home: const HomeShell(),
        );
      },
    );
  }
}
