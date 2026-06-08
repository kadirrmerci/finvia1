import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'notification_service.dart';

class StockAlert {
  final String symbol;
  final String name;
  final double targetPrice;
  final bool isAbove;

  StockAlert({
    required this.symbol,
    required this.name,
    required this.targetPrice,
    required this.isAbove,
  });
}

class StockAlertService {
  static final StockAlertService _instance = StockAlertService._internal();
  factory StockAlertService() => _instance;
  StockAlertService._internal();

  final List<StockAlert> _alerts = [];
  Timer? _timer;
  final _notif = NotificationService();

  void addAlert(StockAlert alert) {
    _alerts.removeWhere((a) => a.symbol == alert.symbol);
    _alerts.add(alert);
    _startMonitoring();
  }

  void removeAlert(String symbol) {
    _alerts.removeWhere((a) => a.symbol == symbol);
  }

  List<StockAlert> get alerts => List.unmodifiable(_alerts);

  void _startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _checkAlerts());
  }

  Future<void> _checkAlerts() async {
    final triggeredAlerts = <StockAlert>[];
    for (var alert in List.from(_alerts)) {
      final price = await _getPrice(alert.symbol);
      if (price == null) continue;

      if (alert.isAbove && price >= alert.targetPrice) {
        await _notif.checkStockAlarm(
          symbol: alert.symbol,
          companyName: alert.name,
          currentPrice: price,
          targetPrice: alert.targetPrice,
          isUpperAlarm: true,
        );
        triggeredAlerts.add(alert);
      } else if (!alert.isAbove && price <= alert.targetPrice) {
        await _notif.checkStockAlarm(
          symbol: alert.symbol,
          companyName: alert.name,
          currentPrice: price,
          targetPrice: alert.targetPrice,
          isUpperAlarm: false,
        );
        triggeredAlerts.add(alert);
      }
    }
    for (var alert in triggeredAlerts) {
      _alerts.remove(alert);
    }
  }

  Future<double?> _getPrice(String symbol) async {
    try {
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chart']['result'][0]['meta']['regularMarketPrice']
            ?.toDouble();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void dispose() {
    _timer?.cancel();
  }
}
