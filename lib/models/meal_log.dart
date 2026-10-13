enum MealType { breakfast, lunch, dinner, snack }
enum Rating { good, okay, bad }

class MealLog {
  final String id;
  final DateTime time;
  final MealType type;
  final Rating rating;
  final String? note;

  MealLog({
    required this.id,
    required this.time,
    required this.type,
    required this.rating,
    this.note,
  });

  // A meal counts as "late" at or after 10 PM
  bool get isLate => time.hour >= 22;

  Map<String, dynamic> toMap() => {
        'id': id,
        'time': time.toIso8601String(),
        'type': type.name,
        'rating': rating.name,
        'note': note,
      };

  factory MealLog.fromMap(Map map) => MealLog(
        id: map['id'],
        time: DateTime.parse(map['time']),
        type: MealType.values.byName(map['type']),
        rating: Rating.values.byName(map['rating']),
        note: map['note'],
      );
}