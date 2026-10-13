import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const green = Color(0xFF1F6B4A);
const red = Color(0xFFB3321F);

extension NibbleColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get card => isDark ? const Color(0xFF1A241E) : Colors.white;

  Color get muted =>
      isDark ? const Color(0xFF9DB0A4) : const Color(0xFF5B6B62);

  // Accent color used for text and icons (lighter in dark mode so it's readable)
  Color get accentText {
    final primary = Theme.of(this).colorScheme.primary;
    if (!isDark) return primary;
    return primary == red ? const Color(0xFFF4A593) : const Color(0xFF6FD9A5);
  }
}

ThemeData buildTheme({required bool late, required Brightness brightness}) {
  final dark = brightness == Brightness.dark;
  final accent = late ? red : green;
  final bg = dark
      ? (late ? const Color(0xFF1A100E) : const Color(0xFF101712))
      : (late ? const Color(0xFFFBF1EE) : const Color(0xFFF3F5EF));
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
        .copyWith(primary: accent),
    scaffoldBackgroundColor: bg,
  );
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () =>
          Hive.box('settings').put('theme', dark ? 'light' : 'dark'),
    );
  }
}