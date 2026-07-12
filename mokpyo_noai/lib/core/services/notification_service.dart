import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../features/quest/domain/entities/quest_entity.dart';

// 하루 일일 퀘스트를 다 끝내지 않으면 매일 고정 시각에 알림을 보낸다.
// 개인용 단일 사용자 앱이므로 한국 시간대(Asia/Seoul)를 그대로 고정한다.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final NotificationService instance = NotificationService();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _reminderHour = 21;
  static const _reminderMinute = 0;
  static const _channelId = 'daily_quest_reminder';
  static const _channelName = '일일 퀘스트 알림';

  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService 초기화 실패: $e');
      _initialized = false;
    }
  }

  int _todayId() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  // 오늘의 일일 퀘스트(depth==4)가 전부 완료됐으면 알림을 취소하고,
  // 아직 남았고 알림 시각이 지나지 않았으면 오늘 21:00 알림을 예약한다.
  Future<void> scheduleTodayReminderIfNeeded(List<Quest> dailyQuests) async {
    if (!_initialized) return;

    final allDone = dailyQuests.isNotEmpty &&
        dailyQuests.every((q) => q.status == QuestStatus.completed);
    if (dailyQuests.isEmpty || allDone) {
      await cancelTodayReminder();
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final when = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, _reminderHour, _reminderMinute);
    if (when.isBefore(now)) {
      await cancelTodayReminder();
      return;
    }

    try {
      await _plugin.zonedSchedule(
        id: _todayId(),
        title: '목표 정원',
        body: '이거 해야돼~ 오늘의 일일 퀘스트가 아직 안 끝났어요 🌱',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('알림 예약 실패: $e');
    }
  }

  Future<void> cancelTodayReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(id: _todayId());
  }
}
