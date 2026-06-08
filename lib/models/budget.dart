class Budget {
  final String id;
  final String category;
  final double limitAmount;
  final String month;

  Budget({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.month,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'limitAmount': limitAmount,
    'month': month,
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'],
    category: map['category'],
    limitAmount: map['limitAmount'],
    month: map['month'],
  );
}
