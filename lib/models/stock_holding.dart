class StockHolding {
  final String id;
  final String symbol;
  final String name;
  final double buyPrice;
  final double quantity;
  final DateTime buyDate;
  double? currentPrice;

  StockHolding({
    required this.id,
    required this.symbol,
    required this.name,
    required this.buyPrice,
    required this.quantity,
    required this.buyDate,
    this.currentPrice,
  });

  double get totalCost => buyPrice * quantity;
  double get currentValue => (currentPrice ?? buyPrice) * quantity;
  double get profitLoss => currentValue - totalCost;
  double get profitLossPercent => (profitLoss / totalCost) * 100;

  double simulateSell(double sellPrice) => (sellPrice - buyPrice) * quantity;

  Map<String, dynamic> toMap() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'buyPrice': buyPrice,
    'quantity': quantity,
    'buyDate': buyDate.toIso8601String(),
  };

  factory StockHolding.fromMap(Map<String, dynamic> map) => StockHolding(
    id: map['id'],
    symbol: map['symbol'],
    name: map['name'],
    buyPrice: map['buyPrice'],
    quantity: map['quantity'],
    buyDate: DateTime.parse(map['buyDate']),
  );
}