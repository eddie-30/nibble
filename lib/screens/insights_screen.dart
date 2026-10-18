import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal_log.dart';
import '../theme.dart';
import 'package:flutter/foundation.dart';
import '../debug_data.dart';
import '../notifications.dart';

const _amber = Color(0xFFE6BC6A);
const _redish = Color(0xFFC8553D);
const _longGapHours = 6;
const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtGap(Duration d) => '${d.inHours}h ${d.inMinutes % 60}m';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box('meals').listenable(),
          builder: (context, Box box, _) {
            final cutoff = DateTime.now().subtract(const Duration(days: 7));
            final meals = box.values
                .map((m) => MealLog.fromMap(m as Map))
                .where((m) => m.time.isAfter(cutoff))
                .toList();

            int count(Rating r) => meals.where((m) => m.rating == r).length;
            final good = count(Rating.good);
            final okay = count(Rating.okay);
            final bad = count(Rating.bad);

            // Group meals by calendar day
            final days = <String, List<MealLog>>{};
            for (final m in meals) {
              final key = '${m.time.year}-${m.time.month}-${m.time.day}';
              days.putIfAbsent(key, () => []).add(m);
            }
            final skippedBreakfast = days.values
                .where((d) => !d.any((m) => m.type == MealType.breakfast))
                .length;
            final lateCount = meals.where((m) => m.isLate).length;
            final today = DateTime.now();
            final week = [
              for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
            ];

            // 0 = no data, 1 = on schedule, 2 = off schedule
            final status = <int>[];
            for (final d in week) {
              final day = meals.where((m) => _sameDay(m.time, d)).toList();
              if (day.isEmpty) {
                status.add(0);
                continue;
              }
              final types = day.map((m) => m.type).toSet();
              final complete = types.containsAll([
                MealType.breakfast,
                MealType.lunch,
                MealType.dinner,
              ]);
              final hasLate = day.any((m) => m.isLate);
              if (complete && !hasLate) {
                status.add(1);
              } else if (hasLate || !_sameDay(d, today)) {
                status.add(2);
              } else {
                status.add(0); // today, still in progress
              }
            }
            final onSchedule = status.where((s) => s == 1).length;
            final tracked = status.where((s) => s != 0).length;

            // Longest gap between two meals on the same day
            Duration? longest;
            var longestLabel = '';
            for (final d in week) {
              final day = meals.where((m) => _sameDay(m.time, d)).toList()
                ..sort((a, b) => a.time.compareTo(b.time));
              for (var i = 1; i < day.length; i++) {
                final gap = day[i].time.difference(day[i - 1].time);
                if (longest == null || gap > longest) {
                  longest = gap;
                  longestLabel =
                      '${day[i - 1].type.name} and ${day[i].type.name} on ${_dayNames[d.weekday - 1]}';
                }
              }
            }
            final longGap = longest != null && longest.inHours >= _longGapHours;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Last 7 days',
                  style: TextStyle(
                    color: context.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Insights',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                if (meals.isEmpty)
                  Text(
                    'Log a few meals and your insights will show up here.',
                    style: TextStyle(color: context.muted),
                  ),
                if (meals.isNotEmpty) ...[
                  _card(
                    context,
                    'Eating rhythm',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              tracked == 0 ? '–' : '$onSchedule of $tracked',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: context.accentText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'days on schedule',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (var i = 0; i < week.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: status[i] == 1
                                              ? green
                                              : status[i] == 2
                                              ? _amber
                                              : context.muted.withValues(
                                                  alpha: 0.3,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _dayLetters[week[i].weekday - 1],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Green: all three meals, nothing after 10 PM. Amber: missed one or ate late. Grey: no data.',
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    context,
                    'How your meals felt',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Row(
                            children: [
                              if (good > 0)
                                Expanded(
                                  flex: good,
                                  child: Container(height: 14, color: green),
                                ),
                              if (okay > 0)
                                Expanded(
                                  flex: okay,
                                  child: Container(height: 14, color: _amber),
                                ),
                              if (bad > 0)
                                Expanded(
                                  flex: bad,
                                  child: Container(height: 14, color: _redish),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Good $good',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Okay $okay',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Bad $bad',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Worth a look',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (skippedBreakfast > 0)
                    _tile(
                      context,
                      'Skipped breakfast',
                      'No breakfast logged on $skippedBreakfast of ${days.length} days.',
                    ),
                  if (lateCount > 0)
                    _tile(
                      context,
                      'Late-night meals',
                      '$lateCount meal${lateCount == 1 ? '' : 's'} logged after 10 PM.',
                    ),
                  if (longGap)
                    _tile(
                      context,
                      'Long gap between meals',
                      '${_fmtGap(longest)} between $longestLabel',
                    ),
                  if (skippedBreakfast == 0 && lateCount == 0 && !longGap)
                    _tile(
                      context,
                      'Nothing to flag',
                      'Your week looks steady so far.',
                    ),
                ],
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Debug tools',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.muted,
                    ),
                  ),
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: loadSampleWeek,
                        child: const Text('Load sample week'),
                      ),
                      TextButton(
                        onPressed: () => Hive.box('meals').clear(),
                        child: const Text('Clear all meals'),
                      ),
                      TextButton(
                        onPressed: () => showLateWarning('11:02 PM'),
                        child: const Text('Test warning'),
                      ),
                      TextButton(
                        onPressed: scheduleTest,
                        child: const Text('Remind in 1 min'),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.card,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _tile(BuildContext context, String title, String body) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.card,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(body, style: TextStyle(fontSize: 14, color: context.muted)),
      ],
    ),
  );
}
