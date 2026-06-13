import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction.dart';
import '../../models/subscription.dart';
import '../../models/debt.dart';
import '../../models/budget.dart';
import '../../models/credit_card_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FinanceTransaction> _transactions = [];
  List<Subscription> _subscriptions = [];
  List<Debt> _debts = [];
  List<Budget> _budgets = [];
  List<CreditCard> _creditCards = [];
  final _db = DatabaseService();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _db.applyDueSubscriptionCharges();
    final t = await _db.getTransactions();
    final s = await _db.getSubscriptions();
    final d = await _db.getDebts();
    final b = await _db.getBudgets();
    final c = await _db.getCreditCards();
    setState(() {
      _transactions = t;
      _subscriptions = s;
      _debts = d;
      _budgets = b;
      _creditCards = c;
    });
  }

  double get _totalIncome => _transactions
      .where((t) => !t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);
  double get _totalExpense => _transactions
      .where((t) => t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);
  double get _balance => _totalIncome - _totalExpense;
  double get _totalSubscriptions =>
      _subscriptions.fold(0, (sum, s) => sum + s.amount);
  double get _totalDebt => _debts.fold(0, (sum, d) => sum + d.remainingAmount);
  double get _totalCreditCardDebt =>
      _creditCards.fold(0, (sum, c) => sum + c.currentDebt);
  double get _totalCashExpense => _transactions
      .where((t) => t.isExpense && t.creditCardId == null)
      .fold(0, (sum, t) => sum + t.amount);
  double get _totalExpenseBalance =>
      _totalDebt + _totalCreditCardDebt + _totalCashExpense;
  double get _totalAssets => _totalIncome - _totalExpenseBalance;

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (var t in _transactions.where((t) => t.isExpense)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals;
  }

  Map<String, double> get _monthlyExpenses {
    final Map<String, double> data = {};
    for (var t in _transactions.where((t) => t.isExpense)) {
      final key = DateFormat('MMM yy').format(t.date);
      data[key] = (data[key] ?? 0) + t.amount;
    }
    return data;
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finans',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Genel'),
            Tab(text: 'İşlemler'),
            Tab(text: 'Abonelikler'),
            Tab(text: 'Borçlar'),
            Tab(text: 'Bütçe'),
            Tab(text: 'Kredi Kartlarım'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildTransactions(),
          _buildSubscriptions(),
          _buildDebts(),
          _buildBudget(),
          _buildCreditCards(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMenu() {
    final tab = _tabController.index;
    if (tab == 0 || tab == 1) {
      _showAddTransaction();
    } else if (tab == 2) {
      _showAddSubscription();
    } else if (tab == 3) {
      _showAddDebt();
    } else if (tab == 4) {
      _showAddBudget();
    } else if (tab == 5) {
      _showAddCreditCard();
    }
  }

  // ── GENEL ──────────────────────────────────────────
  Widget _buildOverview() {
    final savingsRate = _totalIncome > 0
        ? ((_totalIncome - _totalExpense) / _totalIncome * 100)
        : 0.0;
    final topCategory = _categoryTotals.entries.isEmpty
        ? null
        : _categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    final today = DateTime.now();
    final thisMonthTx = _transactions.where(
      (t) =>
          t.isExpense &&
          t.date.month == today.month &&
          t.date.year == today.year,
    );
    final dailyAvg = thisMonthTx.isEmpty
        ? 0.0
        : thisMonthTx.fold(0.0, (s, t) => s + t.amount) / today.day;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Toplam Varlık',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '₺${NumberFormat('#,##0.00').format(_totalAssets)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _balanceChip(
                      Icons.arrow_upward,
                      'Gelir',
                      _totalIncome,
                      Colors.greenAccent,
                    ),
                    _balanceChip(
                      Icons.arrow_downward,
                      'Gider',
                      _totalExpenseBalance,
                      Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _expenseBreakdownItem('Borç', _totalDebt),
                      _expenseBreakdownItem('Kart', _totalCreditCardDebt),
                      _expenseBreakdownItem('Nakit', _totalCashExpense),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _infoCard(
                'Tasarruf Oranı',
                '%${savingsRate.toStringAsFixed(1)}',
                Icons.savings,
                Colors.green,
              ),
              _infoCard(
                'En Çok Harcama',
                topCategory?.key ?? '-',
                Icons.category,
                Colors.orange,
              ),
              _infoCard(
                'Günlük Ort.',
                '₺${NumberFormat('#,##0').format(dailyAvg)}',
                Icons.today,
                Colors.blue,
              ),
              _infoCard(
                'Abonelikler',
                '₺${NumberFormat('#,##0.00').format(_totalSubscriptions)}/ay',
                Icons.subscriptions,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_creditCards.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Toplam Kart Borcu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₺${NumberFormat('#,##0.00').format(_totalCreditCardDebt)}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_categoryTotals.isNotEmpty) ...[
            const Text(
              'Harcama Dağılımı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _categoryTotals.entries.toList().asMap().entries.map((
                e,
              ) {
                final colors = [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                  Colors.amber,
                ];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(e.value.key, style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          if (_monthlyExpenses.length > 1) ...[
            const Text(
              'Aylık Harcama Trendi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 180, child: _buildBarChart()),
          ],
          const SizedBox(height: 20),
          if (_debts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Toplam Borç',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₺${NumberFormat('#,##0.00').format(_totalDebt)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _balanceChip(IconData icon, String label, double amount, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          '₺${NumberFormat('#,##0').format(amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _expenseBreakdownItem(String label, double amount) {
    return Text(
      '$label: ₺${NumberFormat('#,##0.00').format(amount)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    final entries = _categoryTotals.entries.toList();
    return entries.asMap().entries.map((e) {
      final percent = _totalExpense > 0
          ? e.value.value / _totalExpense * 100
          : 0.0;
      return PieChartSectionData(
        value: e.value.value,
        color: colors[e.key % colors.length],
        title: '%${percent.toStringAsFixed(0)}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildBarChart() {
    final entries = _monthlyExpenses.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= entries.length) return const SizedBox();
                return Text(
                  entries[idx].key,
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: const Color(0xFF6C63FF),
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── İŞLEMLER ───────────────────────────────────────
  Widget _buildTransactions() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz işlem yok',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              '+ butonuna basarak ekle',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final t = _transactions[index];
        return Dismissible(
          key: Key(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await _db.deleteTransaction(t.id);
            await _loadAll();
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: t.isExpense
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                child: Icon(
                  t.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: t.isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Text(
                t.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.category} • ${DateFormat('dd MMM yyyy').format(t.date)}${t.isFixed ? ' • Zorunlu' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (t.creditCardName != null)
                    Text(
                      '💳 ${t.creditCardName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.purple,
                      ),
                    ),
                ],
              ),
              trailing: Text(
                '${t.isExpense ? '-' : '+'}₺${NumberFormat('#,##0.00').format(t.amount)}',
                style: TextStyle(
                  color: t.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── ABONELİKLER ────────────────────────────────────
  Widget _buildSubscriptions() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aylık Toplam',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '₺${NumberFormat('#,##0.00').format(_totalSubscriptions)}/ay',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _subscriptions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.subscriptions, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Abonelik eklenmedi',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _subscriptions.length,
                  itemBuilder: (context, index) {
                    final s = _subscriptions[index];
                    final daysLeft = _daysUntilBilling(s.billingDay);
                    return Dismissible(
                      key: Key(s.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await NotificationService().cancelNotification(
                          2000 + s.id.hashCode,
                        );
                        await _db.deleteSubscription(s.id);
                        await _loadAll();
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.1),
                            child: Text(
                              s.title[0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            s.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Her ayın ${s.billingDay}. günü • $daysLeft gün kaldı'
                            '${s.creditCardName == null ? '' : ' • ${s.creditCardName}'}',
                          ),
                          trailing: Text(
                            '₺${NumberFormat('#,##0.00').format(s.amount)}',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  int _daysUntilBilling(int billingDay) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, billingDay);
    if (next.isBefore(now)) {
      next = DateTime(now.year, now.month + 1, billingDay);
    }
    return next.difference(now).inDays;
  }

  // ── BORÇLAR ────────────────────────────────────────
  Widget _buildDebts() {
    return Column(
      children: [
        if (_debts.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam Borç',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₺${NumberFormat('#,##0.00').format(_totalDebt)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _debts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Borç eklenmedi',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final d = _debts[index];
                    final progress = d.totalAmount > 0
                        ? d.paidAmount / d.totalAmount
                        : 0.0;
                    return Dismissible(
                      key: Key(d.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await _db.deleteDebt(d.id);
                        await _loadAll();
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    d.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '₺${NumberFormat('#,##0').format(d.remainingAmount)} kaldı',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey.shade200,
                                color: Colors.green,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(progress * 100).toStringAsFixed(0)}% ödendi',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '~${d.remainingMonths} ay kaldı',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tahmini bitiş: ${DateFormat('MMM yyyy').format(d.estimatedEndDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Flexible(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade50,
                                            foregroundColor: Colors.green,
                                            elevation: 0,
                                          ),
                                          onPressed: () => _showPayDebt(d),
                                          icon: const Icon(
                                            Icons.payment,
                                            size: 16,
                                          ),
                                          label: Text(
                                            'Ödeme Yap (₺${NumberFormat('#,##0').format(d.monthlyPayment)})',
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            foregroundColor: Colors.blue,
                                            elevation: 0,
                                          ),
                                          onPressed: () => _showExtraPayment(d),
                                          icon: const Icon(
                                            Icons.add_card,
                                            size: 16,
                                          ),
                                          label: const Text('Ara Ödeme Yap'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _showEditDebt(d),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Düzenle'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showPayDebt(Debt d) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${d.title} Ödemesi'),
        content: Text(
          '₺${NumberFormat('#,##0.00').format(d.monthlyPayment)} ödeme yapılsın mı?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final updated = Debt(
                id: d.id,
                title: d.title,
                totalAmount: d.totalAmount,
                paidAmount: d.paidAmount + d.monthlyPayment,
                monthlyPayment: d.monthlyPayment,
                startDate: d.startDate,
                interestRate: d.interestRate,
              );
              await _db.updateDebt(updated);
              final t = FinanceTransaction(
                id: _uuid.v4(),
                title: '${d.title} Borç Ödemesi',
                amount: d.monthlyPayment,
                category: 'Borç Ödemesi',
                date: DateTime.now(),
                isExpense: false,
                isFixed: false,
              );
              await _db.insertTransaction(t);
              await _loadAll();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  void _showExtraPayment(Debt d) {
    final amountController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${d.title} Ara Ödemesi'),
          content: TextField(
            controller: amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Ara ödeme tutarı (₺)',
              hintText:
                  'Kalan: ₺${NumberFormat('#,##0.00').format(d.remainingAmount)}',
              errorText: errorText,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amount = double.tryParse(
                  amountController.text.trim().replaceAll(',', '.'),
                );
                if (amount == null || amount <= 0) {
                  setDialogState(
                    () => errorText = 'Sıfırdan büyük geçerli bir tutar girin.',
                  );
                  return;
                }
                if (amount > d.remainingAmount) {
                  setDialogState(
                    () => errorText = 'Ara ödeme kalan borcu aşamaz.',
                  );
                  return;
                }

                final updated = Debt(
                  id: d.id,
                  title: d.title,
                  totalAmount: d.totalAmount,
                  paidAmount: d.paidAmount + amount,
                  monthlyPayment: d.monthlyPayment,
                  startDate: d.startDate,
                  interestRate: d.interestRate,
                );
                await _db.updateDebt(updated);
                final transaction = FinanceTransaction(
                  id: _uuid.v4(),
                  title: '${d.title} Ara Ödemesi',
                  amount: amount,
                  category: 'Borç Ödemesi',
                  date: DateTime.now(),
                  isExpense: false,
                  isFixed: false,
                );
                await _db.insertTransaction(transaction);
                await _loadAll();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    ).whenComplete(amountController.dispose);
  }

  // ── BÜTÇE ──────────────────────────────────────────
  Widget _buildBudget() {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final monthBudgets = _budgets
        .where((b) => b.month == currentMonth)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (monthBudgets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.pie_chart, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Bütçe hedefi eklenmedi',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ...monthBudgets.map((b) {
              final spent = _categoryTotals[b.category] ?? 0;
              final progress = b.limitAmount > 0
                  ? (spent / b.limitAmount).clamp(0.0, 1.0)
                  : 0.0;
              final isOver = spent > b.limitAmount;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isOver)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⚠️ ₺${(spent - b.limitAmount).toStringAsFixed(2)} aşıldı!',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          PopupMenuButton<String>(
                            tooltip: 'Bütçe işlemleri',
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showBudgetForm(budget: b);
                              } else if (value == 'delete') {
                                _confirmDeleteBudget(b);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Düzenle'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Sil',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        color: isOver ? Colors.red : const Color(0xFF6C63FF),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₺${NumberFormat('#,##0').format(spent)} harcandı',
                            style: TextStyle(
                              color: isOver ? Colors.red : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Limit: ₺${NumberFormat('#,##0').format(b.limitAmount)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── KREDİ KARTLARIM ────────────────────────────────
  Widget _buildCreditCards() {
    if (_creditCards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz kart eklenmedi',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              '+ butonuna basarak ekle',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Kart Borcu',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '₺${NumberFormat('#,##0.00').format(_totalCreditCardDebt)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _creditCards.length,
            itemBuilder: (context, index) {
              final card = _creditCards[index];
              final usagePercent = card.usagePercent.clamp(0.0, 100.0);
              final color = _hexToColor(card.color);
              return Dismissible(
                key: Key(card.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await _db.deleteCreditCard(card.id);
                  await _loadAll();
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  card.bankName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const Icon(
                                  Icons.credit_card,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card.cardName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Güncel Borç',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '₺${NumberFormat('#,##0.00').format(card.currentDebt)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Limit',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '₺${NumberFormat('#,##0.00').format(card.creditLimit)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: usagePercent / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: usagePercent > 80
                                  ? Colors.red
                                  : usagePercent > 50
                                  ? Colors.orange
                                  : Colors.green,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kullanım: %${usagePercent.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Müsait: ₺${NumberFormat('#,##0').format(card.availableLimit)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ekstre: Her ayın ${card.statementDay}. günü',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Son ödeme: ${card.dueDay}. gün',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (card.currentDebt > 0) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Asgari Ödeme (%40)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        Text(
                                          '₺${NumberFormat('#,##0.00').format(card.minimumPayment)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () => _showPayCreditCard(
                                            card,
                                            isMinimum: true,
                                          ),
                                          child: const Text(
                                            'Asgari Öde',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF6C63FF,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () => _showPayCreditCard(
                                            card,
                                            isMinimum: false,
                                          ),
                                          child: const Text(
                                            'Manuel Öde',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.history, size: 16),
                                label: const Text('Ekstre Geçmişi'),
                                onPressed: () => _showStatements(card),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.receipt_long, size: 16),
                                label: const Text('Ekstre tutarı güncelle'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6C63FF),
                                ),
                                onPressed: () => _showAddStatement(card),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPayCreditCard(CreditCard card, {required bool isMinimum}) {
    final amountC = TextEditingController(
      text: isMinimum ? card.minimumPayment.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMinimum ? 'Asgari Ödeme' : 'Manuel Ödeme',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${card.bankName} - ${card.cardName}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountC,
              keyboardType: TextInputType.number,
              readOnly: isMinimum,
              decoration: InputDecoration(
                labelText: 'Ödeme Tutarı (₺)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixText: isMinimum ? '%40' : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final amount =
                      double.tryParse(amountC.text.replaceAll(',', '.')) ?? 0;
                  if (amount <= 0) return;
                  final newDebt = (card.currentDebt - amount)
                      .clamp(0.0, double.infinity)
                      .toDouble();
                  final updatedCard = card.copyWith(currentDebt: newDebt);
                  await _db.updateCreditCard(updatedCard);
                  final t = FinanceTransaction(
                    id: _uuid.v4(),
                    title: '${card.bankName} ${card.cardName} Ödemesi',
                    amount: amount,
                    category: 'Kredi Kartı Ödemesi',
                    date: DateTime.now(),
                    isExpense: true,
                    isFixed: false,
                  );
                  await _db.insertTransaction(t);
                  await _loadAll();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Ödemeyi Onayla',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStatement(CreditCard card) {
    final amountC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${card.bankName} - ${card.cardName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Ekstre Tutarını Güncelle',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Ekstre Tutarı (₺)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 Ekstre tutarı girilince kart borcunuz güncellenecek ve asgari ödeme (%40) otomatik hesaplanacak.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final amount =
                      double.tryParse(amountC.text.replaceAll(',', '.')) ?? 0;
                  if (amount <= 0) return;
                  final now = DateTime.now();
                  final dueDate = DateTime(now.year, now.month, card.dueDay);
                  final statement = CreditCardStatement(
                    id: _uuid.v4(),
                    cardId: card.id,
                    cardName: '${card.bankName} ${card.cardName}',
                    amount: amount,
                    paidAmount: 0,
                    statementDate: now,
                    dueDate: dueDate,
                  );
                  await _db.insertStatement(statement);
                  final updated = card.copyWith(currentDebt: amount);
                  await _db.updateCreditCard(updated);
                  await _loadAll();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Ekstre Tutarını Güncelle',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatements(CreditCard card) async {
    final statements = await _db.getStatements(card.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '${card.bankName} - ${card.cardName} Geçmişi',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (statements.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Henüz ekstre yok',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: statements.length,
                    itemBuilder: (context, index) {
                      final s = statements[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMMM yyyy',
                                    ).format(s.statementDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: s.isPaid
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      s.isPaid ? 'Ödendi' : 'Bekliyor',
                                      style: TextStyle(
                                        color: s.isPaid
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ekstre: ₺${NumberFormat('#,##0.00').format(s.amount)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'Ödenen: ₺${NumberFormat('#,##0.00').format(s.paidAmount)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kalan: ₺${NumberFormat('#,##0.00').format(s.remainingAmount)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Son Ödeme: ${DateFormat('dd MMM').format(s.dueDate)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: s.amount > 0
                                    ? (s.paidAmount / s.amount).clamp(0.0, 1.0)
                                    : 0.0,
                                backgroundColor: Colors.grey.shade200,
                                color: Colors.green,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCreditCard() {
    final bankNameC = TextEditingController();
    final cardNameC = TextEditingController();
    final limitC = TextEditingController();
    final debtC = TextEditingController();
    int statementDay = 1;
    int dueDay = 20;
    String selectedColor = '#6C63FF';

    final cardColors = [
      {'name': 'Mor', 'color': '#6C63FF'},
      {'name': 'Kırmızı', 'color': '#E53935'},
      {'name': 'Mavi', 'color': '#1E88E5'},
      {'name': 'Yeşil', 'color': '#43A047'},
      {'name': 'Turuncu', 'color': '#FB8C00'},
      {'name': 'Siyah', 'color': '#212121'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Yeni Kredi Kartı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bankNameC,
                  decoration: InputDecoration(
                    labelText: 'Banka Adı (Garanti, Ziraat...)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cardNameC,
                  decoration: InputDecoration(
                    labelText: 'Kart Adı (Miles&Smiles, Bonus...)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Kart Limiti (₺)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: debtC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Borç (₺) - opsiyonel',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Ekstre günü: '),
                    Expanded(
                      child: Slider(
                        value: statementDay.toDouble(),
                        min: 1,
                        max: 28,
                        divisions: 27,
                        label: 'Her ayın $statementDay. günü',
                        onChanged: (v) => set(() => statementDay = v.toInt()),
                      ),
                    ),
                    Text('$statementDay'),
                  ],
                ),
                Row(
                  children: [
                    const Text('Son ödeme: '),
                    Expanded(
                      child: Slider(
                        value: dueDay.toDouble(),
                        min: 1,
                        max: 28,
                        divisions: 27,
                        label: 'Her ayın $dueDay. günü',
                        onChanged: (v) => set(() => dueDay = v.toInt()),
                      ),
                    ),
                    Text('$dueDay'),
                  ],
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kart Rengi:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: cardColors.map((c) {
                    final isSelected = selectedColor == c['color'];
                    return GestureDetector(
                      onTap: () => set(() => selectedColor = c['color']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _hexToColor(c['color']!),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (bankNameC.text.isEmpty ||
                          cardNameC.text.isEmpty ||
                          limitC.text.isEmpty) {
                        return;
                      }
                      final card = CreditCard(
                        id: _uuid.v4(),
                        bankName: bankNameC.text,
                        cardName: cardNameC.text,
                        creditLimit: double.parse(
                          limitC.text.replaceAll(',', '.'),
                        ),
                        currentDebt:
                            double.tryParse(debtC.text.replaceAll(',', '.')) ??
                            0,
                        statementDay: statementDay,
                        dueDay: dueDay,
                        color: selectedColor,
                      );
                      await _db.insertCreditCard(card);
                      await _loadAll();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      'Kartı Ekle',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransaction() {
    final titleC = TextEditingController();
    final amountC = TextEditingController();
    String cat = 'Market';
    bool isExpense = true;
    bool isFixed = false;
    CreditCard? selectedCard;
    final expenseCats = [
      'Market',
      'Faturalar',
      'Kira',
      'Ulaşım',
      'Sağlık',
      'Eğlence',
      'Giyim',
      'Yemek',
      'Eğitim',
      'Diğer',
    ];
    final incomeCats = ['Maaş', 'Ek Gelir'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, set) {
          final activeCats = isExpense ? expenseCats : incomeCats;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Yeni İşlem',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => set(() {
                            isExpense = true;
                            cat = 'Market';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isExpense
                                  ? Colors.red
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Gider',
                                style: TextStyle(
                                  color: isExpense
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => set(() {
                            isExpense = false;
                            isFixed = false;
                            selectedCard = null;
                            cat = 'Maaş';
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isExpense
                                  ? Colors.green
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Gelir',
                                style: TextStyle(
                                  color: !isExpense
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleC,
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Tutar (₺)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(isExpense),
                    initialValue: cat,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: activeCats
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => set(() => cat = v ?? cat),
                  ),
                  if (isExpense && _creditCards.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CreditCard?>(
                      initialValue: selectedCard,
                      decoration: InputDecoration(
                        labelText: '💳 Kredi Kartı (opsiyonel)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Kartla ödeme yok'),
                        ),
                        ..._creditCards.map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.bankName} - ${c.cardName}'),
                          ),
                        ),
                      ],
                      onChanged: (v) => set(() => selectedCard = v),
                    ),
                  ],
                  if (isExpense)
                    Row(
                      children: [
                        Checkbox(
                          value: isFixed,
                          onChanged: (v) => set(() => isFixed = v ?? false),
                        ),
                        const Text('Zorunlu gider'),
                      ],
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        if (titleC.text.isEmpty || amountC.text.isEmpty) return;
                        final amount = double.parse(
                          amountC.text.replaceAll(',', '.'),
                        );
                        final t = FinanceTransaction(
                          id: _uuid.v4(),
                          title: titleC.text,
                          amount: amount,
                          category: cat,
                          date: DateTime.now(),
                          isExpense: isExpense,
                          isFixed: isExpense && isFixed,
                          creditCardId: selectedCard?.id,
                          creditCardName: selectedCard != null
                              ? '${selectedCard!.bankName} ${selectedCard!.cardName}'
                              : null,
                        );
                        await _db.insertTransaction(t);

                        if (selectedCard != null && isExpense) {
                          final updatedCard = selectedCard!.copyWith(
                            currentDebt: selectedCard!.currentDebt + amount,
                          );
                          await _db.updateCreditCard(updatedCard);
                        }

                        await _loadAll();

                        if (isExpense) {
                          final now = DateTime.now();
                          final currentMonth = DateFormat(
                            'yyyy-MM',
                          ).format(now);
                          final budgetList = _budgets.where(
                            (b) => b.category == cat && b.month == currentMonth,
                          );
                          if (budgetList.isNotEmpty) {
                            final budget = budgetList.first;
                            final spent = _categoryTotals[cat] ?? 0;
                            if (spent > budget.limitAmount) {
                              final asim = spent - budget.limitAmount;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '⚠️ $cat bütçenizi ₺${asim.toStringAsFixed(2)} aştınız!',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          }
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddSubscription() {
    final titleC = TextEditingController();
    final amountC = TextEditingController();
    int billingDay = 1;
    String? selectedCardId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Yeni Abonelik',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleC,
                decoration: InputDecoration(
                  labelText: 'Abonelik Adı (Netflix, Spotify...)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Aylık Tutar (₺)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCardId,
                decoration: InputDecoration(
                  labelText: 'Bağlı kredi kartı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                hint: const Text('Kredi kartı seçin'),
                items: _creditCards
                    .map(
                      (card) => DropdownMenuItem(
                        value: card.id,
                        child: Text('${card.cardName} • ${card.bankName}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => set(() => selectedCardId = value),
              ),
              if (_creditCards.isEmpty) ...[
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Abonelik eklemek için önce bir kredi kartı ekleyin.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Fatura günü: '),
                  Expanded(
                    child: Slider(
                      value: billingDay.toDouble(),
                      min: 1,
                      max: 28,
                      divisions: 27,
                      label: 'Her ayın $billingDay. günü',
                      onChanged: (v) => set(() => billingDay = v.toInt()),
                    ),
                  ),
                  Text('$billingDay'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _creditCards.isEmpty
                      ? null
                      : () async {
                          final amount = double.tryParse(
                            amountC.text.replaceAll(',', '.'),
                          );
                          if (titleC.text.trim().isEmpty ||
                              amount == null ||
                              amount <= 0 ||
                              selectedCardId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Abonelik adı, geçerli tutar ve kredi kartı seçimi zorunludur.',
                                ),
                              ),
                            );
                            return;
                          }
                          final selectedCard = _creditCards.firstWhere(
                            (card) => card.id == selectedCardId,
                          );
                          final now = DateTime.now();
                          final currentMonth =
                              '${now.year}-${now.month.toString().padLeft(2, '0')}';
                          final s = Subscription(
                            id: _uuid.v4(),
                            title: titleC.text.trim(),
                            amount: amount,
                            category: 'Abonelik',
                            billingDay: billingDay,
                            color: '#6C63FF',
                            creditCardId: selectedCard.id,
                            creditCardName: selectedCard.cardName,
                            lastChargedMonth: billingDay < now.day
                                ? currentMonth
                                : null,
                          );
                          await _db.insertSubscription(s);
                          await NotificationService()
                              .scheduleSubscriptionReminder(
                                id: s.id.hashCode,
                                subscriptionName: s.title,
                                dayOfMonth: billingDay,
                                hour: 9,
                                minute: 0,
                              );
                          await _loadAll();
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDebt() => _showDebtForm();

  void _showEditDebt(Debt debt) => _showDebtForm(debt: debt);

  void _showDebtForm({Debt? debt}) {
    final isEditing = debt != null;
    final titleC = TextEditingController(text: debt?.title ?? '');
    final totalC = TextEditingController(
      text: debt?.totalAmount.toStringAsFixed(2) ?? '',
    );
    final paidC = TextEditingController(
      text: debt?.paidAmount.toStringAsFixed(2) ?? '',
    );
    final monthlyC = TextEditingController(
      text: debt?.monthlyPayment.toStringAsFixed(2) ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Borcu Düzenle' : 'Yeni Borç',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleC,
                decoration: InputDecoration(
                  labelText: 'Borç adı',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Toplam Borç (₺)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paidC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ödenen Miktar (₺)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monthlyC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Aylık Ödeme (₺)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final title = titleC.text.trim();
                    final total = double.tryParse(
                      totalC.text.replaceAll(',', '.'),
                    );
                    final paid =
                        double.tryParse(paidC.text.replaceAll(',', '.')) ?? 0;
                    final monthly =
                        double.tryParse(monthlyC.text.replaceAll(',', '.')) ??
                        0;

                    String? errorMessage;
                    if (title.isEmpty || total == null || total <= 0) {
                      errorMessage =
                          'Borç adı ve sıfırdan büyük toplam borç girin.';
                    } else if (paid < 0 || monthly < 0) {
                      errorMessage = 'Tutarlar negatif olamaz.';
                    } else if (paid > total) {
                      errorMessage =
                          'Ödenen miktar toplam borçtan büyük olamaz.';
                    }

                    if (errorMessage != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(errorMessage)));
                      return;
                    }

                    final updatedDebt = Debt(
                      id: debt?.id ?? _uuid.v4(),
                      title: title,
                      totalAmount: total!,
                      paidAmount: paid,
                      monthlyPayment: monthly,
                      startDate: debt?.startDate ?? DateTime.now(),
                      interestRate: debt?.interestRate ?? 0,
                    );
                    if (isEditing) {
                      await _db.updateDebt(updatedDebt);
                    } else {
                      await _db.insertDebt(updatedDebt);
                    }
                    await _loadAll();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    isEditing ? 'Güncelle' : 'Kaydet',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBudget() => _showBudgetForm();

  void _showBudgetForm({Budget? budget}) {
    final isEditing = budget != null;
    String cat = budget?.category ?? 'Market';
    final limitC = TextEditingController(
      text: budget?.limitAmount.toStringAsFixed(2),
    );
    final cats = [
      'Market',
      'Faturalar',
      'Kira',
      'Ulaşım',
      'Sağlık',
      'Eğlence',
      'Giyim',
      'Yemek',
      'Eğitim',
      'Diğer',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Bütçe Hedefini Düzenle' : 'Bütçe Hedefi Ekle',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: cat,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: cats
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setModalState(() => cat = v ?? cat),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitC,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Aylık Limit (₺)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final limit = double.tryParse(
                      limitC.text.trim().replaceAll(',', '.'),
                    );
                    if (limit == null || limit <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Aylık limit sıfırdan büyük bir sayı olmalı.',
                          ),
                        ),
                      );
                      return;
                    }
                    final b = Budget(
                      id: budget?.id ?? _uuid.v4(),
                      category: cat,
                      limitAmount: limit,
                      month:
                          budget?.month ??
                          DateFormat('yyyy-MM').format(DateTime.now()),
                    );
                    if (isEditing) {
                      await _db.updateBudget(b);
                    } else {
                      await _db.insertBudget(b);
                    }
                    await _loadAll();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: Text(
                    isEditing ? 'Güncelle' : 'Kaydet',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(limitC.dispose);
  }

  Future<void> _confirmDeleteBudget(Budget budget) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bütçe kalemini sil'),
        content: Text(
          '${budget.category} bütçe kalemi tamamen silinecek. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await _db.deleteBudget(budget.id);
    await _loadAll();
  }
}
