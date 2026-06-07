class Debt {
  final String id;
  final String title;
  final double totalAmount;
  final double paidAmount;
  final double monthlyPayment;
  final DateTime startDate;
  final double interestRate;

  Debt({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.paidAmount,
    required this.monthlyPayment,
    required this.startDate,
    this.interestRate = 0,
  });

  double get remainingAmount => totalAmount - paidAmount;
  int get remainingMonths =>
      monthlyPayment > 0 ? (remainingAmount / monthlyPayment).ceil() : 0;
  DateTime get estimatedEndDate =>
      startDate.add(Duration(days: remainingMonths * 30));

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'monthlyPayment': monthlyPayment,
    'startDate': startDate.toIso8601String(),
    'interestRate': interestRate,
  };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
    id: map['id'],
    title: map['title'],
    totalAmount: map['totalAmount'],
    paidAmount: map['paidAmount'],
    monthlyPayment: map['monthlyPayment'],
    startDate: DateTime.parse(map['startDate']),
    interestRate: map['interestRate'],
  );
}