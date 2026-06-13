import '../models/health_record.dart';
import '../models/stock_holding.dart';
import '../models/transaction.dart';
import 'database_service.dart';

class PuzzleProgress {
  const PuzzleProgress({
    required this.totalPieces,
    required this.financePieces,
    required this.investmentPieces,
    required this.healthPieces,
  });

  final int totalPieces;
  final int financePieces;
  final int investmentPieces;
  final int healthPieces;

  int get earnedPieces => financePieces + investmentPieces + healthPieces;
  int get visiblePieces => earnedPieces % totalPieces;
  int get completedBoards => earnedPieces ~/ totalPieces;
  double get progress => visiblePieces / totalPieces;
}

class PuzzleProgressService {
  PuzzleProgressService(this._db);

  final DatabaseService _db;

  Future<PuzzleProgress> calculate() async {
    try {
      final results = await Future.wait([
        _db.getTransactions(),
        _db.getHoldings(),
        _db.getHealthRecords(),
      ]).timeout(const Duration(seconds: 4));

      return PuzzleProgress(
        totalPieces: 10000,
        financePieces: _financePieces(results[0] as List<FinanceTransaction>),
        investmentPieces: _investmentPieces(results[1] as List<StockHolding>),
        healthPieces: _healthPieces(results[2] as List<HealthRecord>),
      );
    } catch (_) {
      return const PuzzleProgress(
        totalPieces: 10000,
        financePieces: 0,
        investmentPieces: 0,
        healthPieces: 0,
      );
    }
  }

  int _financePieces(List<FinanceTransaction> transactions) {
    final now = DateTime.now();
    final monthTransactions = transactions.where(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );
    final income = monthTransactions
        .where((t) => !t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = monthTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    if (income <= 0) return 0;
    final savingsRate = ((income - expense) / income) * 100;
    return savingsRate > 0 ? (savingsRate * 10).floor() : 0;
  }

  int _investmentPieces(List<StockHolding> holdings) {
    final profit = holdings.fold<double>(
      0,
      (sum, holding) => sum + (holding.profitLoss > 0 ? holding.profitLoss : 0),
    );
    return profit.floor();
  }

  int _healthPieces(List<HealthRecord> records) {
    final bodyFatRecords =
        records
            .where((r) => r.bodyFatPercentage != null)
            .toList(growable: false)
          ..sort((a, b) => a.date.compareTo(b.date));
    var pieces = 0;
    for (var i = 1; i < bodyFatRecords.length; i++) {
      final previous = bodyFatRecords[i - 1].bodyFatPercentage!;
      final current = bodyFatRecords[i].bodyFatPercentage!;
      final delta = previous - current;
      pieces += (delta * 10).floor();
    }
    return pieces < 0 ? 0 : pieces;
  }
}
