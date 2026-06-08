class CreditCard {
  final String id;
  final String bankName;
  final String cardName;
  final double creditLimit;
  final double currentDebt;
  final int statementDay;
  final int dueDay;
  final String color;

  CreditCard({
    required this.id,
    required this.bankName,
    required this.cardName,
    required this.creditLimit,
    required this.currentDebt,
    required this.statementDay,
    required this.dueDay,
    this.color = '#6C63FF',
  });

  double get minimumPayment => currentDebt * 0.40;
  double get availableLimit => creditLimit - currentDebt;
  double get usagePercent =>
      creditLimit > 0 ? (currentDebt / creditLimit * 100) : 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'bankName': bankName,
    'cardName': cardName,
    'creditLimit': creditLimit,
    'currentDebt': currentDebt,
    'statementDay': statementDay,
    'dueDay': dueDay,
    'color': color,
  };

  factory CreditCard.fromMap(Map<String, dynamic> map) => CreditCard(
    id: map['id'],
    bankName: map['bankName'],
    cardName: map['cardName'],
    creditLimit: map['creditLimit'],
    currentDebt: map['currentDebt'],
    statementDay: map['statementDay'],
    dueDay: map['dueDay'],
    color: map['color'] ?? '#6C63FF',
  );

  CreditCard copyWith({
    String? bankName,
    String? cardName,
    double? creditLimit,
    double? currentDebt,
    int? statementDay,
    int? dueDay,
    String? color,
  }) => CreditCard(
    id: id,
    bankName: bankName ?? this.bankName,
    cardName: cardName ?? this.cardName,
    creditLimit: creditLimit ?? this.creditLimit,
    currentDebt: currentDebt ?? this.currentDebt,
    statementDay: statementDay ?? this.statementDay,
    dueDay: dueDay ?? this.dueDay,
    color: color ?? this.color,
  );
}

class CreditCardStatement {
  final String id;
  final String cardId;
  final String cardName;
  final double amount;
  double paidAmount;
  final DateTime statementDate;
  final DateTime dueDate;

  CreditCardStatement({
    required this.id,
    required this.cardId,
    required this.cardName,
    required this.amount,
    required this.paidAmount,
    required this.statementDate,
    required this.dueDate,
  });

  double get remainingAmount => amount - paidAmount;
  bool get isPaid => paidAmount >= amount;
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toMap() => {
    'id': id,
    'cardId': cardId,
    'cardName': cardName,
    'amount': amount,
    'paidAmount': paidAmount,
    'statementDate': statementDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
  };

  factory CreditCardStatement.fromMap(Map<String, dynamic> map) =>
      CreditCardStatement(
        id: map['id'],
        cardId: map['cardId'],
        cardName: map['cardName'],
        amount: map['amount'],
        paidAmount: map['paidAmount'],
        statementDate: DateTime.parse(map['statementDate']),
        dueDate: DateTime.parse(map['dueDate']),
      );

  CreditCardStatement copyWith({double? paidAmount}) => CreditCardStatement(
    id: id,
    cardId: cardId,
    cardName: cardName,
    amount: amount,
    paidAmount: paidAmount ?? this.paidAmount,
    statementDate: statementDate,
    dueDate: dueDate,
  );
}
