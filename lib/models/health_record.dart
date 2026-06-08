class HealthRecord {
  final String id;
  final double weight;
  final DateTime date;
  final String? note;

  HealthRecord({
    required this.id,
    required this.weight,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'weight': weight,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory HealthRecord.fromMap(Map<String, dynamic> map) => HealthRecord(
    id: map['id'],
    weight: map['weight'],
    date: DateTime.parse(map['date']),
    note: map['note'],
  );
}
