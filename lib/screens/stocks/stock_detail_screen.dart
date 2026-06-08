import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String name;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  Map<String, dynamic>? _stockData;
  List<FlSpot> _chartData = [];
  bool _isLoading = true;
  String _selectedRange = '1mo';
  String _error = '';

  final Map<String, String> _ranges = {
    '1hf': '5d',
    '1ay': '1mo',
    '3ay': '3mo',
    '6ay': '6mo',
    '1yıl': '1y',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    await Future.wait([_loadStockInfo(), _loadChartData()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadStockInfo() async {
    try {
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/${widget.symbol}?interval=1d&range=1d';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meta = data['chart']['result'][0]['meta'];
        setState(() => _stockData = meta);
      }
    } catch (e) {
      setState(() => _error = 'Veri yüklenemedi');
    }
  }

  Future<void> _loadChartData() async {
    try {
      final url =
          'https://query1.finance.yahoo.com/v8/finance/chart/${widget.symbol}?interval=1d&range=$_selectedRange';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final closes =
            data['chart']['result'][0]['indicators']['quote'][0]['close']
                as List;
        final spots = <FlSpot>[];
        for (int i = 0; i < closes.length; i++) {
          if (closes[i] != null) {
            spots.add(FlSpot(i.toDouble(), closes[i].toDouble()));
          }
        }
        setState(() => _chartData = spots);
      }
    } catch (e) {
      setState(() => _chartData = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = _stockData?['regularMarketPrice']?.toDouble() ?? 0.0;
    final prevClose = _stockData?['chartPreviousClose']?.toDouble() ?? price;
    final change = price - prevClose;
    final changePercent = prevClose > 0 ? (change / prevClose * 100) : 0.0;
    final isPositive = change >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.name,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fiyat kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPositive
                            ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
                            : [
                                const Color(0xFFD32F2F),
                                const Color(0xFFEF9A9A),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NumberFormat('#,##0.00').format(price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: Colors.white,
                              size: 16,
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${NumberFormat('#,##0.00').format(change)} (${changePercent.toStringAsFixed(2)}%)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grafik
                  const Text(
                    'Fiyat Grafiği',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Zaman aralığı seçici
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _ranges.entries.map((e) {
                        final isSelected = _selectedRange == e.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(e.key),
                            selected: isSelected,
                            onSelected: (v) {
                              setState(() => _selectedRange = e.value);
                              _loadChartData();
                            },
                            selectedColor: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_chartData.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartData,
                              isCurved: true,
                              color: isPositive ? Colors.green : Colors.red,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: isPositive
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Grafik verisi yüklenemedi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Detay bilgileri
                  const Text(
                    'Piyasa Bilgileri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2,
                    children: [
                      _infoCard(
                        'Açılış',
                        NumberFormat(
                          '#,##0.00',
                        ).format(_stockData?['regularMarketOpen'] ?? 0),
                      ),
                      _infoCard(
                        'Önceki Kapanış',
                        NumberFormat('#,##0.00').format(prevClose),
                      ),
                      _infoCard(
                        'Günlük Yüksek',
                        NumberFormat(
                          '#,##0.00',
                        ).format(_stockData?['regularMarketDayHigh'] ?? 0),
                      ),
                      _infoCard(
                        'Günlük Düşük',
                        NumberFormat(
                          '#,##0.00',
                        ).format(_stockData?['regularMarketDayLow'] ?? 0),
                      ),
                      _infoCard(
                        '52H Yüksek',
                        NumberFormat(
                          '#,##0.00',
                        ).format(_stockData?['fiftyTwoWeekHigh'] ?? 0),
                      ),
                      _infoCard(
                        '52H Düşük',
                        NumberFormat(
                          '#,##0.00',
                        ).format(_stockData?['fiftyTwoWeekLow'] ?? 0),
                      ),
                      _infoCard(
                        'Hacim',
                        NumberFormat(
                          '#,##0',
                        ).format(_stockData?['regularMarketVolume'] ?? 0),
                      ),
                      _infoCard('Para Birimi', _stockData?['currency'] ?? '-'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
