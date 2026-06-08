class Habit {
  final String id;
  final String title;
  final String type;
  final DateTime startDate;
  final List<DateTime> completedDays;
  final String emoji;
  final String motivation;

  Habit({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.completedDays,
    required this.emoji,
    required this.motivation,
  });

  int get currentStreak {
    if (completedDays.isEmpty) return 0;
    final sorted = completedDays..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime.now();
    for (var day in sorted) {
      if (day.year == check.year &&
          day.month == check.month &&
          day.day == check.day) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool isTodayCompleted() {
    final today = DateTime.now();
    return completedDays.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type,
    'startDate': startDate.toIso8601String(),
    'completedDays': completedDays.map((d) => d.toIso8601String()).join(','),
    'emoji': emoji,
    'motivation': motivation,
  };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    id: map['id'],
    title: map['title'],
    type: map['type'],
    startDate: DateTime.parse(map['startDate']),
    completedDays:
        map['completedDays'] != null && map['completedDays'].isNotEmpty
        ? (map['completedDays'] as String)
              .split(',')
              .map((d) => DateTime.parse(d))
              .toList()
        : [],
    emoji: map['emoji'],
    motivation: map['motivation'],
  );

  Habit copyWith({List<DateTime>? completedDays}) => Habit(
    id: id,
    title: title,
    type: type,
    startDate: startDate,
    completedDays: completedDays ?? this.completedDays,
    emoji: emoji,
    motivation: motivation,
  );
}
