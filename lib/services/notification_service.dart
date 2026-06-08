import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _noteOffset = 1000;
  static const int _subscriptionOffset = 2000;
  static const int _habitOffset = 4000;
  static const int weightReminderId = 4001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    _initialized = true;
    await _requestAndroidNotificationPermission();
  }

  Future<void> _requestAndroidNotificationPermission() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  int noteReminderId(int id) => _noteOffset + id;
  int subscriptionReminderId(int id) => _subscriptionOffset + id;
  int habitReminderId(int id) => _habitOffset + id;

  int stockNotificationId(String symbol) {
    var hash = 0x811c9dc5;
    for (final unit in symbol.toUpperCase().codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return 3000 + hash % 1000;
  }

  AndroidNotificationDetails _getAndroidDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
    );
  }

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) {
    final androidDetails = _getAndroidDetails(
      channelId: channelId,
      channelName: channelName,
      channelDesc: channelDesc,
    );
    return NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextMonthlyTime(int dayOfMonth, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final safeDay = dayOfMonth.clamp(1, 28);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      safeDay,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        safeDay,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String channelId,
    required String channelName,
    required String channelDesc,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      _details(
        channelId: channelId,
        channelName: channelName,
        channelDesc: channelDesc,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'finvia_channel',
    String channelName = 'Finvia Bildirimleri',
    String channelDesc = 'Finvia uygulama bildirimleri',
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      _details(
        channelId: channelId,
        channelName: channelName,
        channelDesc: channelDesc,
      ),
    );
  }

  Future<void> scheduleNoteReminder({
    required int id,
    required String noteTitle,
    required String noteBody,
    required DateTime scheduledTime,
  }) async {
    final nativeTime = tz.TZDateTime.from(scheduledTime, tz.local);
    if (!nativeTime.isAfter(tz.TZDateTime.now(tz.local))) return;

    await _schedule(
      id: noteReminderId(id),
      title: 'Not Hatırlatıcısı: $noteTitle',
      body: noteBody,
      scheduledTime: nativeTime,
      channelId: 'notes_channel',
      channelName: 'Not Hatırlatmaları',
      channelDesc: 'Notlarınız için hatırlatmalar',
    );
  }

  Future<void> scheduleSubscriptionReminder({
    required int id,
    required String subscriptionName,
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    await _schedule(
      id: subscriptionReminderId(id),
      title: 'Abonelik Ödemesi',
      body: 'Bugün $subscriptionName aboneliğinin ödemesi var.',
      scheduledTime: _nextMonthlyTime(dayOfMonth, hour, minute),
      channelId: 'subscription_channel',
      channelName: 'Abonelik Hatırlatmaları',
      channelDesc: 'Abonelik ödeme hatırlatmaları',
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<void> checkStockAlarm({
    required String symbol,
    required String companyName,
    required double currentPrice,
    required double targetPrice,
    required bool isUpperAlarm,
  }) async {
    final triggered = isUpperAlarm
        ? currentPrice >= targetPrice
        : currentPrice <= targetPrice;

    if (!triggered) return;

    final direction = isUpperAlarm ? 'Yükseldi' : 'Düştü';
    final message = isUpperAlarm
        ? '$companyName ($symbol) hedef fiyatınız olan ${targetPrice.toStringAsFixed(2)} seviyesine ulaştı.'
        : '$companyName ($symbol) hedef fiyatınız olan ${targetPrice.toStringAsFixed(2)} seviyesine düştü.';

    await showNotification(
      id: stockNotificationId(symbol),
      title: '$direction - $symbol',
      body: message,
      channelId: 'stock_channel',
      channelName: 'Hisse Bildirimleri',
      channelDesc: 'Hisse senedi fiyat bildirimleri',
    );
  }

  Future<void> scheduleWeightReminder({
    required int hour,
    required int minute,
  }) async {
    await _schedule(
      id: weightReminderId,
      title: 'Kilo Ölçüm Zamanı',
      body: 'Günlük kilonuzu ölçmeyi unutmayın.',
      scheduledTime: _nextDailyTime(hour, minute),
      channelId: 'health_channel',
      channelName: 'Sağlık Hatırlatmaları',
      channelDesc: 'Günlük sağlık takibi hatırlatmaları',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    await _schedule(
      id: habitReminderId(id),
      title: 'Alışkanlık Zamanı',
      body: '$habitName alışkanlığını tamamlamayı unutma.',
      scheduledTime: _nextDailyTime(hour, minute),
      channelId: 'habit_channel',
      channelName: 'Alışkanlık Hatırlatmaları',
      channelDesc: 'Günlük alışkanlık takibi hatırlatmaları',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }
}
