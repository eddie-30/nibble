import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../habits.dart';
import '../models/meal_log.dart';
import 'today_screen.dart'; // for muted and cap
import '../theme.dart';


class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.accentText;
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box('meals').listenable(),
          builder: (context, Box box, _) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Learned from your last 14 days',
                    style: TextStyle(
                        color: context.muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Reminders',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                const Text('Your typical times',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                for (final type in [
                  MealType.breakfast,
                  MealType.lunch,
                  MealType.dinner
                ])
                  _row(context, type, accent),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(BuildContext context, MealType type, Color accent) {
    final typical = typicalMinutes(type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.card, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cap(type.name),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                    typical == null
                        ? 'Needs 3 logs to learn'
                        : 'Usually ${formatMinutes(typical)}',
                    style: TextStyle(fontSize: 13, color: context.muted)),
              ],
            ),
          ),
          if (typical != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('REMIND AT',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.muted)),
                Text(formatMinutes(typical - leadMinutes),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: accent)),
              ],
            ),
        ],
      ),
    );
  }
}