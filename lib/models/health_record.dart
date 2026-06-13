class HealthRecord {
  final String id;
  final double weight;
  final DateTime date;
  final String? note;
  final double? height;
  final double? waist;
  final double? neck;
  final double? hip;
  final double? shoulder;
  final double? chest;
  final double? arm;
  final double? thigh;
  final double? calf;
  final String? gender;
  final double? bodyFatPercentage;
  final double? ffmi;

  HealthRecord({
    required this.id,
    required this.weight,
    required this.date,
    this.note,
    this.height,
    this.waist,
    this.neck,
    this.hip,
    this.shoulder,
    this.chest,
    this.arm,
    this.thigh,
    this.calf,
    this.gender,
    this.bodyFatPercentage,
    this.ffmi,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'weight': weight,
    'date': date.toIso8601String(),
    'note': note,
    'height': height,
    'waist': waist,
    'neck': neck,
    'hip': hip,
    'shoulder': shoulder,
    'chest': chest,
    'arm': arm,
    'thigh': thigh,
    'calf': calf,
    'gender': gender,
    'bodyFatPercentage': bodyFatPercentage,
    'ffmi': ffmi,
  };

  factory HealthRecord.fromMap(Map<String, dynamic> map) => HealthRecord(
    id: map['id'],
    weight: (map['weight'] as num).toDouble(),
    date: DateTime.parse(map['date']),
    note: map['note'],
    height: (map['height'] as num?)?.toDouble(),
    waist: (map['waist'] as num?)?.toDouble(),
    neck: (map['neck'] as num?)?.toDouble(),
    hip: (map['hip'] as num?)?.toDouble(),
    shoulder: (map['shoulder'] as num?)?.toDouble(),
    chest: (map['chest'] as num?)?.toDouble(),
    arm: (map['arm'] as num?)?.toDouble(),
    thigh: (map['thigh'] as num?)?.toDouble(),
    calf: (map['calf'] as num?)?.toDouble(),
    gender: map['gender'],
    bodyFatPercentage: (map['bodyFatPercentage'] as num?)?.toDouble(),
    ffmi: (map['ffmi'] as num?)?.toDouble(),
  );
}
