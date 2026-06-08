class Subscription {
  final String id;
  final String title;
  final double amount;
  final String category;
  final int billingDay;
  final String color;

  Subscription({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.billingDay,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'billingDay': billingDay,
    'color': color,
  };

  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
    id: map['id'],
    title: map['title'],
    amount: map['amount'],
    category: map['category'],
    billingDay: map['billingDay'],
    color: map['color'],
  );
}
