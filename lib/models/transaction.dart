class FinanceTransaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense;
  final bool isFixed;
  final String? creditCardId;
  final String? creditCardName;

  FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
    this.isFixed = false,
    this.creditCardId,
    this.creditCardName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isExpense': isExpense ? 1 : 0,
      'isFixed': isFixed ? 1 : 0,
      'creditCardId': creditCardId,
      'creditCardName': creditCardName,
    };
  }

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) {
    return FinanceTransaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      isExpense: map['isExpense'] == 1,
      isFixed: map['isFixed'] == 1,
      creditCardId: map['creditCardId'],
      creditCardName: map['creditCardName'],
    );
  }
}