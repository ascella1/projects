import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mokpyo_noai/core/services/level_config_service.dart';
import 'package:mokpyo_noai/features/quest/data/repositories/quest_repository_impl.dart';
import 'package:mokpyo_noai/features/quest/domain/entities/quest_entity.dart';
import 'package:mokpyo_noai/features/quest/presentation/providers/user_provider.dart';
import 'package:mokpyo_noai/main.dart';

// 여러 화면 크기(작은 폰 ~ 큰 폰)에서 5개 탭 모두 렌더링했을 때
// RenderFlex overflow 같은 예외가 발생하지 않는지 확인한다.
const _sizes = <Size>[
  Size(320, 568), // iPhone SE(1세대)급 작은 화면
  Size(360, 640), // 흔한 소형 안드로이드
  Size(390, 844), // 표준 iPhone
  Size(414, 896), // 큰 iPhone
  Size(480, 800), // 가로세로 비율이 다른 안드로이드 태블릿/패블릿
];

Quest _quest(int depth, String title, {QuestStatus status = QuestStatus.todo}) =>
    Quest(
      id: 'q_${depth}_$title',
      goalId: 'g_active',
      title: title,
      depth: depth,
      status: status,
      difficulty: QuestDifficulty.easy,
      rewardExp: 10,
      rewardStats: const ['career', 'knowledge'],
      dueDate: DateTime.now(),
      completedAt: status == QuestStatus.completed ? DateTime.now() : null,
    );

void main() {
  for (final size in _sizes) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()} 화면에서 5개 탭 모두 오버플로우 없이 렌더링된다',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'noai_rpg_user_state_v2': jsonEncode(const UserState(
          hasCompletedOnboarding: true,
          characterType: 'fox',
          goal: '아주 길고 긴 목표 제목을 넣어서 텍스트 오버플로우가 나는지 확인해보는 테스트용 목표입니다',
          recommendedStats: ['knowledge', 'career', 'health', 'money', 'communication'],
          level: 25,
          exp: 40,
          boxesCount: 3,
          inventory: ['crown', 'sunglasses'],
          statLevels: {
            'knowledge': 12,
            'career': 8,
            'health': 3,
            'money': 20,
            'communication': 1,
          },
          lastLoginDate: '2026-07-13',
          currentStreak: 4,
          lastRoutineDate: '2026-07-13',
          lastGreetedDate: '2026-07-13',
        ).toJson()),
      });
      await LevelConfigService.load();
      await QuestRepositoryImpl().createQuests([
        _quest(1, '10kg 다이어트'),
        _quest(2, '매일 30분 이상 운동하기'),
        _quest(2, '식습관 조절하기 아주 길게 써보는 중목표 텍스트'),
        _quest(3, '주 3회 헬스장 가기'),
        _quest(4, '물 500ml 마시기', status: QuestStatus.completed),
        _quest(4, '아침 스트레칭 10분'),
        _quest(4, '영단어 10개 외우기'),
      ]);

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '나의 정원 탭');

      for (final tabIcon in [
        Icons.card_giftcard,
        Icons.backpack,
        Icons.emoji_events,
        Icons.map,
      ]) {
        await tester.tap(find.byIcon(tabIcon), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tabIcon 탭');
      }
    });
  }

  testWidgets('320x568 화면에서 목표 입력 위저드도 오버플로우 없이 렌더링된다',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await LevelConfigService.load();

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '캐릭터 선택 단계');

    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '대목표 입력 단계');

    await tester.enterText(find.byType(TextField).first, '10kg 다이어트');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '스탯 선택 단계');
  });
}
