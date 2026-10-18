import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal_log.dart';
import '../theme.dart'; // for the green color
import '../notifications.dart';

class LogScreen extends StatefulWidget {
  final MealType initialType;
  const LogScreen({super.key, this.initialType = MealType.lunch});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late MealType _type = widget.initialType;
  Rating _rating = Rating.good;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final text = _note.text.trim();
    final log = MealLog(
      id: now.microsecondsSinceEpoch.toString(),
      time: now,
      type: _type,
      rating: _rating,
      note: text.isEmpty ? null : text,
    );
    final box = Hive.box('meals');
    await box.put(log.id, log.toMap());
    if (log.isLate) {
      await showLateWarning(TimeOfDay.fromDateTime(log.time).format(context));
    }
    debugPrint('Saved meals: ${box.length}');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now().format(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Log a meal',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('When', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Now · $now',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Meal', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final t in MealType.values)
                ChoiceChip(
                  label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'How was it?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final r in Rating.values)
                ChoiceChip(
                  label: Text(r.name[0].toUpperCase() + r.name.substring(1)),
                  selected: _rating == r,
                  onSelected: (_) => setState(() => _rating = r),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'What did you eat? (optional)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Rice, grilled chicken, salad',
              filled: true,
              fillColor: context.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _save,
              child: const Text(
                'Save meal',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
