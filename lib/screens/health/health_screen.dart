import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/health_record.dart';
import '../../models/habit.dart';
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
  final _db = DatabaseService();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final records = await _db.getHealthRecords();
    final habits = await _db.getHabits();
    setState(() {
      _records = records;
      _habits = habits;
    });
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
          tabs: const [
            Tab(text: 'Kilo Takibi'),
            Tab(text: 'Alışkanlıklar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWeight(), _buildHabits()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddWeight();
          } else {
            _showAddHabit();
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

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
                  if (weightC.text.isEmpty) return;
                  final record = HealthRecord(
                    id: _uuid.v4(),
                    weight: double.parse(weightC.text.replaceAll(',', '.')),
                    date: DateTime.now(),
                    note: noteC.text.isNotEmpty ? noteC.text : null,
                  );
                  await _db.insertHealthRecord(record);
                  await _loadAll();
                  if (context.mounted) Navigator.pop(context);
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
