class Subscription {
  final String id;
  final String title;
  final double amount;
  final String category;
  final int billingDay;
  final String color;
  final String? creditCardId;
  final String? creditCardName;
  final String? lastChargedMonth;

  Subscription({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.billingDay,
    required this.color,
    required this.creditCardId,
    required this.creditCardName,
    this.lastChargedMonth,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'billingDay': billingDay,
    'color': color,
    'creditCardId': creditCardId,
    'creditCardName': creditCardName,
    'lastChargedMonth': lastChargedMonth,
  };

  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
    id: map['id'],
    title: map['title'],
    amount: map['amount'],
    category: map['category'],
    billingDay: map['billingDay'],
    color: map['color'],
    creditCardId: map['creditCardId'] as String?,
    creditCardName: map['creditCardName'] as String?,
    lastChargedMonth: map['lastChargedMonth'] as String?,
  );
}
