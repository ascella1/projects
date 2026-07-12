import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mokpyo_noai/core/services/notification_service.dart';
import 'package:mokpyo_noai/features/quest/domain/entities/quest_entity.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

Quest _quest(String id, QuestStatus status) => Quest(
      id: id,
      goalId: 'g_active',
      title: id,
      depth: 4,
      status: status,
      difficulty: QuestDifficulty.easy,
      rewardExp: 10,
      rewardStats: const ['career'],
      dueDate: DateTime.now(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  // 실제 앱에서는 플러그인 등록기가 자동으로 호출하지만, 순수 유닛 테스트
  // 환경에서는 플랫폼 채널 구현체를 수동으로 등록해줘야 한다.
  AndroidFlutterLocalNotificationsPlugin.registerWith();

  late List<MethodCall> calls;
  late NotificationService service;

  setUp(() async {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
        case 'requestNotificationsPermission':
          return true;
        default:
          return null;
      }
    });
    service = NotificationService.instance;
    await service.init();
    calls.clear(); // init() 호출 자체(initialize/권한요청)는 검증 대상이 아니므로 리셋
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('일일 퀘스트가 비어있으면 예약하지 않고 취소만 한다', () async {
    await service.scheduleTodayReminderIfNeeded([]);
    expect(calls.any((c) => c.method == 'zonedSchedule'), isFalse);
    expect(calls.any((c) => c.method == 'cancel'), isTrue);
  });

  test('일일 퀘스트를 전부 완료했으면 알림을 취소한다', () async {
    await service.scheduleTodayReminderIfNeeded([
      _quest('a', QuestStatus.completed),
      _quest('b', QuestStatus.completed),
    ]);
    expect(calls.any((c) => c.method == 'zonedSchedule'), isFalse);
    expect(calls.any((c) => c.method == 'cancel'), isTrue);
  });

  test('미완료 일일 퀘스트가 있으면 오늘자 알림을 예약한다', () async {
    await service.scheduleTodayReminderIfNeeded([
      _quest('a', QuestStatus.completed),
      _quest('b', QuestStatus.todo),
    ]);
    expect(calls.any((c) => c.method == 'zonedSchedule'), isTrue);
  });

  test('cancelTodayReminder()는 cancel을 호출한다', () async {
    await service.cancelTodayReminder();
    expect(calls.any((c) => c.method == 'cancel'), isTrue);
  });
}
