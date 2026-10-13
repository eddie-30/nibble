import 'log_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal_log.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../habits.dart';

const muted = Color(0xFF5B6B62);

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String dateLabel(DateTime d) =>
    '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

String cap(String s) => s[0].toUpperCase() + s.substring(1);

void deleteMeal(BuildContext context, MealLog m) {
  final box = Hive.box('meals');
  final saved = box.get(m.id);
  box.delete(m.id);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        persist: false,
        duration: const Duration(seconds: 4),
        content: const Text('Meal deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => box.put(m.id, saved),
        ),
      ),
    );
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            Hive.box('meals').listenable(),
            Hive.box('settings').listenable(),
          ]),
          builder: (context, _) {
            final box = Hive.box('meals');
            final now = DateTime.now();
            final meals =
                box.values
                    .map((m) => MealLog.fromMap(m as Map))
                    .where(
                      (m) =>
                          m.time.year == now.year &&
                          m.time.month == now.month &&
                          m.time.day == now.day,
                    )
                    .toList()
                  ..sort((a, b) => a.time.compareTo(b.time));
            final logged = meals.map((m) => m.type).toSet();
            final next = [
              MealType.breakfast,
              MealType.lunch,
              MealType.dinner,
            ].where((t) => !logged.contains(t)).firstOrNull;
            final lateMeals = meals.where((m) => m.isLate).toList();
            final todayKey = '${now.year}-${now.month}-${now.day}';
            final dismissed =
                Hive.box('settings').get('lateDismissed') == todayKey;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel(now),
                            style: TextStyle(
                              color: context.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ThemeToggle(),
                  ],
                ),
                const SizedBox(height: 20),
                lateMeals.isNotEmpty && !dismissed
                    ? LateCard(
                        meal: lateMeals.last,
                        onDismiss: () =>
                            Hive.box('settings').put('lateDismissed', todayKey),
                      )
                    : NextUpCard(next: next),
                const SizedBox(height: 20),
                const Text(
                  "Today's meals",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (meals.isEmpty)
                  Text(
                    'Nothing logged yet today.',
                    style: TextStyle(color: context.muted),
                  ),
                for (final m in meals)
                  Dismissible(
                    key: ValueKey(m.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.only(right: 24),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: red,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) => deleteMeal(context, m),
                    child: MealRow(
                      title: cap(m.type.name),
                      subtitle:
                          '${TimeOfDay.fromDateTime(m.time).format(context)}'
                          '${m.note != null ? ' · ${m.note}' : ''}',
                      chip: m.isLate ? 'Late' : cap(m.rating.name),
                      done: true,
                      onDelete: () => deleteMeal(context, m),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NextUpCard extends StatelessWidget {
  final MealType? next;
  const NextUpCard({super.key, this.next});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final done = next == null;
    final typical = done ? null : typicalMinutes(next!);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            done ? 'ALL DONE' : 'NEXT UP',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            done ? 'Nice work today' : cap(next!.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            done
                ? 'You have logged all three main meals.'
                : typical == null
                ? 'Tap below when you eat.'
                : 'You usually eat ${next!.name} around ${formatMinutes(typical)}. '
                      'Reminder at ${formatMinutes(typical - leadMinutes)}.',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LogScreen(initialType: next ?? MealType.snack),
                ),
              ),
              child: Text(
                done ? 'Log a snack' : 'Log ${next!.name}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealRow extends StatelessWidget {
  final String title, subtitle, chip;
  final bool done;
  final VoidCallback? onDelete;

  const MealRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chip,
    this.done = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentText;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.schedule,
            color: done ? accent : Colors.grey,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: TextStyle(fontSize: 13, color: muted)),
              ],
            ),
          ),
          Text(
            chip,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: done ? accent : Colors.grey[700],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete meal',
              icon: const Icon(Icons.delete_outline, size: 20),
              color: context.muted,
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class LateCard extends StatelessWidget {
  final MealLog meal;
  final VoidCallback onDismiss;
  const LateCard({super.key, required this.meal, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final time = TimeOfDay.fromDateTime(meal.time).format(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LATE-NIGHT MEAL',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onDismiss,
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Eating this close to bedtime can disrupt your sleep. '
            "It's a habit worth changing.",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
