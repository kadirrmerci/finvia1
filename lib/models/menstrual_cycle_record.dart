class MenstrualCycleRecord {
  final String id;
  final DateTime periodStart;
  final int cycleLength;
  final int periodLength;
  final String? note;

  MenstrualCycleRecord({
    required this.id,
    required this.periodStart,
    required this.cycleLength,
    required this.periodLength,
    this.note,
  });

  DateTime get nextPeriodStart => periodStart.add(Duration(days: cycleLength));
  DateTime get ovulationDate =>
      nextPeriodStart.subtract(const Duration(days: 14));
  DateTime get fertileStart => ovulationDate.subtract(const Duration(days: 5));
  DateTime get fertileEnd => ovulationDate.add(const Duration(days: 1));

  Map<String, dynamic> toMap() => {
    'id': id,
    'periodStart': periodStart.toIso8601String(),
    'cycleLength': cycleLength,
    'periodLength': periodLength,
    'note': note,
  };

  factory MenstrualCycleRecord.fromMap(Map<String, dynamic> map) =>
      MenstrualCycleRecord(
        id: map['id'],
        periodStart: DateTime.parse(map['periodStart']),
        cycleLength: (map['cycleLength'] as num).toInt(),
        periodLength: (map['periodLength'] as num).toInt(),
        note: map['note'],
      );
}
