import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'finvia_channel',
    String channelName = 'Finvia Bildirimleri',
    String channelDesc = 'Finvia uygulama bildirimleri',
  }) async {
    final androidDetails = _getAndroidDetails(
      channelId: channelId,
      channelName: channelName,
      channelDesc: channelDesc,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }

  Future<void> scheduleNoteReminder({
    required int id,
    required String noteTitle,
    required String noteBody,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;
    final delay = scheduledTime.difference(DateTime.now());
    Future.delayed(delay, () async {
      await showNotification(
        id: 1000 + id,
        title: '📝 $noteTitle',
        body: noteBody,
        channelId: 'notes_channel',
        channelName: 'Not Hatirlatmalari',
        channelDesc: 'Notlariniz icin hatirlatmalar',
      );
    });
  }

  Future<void> scheduleSubscriptionReminder({
    required int id,
    required String subscriptionName,
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    DateTime nextReminder = DateTime(
      now.year,
      now.month,
      dayOfMonth,
      hour,
      minute,
    );

    if (nextReminder.isBefore(now)) {
      nextReminder = DateTime(
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        dayOfMonth,
        hour,
        minute,
      );
    }

    final delay = nextReminder.difference(now);
    Future.delayed(delay, () async {
      await showNotification(
        id: 2000 + id,
        title: '💳 Abonelik Odemesi',
        body: 'Bugun $subscriptionName aboneliğinin odemesi var! Gider girmeyi unutmayalim 😊',
        channelId: 'subscription_channel',
        channelName: 'Abonelik Hatirlatmalari',
        channelDesc: 'Abonelik odeme hatirlatmalari',
      );
    });
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

    final direction = isUpperAlarm ? '🚀 Yukseldi' : '📉 Dustu';
    final message = isUpperAlarm
        ? '$companyName ($symbol) hedef fiyatiniz olan ${targetPrice.toStringAsFixed(2)} seviyesine ulasti!'
        : '$companyName ($symbol) hedef fiyatiniz olan ${targetPrice.toStringAsFixed(2)} seviyesine dustu!';

    await showNotification(
      id: 3000 + symbol.hashCode.abs() % 1000,
      title: '$direction - $symbol',
      body: message,
      channelId: 'stock_channel',
      channelName: 'Hisse Alarmlari',
      channelDesc: 'Hisse senedi fiyat alarmlari',
    );
  }

  Future<void> scheduleWeightReminder({
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);
    Future.delayed(delay, () async {
      await showNotification(
        id: 4001,
        title: '⚖️ Kilo Olcum Zamani!',
        body: 'Gunaydin! Gunluk kilonuzu olcmeyi unutmayin 💪',
        channelId: 'health_channel',
        channelName: 'Saglik Hatirlatmalari',
        channelDesc: 'Gunluk saglik takibi hatirlatmalari',
      );
    });
  }

  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final delay = scheduledTime.difference(now);
    Future.delayed(delay, () async {
      await showNotification(
        id: 4000 + id,
        title: '✅ Aliskanlik Zamani!',
        body: '$habitName aliskanligini tamamlamayi unutma!',
        channelId: 'habit_channel',
        channelName: 'Aliskanlik Hatirlatmalari',
        channelDesc: 'Gunluk aliskanlik takibi hatirlatmalari',
      );
    });
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
