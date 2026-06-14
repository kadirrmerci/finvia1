import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/health_record.dart';
import '../../models/habit.dart';
import '../../models/menstrual_cycle_record.dart';
import '../../services/body_fat_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});
  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthRecord> _records = [];
  List<Habit> _habits = [];
  List<MenstrualCycleRecord> _cycles = [];
  double? _targetWeight;
  String? _profileGender;
  final _db = DatabaseService();
  final _uuid = const Uuid();
  final _bodyFatService = const BodyFatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final records = await _db.getHealthRecords();
    final habits = await _db.getHabits();
    final cycles = await _db.getMenstrualCycles();
    final goal = await _db.getHealthGoal();
    final profileGender = await _db.getCurrentUserGender();
    if (!mounted) return;
    final nextLength = profileGender == 'female' ? 3 : 2;
    if (_tabController.length != nextLength) {
      final nextIndex = _tabController.index.clamp(0, nextLength - 1);
      _tabController.dispose();
      _tabController = TabController(
        length: nextLength,
        vsync: this,
        initialIndex: nextIndex,
      );
    }
    setState(() {
      _records = records;
      _habits = habits;
      _cycles = cycles;
      _targetWeight = (goal?['targetWeight'] as num?)?.toDouble();
      _profileGender = profileGender;
    });
  }

  bool get _showMenstrualCycle => _profileGender == 'female';

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sağlık & Alışkanlık',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Vücut Takibi'),
            if (_showMenstrualCycle) const Tab(text: 'Adet Döngüsü'),
            const Tab(text: 'Alışkanlıklar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBodyFat(),
          if (_showMenstrualCycle) _buildMenstrualCycle(),
          _buildHabits(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddBodyFatMeasurement();
          } else if (_showMenstrualCycle && _tabController.index == 1) {
            _showAddMenstrualCycle();
          } else {
            _showAddHabit();
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildWeight() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz kilo kaydı yok',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Text(
              '+ butonuna basarak ekle',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.alarm),
              label: const Text('Kilo Hatırlatıcısı Kur'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF)),
              ),
              onPressed: _showWeightReminderDialog,
            ),
          ],
        ),
      );
    }

    final latest = _records.first;
    final first = _records.last;
    final diff = latest.weight - first.weight;
    final isLoss = diff <= 0;
    final targetDiff = _targetWeight == null
        ? null
        : latest.weight - _targetWeight!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _weightCard(
                  'Güncel Kilo',
                  '${latest.weight} kg',
                  Icons.monitor_weight,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _weightCard(
                  'Değişim',
                  '${isLoss ? '' : '+'}${diff.toStringAsFixed(1)} kg',
                  isLoss ? Icons.trending_down : Icons.trending_up,
                  isLoss ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.flag_outlined)),
              title: Text(
                _targetWeight == null
                    ? 'Hedef kilo belirlenmedi'
                    : 'Hedef kilo: ${_targetWeight!.toStringAsFixed(1)} kg',
              ),
              subtitle: Text(
                targetDiff == null
                    ? 'Hedef belirleyerek kilo ilerlemeni raporla.'
                    : targetDiff > 0
                    ? 'Hedefe ${targetDiff.toStringAsFixed(1)} kg kaldı.'
                    : 'Hedefin ${targetDiff.abs().toStringAsFixed(1)} kg altındasın.',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _showTargetWeightDialog,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.alarm),
              label: const Text('Kilo Hatırlatıcısı Kur'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF)),
              ),
              onPressed: _showWeightReminderDialog,
            ),
          ),
          const SizedBox(height: 16),
          if (_records.length > 1) ...[
            const Text(
              'Kilo Grafiği',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
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
                          final reversed = _records.reversed.toList();
                          if (idx < 0 || idx >= reversed.length) {
                            return const SizedBox();
                          }
                          return Text(
                            DateFormat('dd/MM').format(reversed[idx].date),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _records.reversed
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF6C63FF),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Kayıtlar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._records.map(
            (r) => Dismissible(
              key: Key(r.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                await _db.deleteHealthRecord(r.id);
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
                    child: const Icon(
                      Icons.monitor_weight,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  title: Text(
                    '${r.weight} kg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat('dd MMMM yyyy').format(r.date)),
                  trailing: r.note != null && r.note!.isNotEmpty
                      ? Text(
                          r.note!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyFat() {
    final bodyFatRecords = _records
        .where((r) => r.bodyFatPercentage != null)
        .toList(growable: false);
    final measurementRecords = _records
        .where(_hasBodyMeasurement)
        .toList(growable: false);

    if (bodyFatRecords.isEmpty && measurementRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.percent, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Henüz yağ oranı ölçümü yok',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Text(
              '+ butonuna basarak bilimsel ölçüm ekle',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.alarm),
              label: const Text('Haftalık Ölçüm Hatırlatıcısı'),
              onPressed: _showBodyFatReminderDialog,
            ),
          ],
        ),
      );
    }

    final latest = bodyFatRecords.isEmpty ? null : bodyFatRecords.first;
    final previous = bodyFatRecords.length > 1 ? bodyFatRecords[1] : null;
    final change = latest == null || previous == null
        ? null
        : latest.bodyFatPercentage! - previous.bodyFatPercentage!;
    final latestFfmi = latest == null
        ? null
        : latest.ffmi ??
              (latest.height == null
                  ? null
                  : _bodyFatService.calculateFfmi(
                      weightKg: latest.weight,
                      heightCm: latest.height!,
                      bodyFatPercentage: latest.bodyFatPercentage!,
                    ));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _metricPill(
                'BW',
                latest == null ? '-' : '${latest.weight.toStringAsFixed(1)} kg',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricPill(
                'BF',
                latest == null
                    ? '-'
                    : '%${latest.bodyFatPercentage!.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _metricPill('FFMI', latestFfmi?.toStringAsFixed(2) ?? '-'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _weightCard(
                'Güncel Yağ Oranı',
                latest == null
                    ? '-'
                    : '%${latest.bodyFatPercentage!.toStringAsFixed(1)}',
                Icons.percent,
                Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _weightCard(
                'Son Değişim',
                change == null
                    ? 'İlk ölçüm'
                    : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                change == null || change <= 0
                    ? Icons.trending_down
                    : Icons.trending_up,
                change == null || change <= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.alarm),
            label: const Text('Haftalık Yağ Oranı Hatırlatıcısı'),
            onPressed: _showBodyFatReminderDialog,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ölçülerim',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _measurementSection(
          'Vücut Ağırlığı',
          measurementRecords,
          (r) => r.weight <= 0 ? null : r.weight,
          field: _BodyMeasurementField.weight,
        ),
        _measurementSection(
          'Boy',
          measurementRecords,
          (r) => r.height,
          field: _BodyMeasurementField.height,
        ),
        _measurementSection(
          'Boyun',
          measurementRecords,
          (r) => r.neck,
          field: _BodyMeasurementField.neck,
        ),
        _measurementSection(
          'Bel',
          measurementRecords,
          (r) => r.waist,
          field: _BodyMeasurementField.waist,
        ),
        _measurementSection(
          'Kalça',
          measurementRecords,
          (r) => r.hip,
          field: _BodyMeasurementField.hip,
        ),
      ],
    );
  }

  Widget _metricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFC83333),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementSection(
    String title,
    List<HealthRecord> records,
    double? Function(HealthRecord record) selector, {
    _BodyMeasurementField? field,
    String suffix = '',
  }) {
    final values = records
        .where((record) => selector(record) != null)
        .take(2)
        .toList(growable: false);
    if (values.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFC83333),
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [
            ...values.map((record) {
              final value = selector(record)!;
              return ListTile(
                title: Text(
                  '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$suffix',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                subtitle: Text(_relativeDayText(record.date)),
                trailing: field == null
                    ? null
                    : IconButton(
                        tooltip: 'Düzenle',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showSingleMeasurementEditor(
                          title: title,
                          field: field,
                          record: record,
                          currentValue: value,
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _hasBodyMeasurement(HealthRecord record) {
    return record.weight > 0 ||
        record.height != null ||
        record.neck != null ||
        record.hip != null ||
        record.waist != null ||
        record.bodyFatPercentage != null;
  }

  void _showSingleMeasurementEditor({
    required String title,
    required _BodyMeasurementField field,
    HealthRecord? record,
    double? currentValue,
  }) {
    final valueC = TextEditingController(
      text: currentValue == null ? '' : currentValue.toStringAsFixed(1),
    );
    var selectedDate = record?.date ?? DateTime.now();

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
              Text(
                '$title Ölçüsü',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '$title (cm/kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) set(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final value = _parseDouble(valueC.text);
                    if (value == null) {
                      _showHealthMessage(
                        'Geçerli bir ölçü gir.',
                        isError: true,
                      );
                      return;
                    }
                    final updated = _copyHealthRecordWithMeasurement(
                      record ??
                          HealthRecord(
                            id: _uuid.v4(),
                            weight: field == _BodyMeasurementField.weight
                                ? value
                                : 0,
                            date: selectedDate,
                          ),
                      field,
                      value,
                      selectedDate,
                    );
                    if (record == null) {
                      await _db.insertHealthRecord(updated);
                    } else {
                      await _db.updateHealthRecord(updated);
                    }
                    await _loadAll();
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showHealthMessage('$title ölçüsü kaydedildi.');
                    }
                  },
                  child: Text(record == null ? 'Kaydet' : 'Güncelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  HealthRecord _copyHealthRecordWithMeasurement(
    HealthRecord record,
    _BodyMeasurementField field,
    double? value,
    DateTime date,
  ) {
    final updated = HealthRecord(
      id: record.id,
      weight: field == _BodyMeasurementField.weight
          ? (value ?? 0)
          : record.weight,
      date: date,
      note: record.note,
      height: field == _BodyMeasurementField.height ? value : record.height,
      waist: field == _BodyMeasurementField.waist ? value : record.waist,
      neck: field == _BodyMeasurementField.neck ? value : record.neck,
      hip: field == _BodyMeasurementField.hip ? value : record.hip,
      shoulder: field == _BodyMeasurementField.shoulder
          ? value
          : record.shoulder,
      chest: field == _BodyMeasurementField.chest ? value : record.chest,
      arm: field == _BodyMeasurementField.arm ? value : record.arm,
      thigh: field == _BodyMeasurementField.thigh ? value : record.thigh,
      calf: field == _BodyMeasurementField.calf ? value : record.calf,
      gender: record.gender ?? 'male',
      bodyFatPercentage: record.bodyFatPercentage,
      ffmi: record.ffmi,
    );
    return _withRecalculatedBodyMetrics(updated);
  }

  HealthRecord _withRecalculatedBodyMetrics(HealthRecord record) {
    final gender = record.gender ?? 'male';
    final canCalculate =
        record.weight > 0 &&
        record.height != null &&
        record.waist != null &&
        record.neck != null &&
        (gender != 'female' || record.hip != null);

    double? bodyFat;
    double? ffmi;
    if (canCalculate) {
      try {
        bodyFat = _bodyFatService
            .calculateAceNavyBodyFat(
              gender: gender,
              heightCm: record.height!,
              waistCm: record.waist!,
              neckCm: record.neck!,
              hipCm: record.hip,
            )
            .clamp(2, 75)
            .toDouble();
        ffmi = _bodyFatService.calculateFfmi(
          weightKg: record.weight,
          heightCm: record.height!,
          bodyFatPercentage: bodyFat,
        );
      } catch (_) {
        bodyFat = null;
        ffmi = null;
      }
    }

    return HealthRecord(
      id: record.id,
      weight: record.weight,
      date: record.date,
      note: record.note,
      height: record.height,
      waist: record.waist,
      neck: record.neck,
      hip: record.hip,
      shoulder: record.shoulder,
      chest: record.chest,
      arm: record.arm,
      thigh: record.thigh,
      calf: record.calf,
      gender: gender,
      bodyFatPercentage: bodyFat,
      ffmi: ffmi,
    );
  }

  String _relativeDayText(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'bugün';
    return '$days gün önce';
  }

  Widget _buildMenstrualCycle() {
    if (_cycles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz adet döngüsü kaydı yok',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              '+ butonuna basarak son adet başlangıcını ekle',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final latest = _cycles.first;
    final predictedCycleLength = _predictedCycleLength();
    final prediction = MenstrualCycleRecord(
      id: latest.id,
      periodStart: latest.periodStart,
      cycleLength: predictedCycleLength,
      periodLength: latest.periodLength,
      note: latest.note,
    );
    final daysToPeriod = prediction.nextPeriodStart
        .difference(DateTime.now())
        .inDays;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _weightCard(
                'Sonraki Adet',
                DateFormat('dd MMM').format(prediction.nextPeriodStart),
                Icons.event,
                Colors.pink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _weightCard(
                'Kalan Gün',
                daysToPeriod < 0 ? 'geçti' : '$daysToPeriod gün',
                Icons.hourglass_bottom,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _weightCard(
                'Ovulasyon',
                DateFormat('dd MMM').format(prediction.ovulationDate),
                Icons.egg_alt_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _weightCard(
                'Verimli Pencere',
                '${DateFormat('dd MMM').format(prediction.fertileStart)} - ${DateFormat('dd MMM').format(prediction.fertileEnd)}',
                Icons.favorite_outline,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Tahmini döngü: $predictedCycleLength gün',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Kayıtlar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._cycles.map(
          (cycle) => Dismissible(
            key: Key(cycle.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) async {
              await _db.deleteMenstrualCycle(cycle.id);
              await _loadAll();
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.water_drop)),
                title: Text(
                  DateFormat('dd MMMM yyyy').format(cycle.periodStart),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${cycle.cycleLength} gün döngü • ${cycle.periodLength} gün adet',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _predictedCycleLength() {
    if (_cycles.isEmpty) return 28;
    final lengths = _cycles.take(6).map((c) => c.cycleLength).toList();
    if (lengths.length == 1) return lengths.first;
    var weightedSum = 0.0;
    var totalWeight = 0.0;
    for (var i = 0; i < lengths.length; i++) {
      final weight = lengths.length - i;
      weightedSum += lengths[i] * weight;
      totalWeight += weight;
    }
    return (weightedSum / totalWeight).round().clamp(21, 45);
  }

  void _showAddMenstrualCycle() {
    var periodStart = DateTime.now();
    final cycleLengthC = TextEditingController(text: '28');
    final periodLengthC = TextEditingController(text: '5');
    final noteC = TextEditingController();

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
                  'Adet Döngüsü',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd MMMM yyyy').format(periodStart)),
                  subtitle: const Text('Son adet başlangıç tarihi'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: periodStart,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) set(() => periodStart = picked);
                  },
                ),
                _numberField(cycleLengthC, 'Döngü uzunluğu (gün)'),
                _numberField(periodLengthC, 'Adet süresi (gün)'),
                TextField(
                  controller: noteC,
                  decoration: InputDecoration(
                    labelText: 'Not (opsiyonel)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final cycleLength =
                          int.tryParse(cycleLengthC.text.trim()) ?? 28;
                      final periodLength =
                          int.tryParse(periodLengthC.text.trim()) ?? 5;
                      if (cycleLength < 21 ||
                          cycleLength > 45 ||
                          periodLength < 1 ||
                          periodLength > 12) {
                        _showHealthMessage(
                          'Döngü ve adet süresi değerlerini kontrol et.',
                          isError: true,
                        );
                        return;
                      }
                      await _db.insertMenstrualCycle(
                        MenstrualCycleRecord(
                          id: _uuid.v4(),
                          periodStart: periodStart,
                          cycleLength: cycleLength,
                          periodLength: periodLength,
                          note: noteC.text.trim().isEmpty
                              ? null
                              : noteC.text.trim(),
                        ),
                      );
                      await _loadAll();
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showHealthMessage('Adet döngüsü kaydedildi.');
                      }
                    },
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabits() {
    if (_habits.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.self_improvement, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz alışkanlık yok',
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
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        final isCompleted = habit.isTodayCompleted();
        final streak = habit.currentStreak;
        final totalDays = DateTime.now().difference(habit.startDate).inDays + 1;
        final completedCount = habit.completedDays.length;
        final progress = totalDays > 0 ? completedCount / totalDays : 0.0;

        return Dismissible(
          key: Key(habit.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            await NotificationService().cancelNotification(
              4000 + habit.id.hashCode,
            );
            await _db.deleteHabit(habit.id);
            await _loadAll();
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            habit.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                habit.motivation,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final today = DateTime.now();
                          List<DateTime> newDays = List.from(
                            habit.completedDays,
                          );
                          if (isCompleted) {
                            newDays.removeWhere(
                              (d) =>
                                  d.year == today.year &&
                                  d.month == today.month &&
                                  d.day == today.day,
                            );
                            await _db.updateHabit(
                              habit.copyWith(completedDays: newDays),
                            );
                            await _loadAll();
                          } else {
                            newDays.add(today);
                            await _db.updateHabit(
                              habit.copyWith(completedDays: newDays),
                            );
                            await _loadAll();
                            if (context.mounted) {
                              final newStreak = habit
                                  .copyWith(completedDays: newDays)
                                  .currentStreak;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    newStreak > 1
                                        ? '🔥 Harika! $newStreak gün seri devam ediyor!'
                                        : '✅ ${habit.title} bugün tamamlandı!',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.close,
                            color: isCompleted ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    color: isCompleted ? Colors.green : const Color(0xFF6C63FF),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 16,
                          ),
                          Text(
                            ' $streak gün seri',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$completedCount / $totalDays gün tamamlandı',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildWeekCalendar(habit),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekCalendar(Habit habit) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final isCompleted = habit.completedDays.any(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
        final isToday =
            day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;

        return Column(
          children: [
            Text(
              DateFormat('E').format(day)[0],
              style: TextStyle(
                fontSize: 10,
                color: isToday ? const Color(0xFF6C63FF) : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isToday
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: const Color(0xFF6C63FF), width: 1.5)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        );
      }),
    );
  }

  void _showWeightReminderDialog() async {
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('⚖️ Kilo Hatırlatıcısı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Her gün hangi saatte kilo ölçüm hatırlatması gönderelim?',
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) set(() => selectedTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      Text(
                        selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                await NotificationService().scheduleWeightReminder(
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Her gün ${selectedTime.format(context)}\'de hatırlatacağım! ⚖️',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTargetWeightDialog() {
    final targetC = TextEditingController(
      text: _targetWeight?.toStringAsFixed(1) ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedef Kilo'),
        content: TextField(
          controller: targetC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hedef kilo (kg)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(targetC.text.replaceAll(',', '.'));
              if (value == null) {
                _showHealthMessage(
                  'Geçerli bir hedef kilo gir.',
                  isError: true,
                );
                return;
              }
              try {
                await _db.saveHealthGoal(targetWeight: value);
                await _loadAll();
                if (context.mounted) {
                  Navigator.pop(context);
                  _showHealthMessage('Hedef kilo kaydedildi.');
                }
              } catch (_) {
                _showHealthMessage('Hedef kilo kaydedilemedi.', isError: true);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showBodyFatReminderDialog() async {
    var selectedDay = DateTime.monday;
    var selectedTime = const TimeOfDay(hour: 9, minute: 0);
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          title: const Text('Yağ Oranı Hatırlatıcısı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Ölçüm günü',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  days.length,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(days[index]),
                  ),
                ),
                onChanged: (value) => set(() => selectedDay = value ?? 1),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(selectedTime.format(context)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) set(() => selectedTime = time);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await NotificationService().scheduleBodyFatReminder(
                  weekday: selectedDay,
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBodyFatMeasurement([HealthRecord? existing]) {
    String formatMeasurement(double? value) =>
        value == null ? '' : value.toStringAsFixed(1);

    final weightC = TextEditingController(
      text: formatMeasurement(existing?.weight),
    );
    final heightC = TextEditingController(
      text: formatMeasurement(existing?.height),
    );
    final waistC = TextEditingController(
      text: formatMeasurement(existing?.waist),
    );
    final neckC = TextEditingController(
      text: formatMeasurement(existing?.neck),
    );
    final hipC = TextEditingController(text: formatMeasurement(existing?.hip));
    String gender = existing?.gender ?? 'male';

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
                  'Bilimsel Yağ Oranı Ölçümü',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'male', label: Text('Erkek')),
                    ButtonSegment(value: 'female', label: Text('Kadın')),
                  ],
                  selected: {gender},
                  onSelectionChanged: (value) =>
                      set(() => gender = value.first),
                ),
                const SizedBox(height: 12),
                _numberField(
                  weightC,
                  'Kilo (kg)',
                  onChanged: (_) => set(() {}),
                ),
                _numberField(heightC, 'Boy (cm)', onChanged: (_) => set(() {})),
                _numberField(
                  neckC,
                  'Boyun ölçüsü (cm)',
                  onChanged: (_) => set(() {}),
                ),
                _numberField(
                  waistC,
                  'Bel ölçüsü (cm)',
                  onChanged: (_) => set(() {}),
                ),
                if (gender == 'female')
                  _numberField(
                    hipC,
                    'Kalça ölçüsü (cm)',
                    onChanged: (_) => set(() {}),
                  ),
                _bodyFatPreview(
                  gender: gender,
                  weight: weightC.text,
                  height: heightC.text,
                  waist: waistC.text,
                  neck: neckC.text,
                  hip: hipC.text,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final weight = _parseDouble(weightC.text);
                      final height = _parseDouble(heightC.text);
                      final waist = _parseDouble(waistC.text);
                      final neck = _parseDouble(neckC.text);
                      final hip = _parseDouble(hipC.text);
                      if (weight == null ||
                          height == null ||
                          waist == null ||
                          neck == null ||
                          (gender == 'female' && hip == null)) {
                        _showHealthMessage(
                          'Navy formülü için gerekli ölçüleri doldurmalısın.',
                          isError: true,
                        );
                        return;
                      }
                      try {
                        final fat = _bodyFatService.calculateAceNavyBodyFat(
                          gender: gender,
                          heightCm: height,
                          waistCm: waist,
                          neckCm: neck,
                          hipCm: hip,
                        );
                        final clampedFat = fat.clamp(2, 75).toDouble();
                        final ffmi = _bodyFatService.calculateFfmi(
                          weightKg: weight,
                          heightCm: height,
                          bodyFatPercentage: clampedFat,
                        );
                        final record = HealthRecord(
                          id: existing?.id ?? _uuid.v4(),
                          weight: weight,
                          date: existing?.date ?? DateTime.now(),
                          height: height,
                          waist: waist,
                          neck: neck,
                          hip: hip,
                          shoulder: existing?.shoulder,
                          chest: existing?.chest,
                          arm: existing?.arm,
                          thigh: existing?.thigh,
                          calf: existing?.calf,
                          gender: gender,
                          bodyFatPercentage: clampedFat,
                          ffmi: ffmi,
                        );
                        if (existing == null) {
                          await _db.insertHealthRecord(record);
                        } else {
                          await _db.updateHealthRecord(record);
                        }
                        await _loadAll();
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showHealthMessage('Yağ oranı ölçümü kaydedildi.');
                        }
                      } catch (_) {
                        _showHealthMessage(
                          'Ölçüm kaydedilemedi. Değerleri kontrol et.',
                          isError: true,
                        );
                      }
                    },
                    child: Text(
                      existing == null ? 'Hesapla ve Kaydet' : 'Güncelle',
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

  Widget _bodyFatPreview({
    required String gender,
    required String weight,
    required String height,
    required String waist,
    required String neck,
    required String hip,
  }) {
    final parsedWeight = _parseDouble(weight);
    final parsedHeight = _parseDouble(height);
    final parsedWaist = _parseDouble(waist);
    final parsedNeck = _parseDouble(neck);
    final parsedHip = _parseDouble(hip);

    if (parsedWeight == null ||
        parsedHeight == null ||
        parsedWaist == null ||
        parsedNeck == null ||
        (gender == 'female' && parsedHip == null)) {
      return const SizedBox.shrink();
    }

    try {
      final fat = _bodyFatService.calculateAceNavyBodyFat(
        gender: gender,
        heightCm: parsedHeight,
        waistCm: parsedWaist,
        neckCm: parsedNeck,
        hipCm: parsedHip,
      );
      final clampedFat = fat.clamp(2, 75).toDouble();
      final ffmi = _bodyFatService.calculateFfmi(
        weightKg: parsedWeight,
        heightCm: parsedHeight,
        bodyFatPercentage: clampedFat,
      );

      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: _metricPill(
                'Yağ Oranı',
                '%${clampedFat.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _metricPill('FFMI', ffmi.toStringAsFixed(2))),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  double? _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.'));
  }

  void _showHealthMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ignore: unused_element
  void _showAddWeight() {
    final weightC = TextEditingController();
    final noteC = TextEditingController();

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
            const Text(
              'Kilo Ekle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kilo (kg)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteC,
              decoration: InputDecoration(
                labelText: 'Not (opsiyonel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                  final weight = _parseDouble(weightC.text);
                  if (weight == null) {
                    _showHealthMessage('Geçerli bir kilo gir.', isError: true);
                    return;
                  }
                  try {
                    final record = HealthRecord(
                      id: _uuid.v4(),
                      weight: weight,
                      date: DateTime.now(),
                      note: noteC.text.isNotEmpty ? noteC.text : null,
                    );
                    await _db.insertHealthRecord(record);
                    await _loadAll();
                    if (context.mounted) {
                      Navigator.pop(context);
                      _showHealthMessage('Kilo kaydı eklendi.');
                    }
                  } catch (_) {
                    _showHealthMessage('Kilo kaydı eklenemedi.', isError: true);
                  }
                },
                child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabit() {
    final titleC = TextEditingController();
    final motivationC = TextEditingController();
    String selectedEmoji = '🚭';
    String selectedType = 'quit';
    TimeOfDay? reminderTime;

    final habitTemplates = [
      {
        'emoji': '🚭',
        'title': 'Sigara Bırak',
        'type': 'quit',
        'motivation': 'Sağlıklı bir yaşam için',
      },
      {
        'emoji': '🏃',
        'title': 'Spor Yap',
        'type': 'build',
        'motivation': 'Her gün daha güçlü',
      },
      {
        'emoji': '💧',
        'title': 'Su İç',
        'type': 'build',
        'motivation': '8 bardak su içiyorum',
      },
      {
        'emoji': '📚',
        'title': 'Kitap Oku',
        'type': 'build',
        'motivation': 'Her gün öğreniyorum',
      },
      {
        'emoji': '🧘',
        'title': 'Meditasyon',
        'type': 'build',
        'motivation': 'Zihinsel huzur için',
      },
      {
        'emoji': '🍎',
        'title': 'Sağlıklı Ye',
        'type': 'build',
        'motivation': 'Vücuduma iyi bakıyorum',
      },
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
                  'Alışkanlık Ekle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hızlı Seç:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: habitTemplates.map((t) {
                    return GestureDetector(
                      onTap: () {
                        set(() {
                          selectedEmoji = t['emoji']!;
                          selectedType = t['type']!;
                          titleC.text = t['title']!;
                          motivationC.text = t['motivation']!;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedEmoji == t['emoji']
                              ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: selectedEmoji == t['emoji']
                              ? Border.all(color: const Color(0xFF6C63FF))
                              : null,
                        ),
                        child: Text('${t['emoji']} ${t['title']}'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: 'Alışkanlık Adı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivationC,
                  decoration: InputDecoration(
                    labelText: 'Motivasyon cümlesi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm, color: Color(0xFF6C63FF)),
                  title: Text(
                    reminderTime != null
                        ? 'Hatırlatıcı: ${reminderTime!.format(context)}'
                        : 'Günlük Hatırlatıcı Ekle',
                  ),
                  trailing: reminderTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => set(() => reminderTime = null),
                        )
                      : null,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (time != null) {
                      set(() => reminderTime = time);
                    }
                  },
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
                      if (titleC.text.isEmpty) return;
                      final habit = Habit(
                        id: _uuid.v4(),
                        title: titleC.text,
                        type: selectedType,
                        startDate: DateTime.now(),
                        completedDays: [],
                        emoji: selectedEmoji,
                        motivation: motivationC.text,
                      );
                      await _db.insertHabit(habit);
                      if (reminderTime != null) {
                        await NotificationService().scheduleHabitReminder(
                          id: habit.id.hashCode,
                          habitName: habit.title,
                          hour: reminderTime!.hour,
                          minute: reminderTime!.minute,
                        );
                      }
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
      ),
    );
  }
}

enum _BodyMeasurementField {
  weight,
  height,
  neck,
  shoulder,
  chest,
  arm,
  waist,
  hip,
  thigh,
  calf,
}
