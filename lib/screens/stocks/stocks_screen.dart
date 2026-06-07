import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../models/stock_holding.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/stock_alert_service.dart';
import 'stock_detail_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});
  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StockHolding> _holdings = [];
  final _db = DatabaseService();
  final _uuid = const Uuid();
  final _alertService = StockAlertService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Map<String, double?> _watchlist = {};
  String _selectedFilter = 'Tümü';

  final Map<String, List<Map<String, String>>> _markets = {
    'Tümü': [],
    'BIST': [
      {'symbol': 'THYAO.IS', 'name': 'Türk Hava Yolları'},
      {'symbol': 'GARAN.IS', 'name': 'Garanti BBVA'},
      {'symbol': 'ASELS.IS', 'name': 'Aselsan'},
      {'symbol': 'EREGL.IS', 'name': 'Ereğli Demir'},
      {'symbol': 'AKBNK.IS', 'name': 'Akbank'},
      {'symbol': 'SISE.IS', 'name': 'Şişe Cam'},
      {'symbol': 'KCHOL.IS', 'name': 'Koç Holding'},
      {'symbol': 'TOASO.IS', 'name': 'Tofaş'},
      {'symbol': 'ISCTR.IS', 'name': 'İş Bankası'},
      {'symbol': 'TUPRS.IS', 'name': 'Tüpraş'},
      {'symbol': 'BIMAS.IS', 'name': 'BİM'},
      {'symbol': 'FROTO.IS', 'name': 'Ford Otosan'},
      {'symbol': 'SAHOL.IS', 'name': 'Sabancı Holding'},
      {'symbol': 'ARCLK.IS', 'name': 'Arçelik'},
      {'symbol': 'HALKB.IS', 'name': 'Halkbank'},
      {'symbol': 'VAKBN.IS', 'name': 'Vakıfbank'},
      {'symbol': 'YKBNK.IS', 'name': 'Yapı Kredi'},
      {'symbol': 'PGSUS.IS', 'name': 'Pegasus'},
      {'symbol': 'TAVHL.IS', 'name': 'TAV Havalimanları'},
      {'symbol': 'EKGYO.IS', 'name': 'Emlak Konut GYO'},
      {'symbol': 'KOZAL.IS', 'name': 'Koza Altın'},
      {'symbol': 'MGROS.IS', 'name': 'Migros'},
      {'symbol': 'TCELL.IS', 'name': 'Turkcell'},
      {'symbol': 'TTKOM.IS', 'name': 'Türk Telekom'},
      {'symbol': 'PETKM.IS', 'name': 'Petkim'},
      {'symbol': 'DOHOL.IS', 'name': 'Doğan Holding'},
      {'symbol': 'ENKAI.IS', 'name': 'Enka İnşaat'},
      {'symbol': 'CCOLA.IS', 'name': 'Coca Cola İçecek'},
      {'symbol': 'ULKER.IS', 'name': 'Ülker'},
      {'symbol': 'SOKM.IS', 'name': 'Şok Market'},
      {'symbol': 'SASA.IS', 'name': 'Sasa Polyester'},
      {'symbol': 'TKFEN.IS', 'name': 'Tekfen Holding'},
      {'symbol': 'AEFES.IS', 'name': 'Anadolu Efes'},
      {'symbol': 'MAVI.IS', 'name': 'Mavi Giyim'},
      {'symbol': 'DOAS.IS', 'name': 'Doğuş Otomotiv'},
      {'symbol': 'VESBE.IS', 'name': 'Vestel Beyaz Eşya'},
      {'symbol': 'TERA.IS', 'name': 'Tera Yatırım'},
    ],
    'ABD': [
      {'symbol': 'AAPL', 'name': 'Apple'},
      {'symbol': 'GOOGL', 'name': 'Google'},
      {'symbol': 'MSFT', 'name': 'Microsoft'},
      {'symbol': 'TSLA', 'name': 'Tesla'},
      {'symbol': 'AMZN', 'name': 'Amazon'},
      {'symbol': 'META', 'name': 'Meta'},
      {'symbol': 'NVDA', 'name': 'NVIDIA'},
      {'symbol': 'NFLX', 'name': 'Netflix'},
    ],
    'Avrupa': [
      {'symbol': 'SAP.DE', 'name': 'SAP'},
      {'symbol': 'ASML.AS', 'name': 'ASML'},
      {'symbol': 'MC.PA', 'name': 'LVMH'},
      {'symbol': 'SIE.DE', 'name': 'Siemens'},
      {'symbol': 'NESN.SW', 'name': 'Nestle'},
    ],
    'Kripto': [
      {'symbol': 'BTC-USD', 'name': 'Bitcoin'},
      {'symbol': 'ETH-USD', 'name': 'Ethereum'},
      {'symbol': 'BNB-USD', 'name': 'BNB'},
      {'symbol': 'SOL-USD', 'name': 'Solana'},
      {'symbol': 'XRP-USD', 'name': 'XRP'},
      {'symbol': 'AVAX-USD', 'name': 'Avalanche'},
    ],
    'Emtia': [
      {'symbol': 'GC=F', 'name': 'Altın'},
      {'symbol': 'SI=F', 'name': 'Gümüş'},
      {'symbol': 'CL=F', 'name': 'Ham Petrol'},
      {'symbol': 'NG=F', 'name': 'Doğalgaz'},
    ],
  };

  List<Map<String, String>> get _currentList {
    if (_selectedFilter == 'Tümü') {
      return _markets.values.expand((e) => e).toList();
    }
    return _markets[_selectedFilter] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHoldings();
    _loadWatchlist();
    NotificationService().init();
  }

  Future<void> _loadHoldings() async {
    final data = await _db.getHoldings();
    setState(() => _holdings = data);
    _updatePrices();
  }

  Future<void> _loadWatchlist() async {
    for (var item in _currentList) {
      _fetchPrice(item['symbol']!);
    }
  }

  Future<void> _updatePrices() async {
    for (var h in _holdings) {
      final price = await _getPrice(h.symbol);
      if (price != null && mounted) {
        setState(() => h.currentPrice = price);
      }
    }
  }

  Future<double?> _getPrice(String symbol) async {
    try {
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d';
      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'Mozilla/5.0'});
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

  Future<void> _fetchPrice(String symbol) async {
    final price = await _getPrice(symbol);
    if (mounted) setState(() => _watchlist[symbol] = price);
  }

  Future<void> _searchSymbol(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final url =
          'https://query1.finance.yahoo.com/v1/finance/search?q=$query&lang=tr-TR&region=TR';
      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'Mozilla/5.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quotes = data['quotes'] as List;
        setState(() {
          _searchResults = quotes.take(8).map((q) => {
            'symbol': q['symbol']?.toString() ?? '',
            'name': q['longname']?.toString() ?? q['shortname']?.toString() ?? '',
          }).toList();
        });
      }
    } catch (e) {
      setState(() => _searchResults = []);
    }
    setState(() => _isSearching = false);
  }

  double get _totalInvested => _holdings.fold(0, (s, h) => s + h.totalCost);
  double get _totalValue => _holdings.fold(0, (s, h) => s + h.currentValue);
  double get _totalProfitLoss => _totalValue - _totalInvested;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borsa & Yatırım',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active),
              onPressed: _showAlerts),
          IconButton(icon: const Icon(Icons.refresh),
              onPressed: () { _loadWatchlist(); _updatePrices(); }),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Piyasa'),
            Tab(text: 'Portföy'),
            Tab(text: 'Analiz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMarket(), _buildPortfolio(), _buildAnalysis()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHoldingWithSymbol,
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMarket() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Hisse, kripto, emtia ara...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        })
                    : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          onChanged: _searchSymbol,
        ),
      ),
      if (_searchResults.isEmpty)
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _markets.keys.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (v) {
                    setState(() => _selectedFilter = filter);
                    _loadWatchlist();
                  },
                  selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6C63FF),
                ),
              );
            }).toList(),
          ),
        ),
      const SizedBox(height: 8),
      Expanded(
        child: _searchResults.isNotEmpty
            ? ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                      child: Text(
                        item['symbol']!.isNotEmpty ? item['symbol']![0] : '?',
                        style: const TextStyle(color: Color(0xFF6C63FF)),
                      ),
                    ),
                    title: Text(item['symbol']!,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['name']!),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => StockDetailScreen(
                          symbol: item['symbol']!,
                          name: item['name']!,
                        ),
                      ));
                    },
                  );
                },
              )
            : RefreshIndicator(
                onRefresh: _loadWatchlist,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _currentList.length,
                  itemBuilder: (context, index) {
                    final item = _currentList[index];
                    final symbol = item['symbol']!;
                    final price = _watchlist[symbol];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                          child: Text(symbol[0],
                              style: const TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(item['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(symbol,
                            style: const TextStyle(fontSize: 12)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          price != null
                              ? Text(NumberFormat('#,##0.00').format(price),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14))
                              : const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.notifications_none, size: 20),
                            onPressed: () => _showAddAlert(symbol, item['name']!, price ?? 0),
                          ),
                        ]),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (context) => StockDetailScreen(
                            symbol: symbol,
                            name: item['name']!,
                          ),
                        )),
                      ),
                    );
                  },
                ),
              ),
      ),
    ]);
  }

  Widget _buildPortfolio() {
    return Column(children: [
      if (_holdings.isNotEmpty)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _totalProfitLoss >= 0
                  ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
                  : [const Color(0xFFD32F2F), const Color(0xFFEF9A9A)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('Toplam Portföy Değeri',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(NumberFormat('#,##0.00').format(_totalValue),
                style: const TextStyle(color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              Column(children: [
                const Text('Yatırılan',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(NumberFormat('#,##0.00').format(_totalInvested),
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ]),
              Column(children: [
                const Text('Kar/Zarar',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${_totalProfitLoss >= 0 ? '+' : ''}${NumberFormat('#,##0.00').format(_totalProfitLoss)}',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ]),
            ]),
          ]),
        ),
      Expanded(
        child: _holdings.isEmpty
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.candlestick_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Portföy boş',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text('Piyasa sekmesinden hisse ekle',
                      style: TextStyle(color: Colors.grey)),
                ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _holdings.length,
                itemBuilder: (context, index) {
                  final h = _holdings[index];
                  final isProfit = h.profitLoss >= 0;
                  return Dismissible(
                    key: Key(h.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await _db.deleteHolding(h.id);
                      await _loadHoldings();
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  CircleAvatar(
                                    backgroundColor: isProfit
                                        ? Colors.green.shade50 : Colors.red.shade50,
                                    child: Text(h.symbol[0],
                                        style: TextStyle(
                                            color: isProfit ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h.symbol, style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(h.name, style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                    ]),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(h.currentPrice != null
                                        ? NumberFormat('#,##0.00').format(h.currentPrice)
                                        : 'Yükleniyor...',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('${isProfit ? '+' : ''}${h.profitLossPercent.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                            color: isProfit ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold)),
                                  ]),
                              ]),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statChip('Alış', NumberFormat('#,##0.00').format(h.buyPrice)),
                                _statChip('Adet', h.quantity.toStringAsFixed(4)),
                                _statChip('Kar/Zarar',
                                    '${isProfit ? '+' : ''}${NumberFormat('#,##0.00').format(h.profitLoss)}',
                                    color: isProfit ? Colors.green : Colors.red),
                              ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                                    foregroundColor: const Color(0xFF6C63FF),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _showSimulate(h),
                                  icon: const Icon(Icons.calculate, size: 16),
                                  label: const Text('Satış Simülasyonu'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.notifications_active,
                                    color: Color(0xFF6C63FF)),
                                onPressed: () => _showAddAlert(
                                    h.symbol, h.name, h.currentPrice ?? h.buyPrice),
                              ),
                            ]),
                          ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _statChip(String label, String value, {Color? color}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold,
          color: color, fontSize: 13)),
    ]);
  }

  Widget _buildAnalysis() {
    if (_holdings.isEmpty) {
      return const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Analiz için portföy ekle',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Portföy Dağılımı',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._holdings.map((h) {
          final percent = _totalInvested > 0
              ? h.totalCost / _totalInvested * 100 : 0.0;
          final isProfit = h.profitLoss >= 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${h.symbol} — ${h.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('%${percent.toStringAsFixed(1)}'),
              ]),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: Colors.grey.shade200,
                color: isProfit ? Colors.green : Colors.red,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Alış: ${DateFormat('dd MMM yyyy').format(h.buyDate)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${isProfit ? '+' : ''}${NumberFormat('#,##0.00').format(h.profitLoss)}',
                    style: TextStyle(fontSize: 12,
                        color: isProfit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  void _showAddAlert(String symbol, String name, double currentPrice) {
    final priceC = TextEditingController(text: currentPrice.toStringAsFixed(2));
    bool isAbove = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$symbol Fiyat Alarmı',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Güncel: ${NumberFormat('#,##0.00').format(currentPrice)}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => set(() => isAbove = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isAbove ? Colors.green : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('📈 Yükselince',
                      style: TextStyle(
                          color: isAbove ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold))),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => set(() => isAbove = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !isAbove ? Colors.red : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('📉 Düşünce',
                      style: TextStyle(
                          color: !isAbove ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold))),
                ),
              )),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: priceC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Hedef Fiyat',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  if (priceC.text.isEmpty) return;
                  _alertService.addAlert(StockAlert(
                    symbol: symbol, name: name,
                    targetPrice: double.parse(priceC.text.replaceAll(',', '.')),
                    isAbove: isAbove,
                  ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$symbol için alarm kuruldu!'),
                    backgroundColor: const Color(0xFF6C63FF),
                  ));
                },
                child: const Text('Alarmı Kur', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showAlerts() {
    final alerts = _alertService.alerts;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Aktif Alarmlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            const Padding(padding: EdgeInsets.all(20),
                child: Text('Henüz alarm kurulmadı',
                    style: TextStyle(color: Colors.grey)))
          else
            ...alerts.map((a) => ListTile(
              leading: Icon(a.isAbove ? Icons.trending_up : Icons.trending_down,
                  color: a.isAbove ? Colors.green : Colors.red),
              title: Text(a.symbol,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${a.isAbove ? 'Yükselince' : 'Düşünce'}: ${NumberFormat('#,##0.00').format(a.targetPrice)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _alertService.removeAlert(a.symbol);
                  Navigator.pop(context);
                  _showAlerts();
                },
              ),
            )),
        ]),
      ),
    );
  }

  void _showSimulate(StockHolding h) {
    final sellPriceC = TextEditingController(
        text: h.currentPrice?.toStringAsFixed(2) ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, set) {
          double simProfit = 0;
          if (sellPriceC.text.isNotEmpty) {
            final sellPrice = double.tryParse(
                sellPriceC.text.replaceAll(',', '.')) ?? 0;
            simProfit = h.simulateSell(sellPrice);
          }
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${h.symbol} Satış Simülasyonu',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _statChip('Alış', NumberFormat('#,##0.00').format(h.buyPrice)),
                _statChip('Adet', h.quantity.toStringAsFixed(4)),
                _statChip('Maliyet', NumberFormat('#,##0.00').format(h.totalCost)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: sellPriceC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Satış Fiyatı',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                onChanged: (v) => set(() {}),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: simProfit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Text(simProfit >= 0 ? 'Tahmini Kar' : 'Tahmini Zarar',
                      style: TextStyle(color: simProfit >= 0 ? Colors.green : Colors.red)),
                  Text('${simProfit >= 0 ? '+' : ''}${NumberFormat('#,##0.00').format(simProfit)}',
                      style: TextStyle(color: simProfit >= 0 ? Colors.green : Colors.red,
                          fontSize: 28, fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  void _showAddHoldingWithSymbol() => _showAddHoldingWithSymbolData('', '');

  void _showAddHoldingWithSymbolData(String symbol, String name) {
    final symbolC = TextEditingController(text: symbol);
    final nameC = TextEditingController(text: name);
    final buyPriceC = TextEditingController();
    final quantityC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Yatırım Ekle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: symbolC,
                decoration: InputDecoration(labelText: 'Sembol (AAPL, BTC-USD, THYAO.IS)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            TextField(controller: nameC,
                decoration: InputDecoration(labelText: 'İsim',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            TextField(controller: buyPriceC, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Alış Fiyatı',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            TextField(controller: quantityC, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Adet / Miktar',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  if (symbolC.text.isEmpty || buyPriceC.text.isEmpty ||
                      quantityC.text.isEmpty) return;
                  final h = StockHolding(
                    id: _uuid.v4(),
                    symbol: symbolC.text.toUpperCase(),
                    name: nameC.text,
                    buyPrice: double.parse(buyPriceC.text.replaceAll(',', '.')),
                    quantity: double.parse(quantityC.text.replaceAll(',', '.')),
                    buyDate: DateTime.now(),
                  );
                  await _db.insertHolding(h);
                  await _loadHoldings();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Portföye Ekle', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}