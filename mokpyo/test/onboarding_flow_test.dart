import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mokpyo/main.dart';

Future<void> _goThroughCharacterStep(WidgetTester tester) async {
  expect(find.text('선택 완료'), findsOneWidget);
  await tester.tap(find.text('🦊'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('선택 완료'));
  await tester.pumpAndSettle();
}

Future<void> _enterGoalAndSubmit(WidgetTester tester, String goal) async {
  expect(find.text('AI 목표 분석 시작'), findsOneWidget);
  await tester.enterText(find.byType(TextField), goal);
  await tester.tap(find.text('AI 목표 분석 시작'));
  // generateAndSaveQuests is async (asset load / http); pump repeatedly
  // instead of pumpAndSettle so we don't hang forever if it were to await
  // a real network call.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  final snackTexts =
      find.byType(SnackBar).evaluate().map((e) => e.widget).toList();
  // ignore: avoid_print
  print('DEBUG snackbars: $snackTexts');
}

Future<void> _setPhoneSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('온보딩: 흔한 목표(다이어트)는 템플릿 퀘스트를 보여준다',
      (tester) async {
    await _setPhoneSize(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );
    await tester.pumpAndSettle();

    await _goThroughCharacterStep(tester);
    await _enterGoalAndSubmit(tester, '다이어트 10키로 하기');

    expect(find.text('✨ 분석 완료 ✨'), findsOneWidget);
    expect(find.textContaining('다이어트 10키로 하기'), findsWidgets);
    // AI 실패 스낵바가 뜨지 않아야 한다 = AI를 아예 호출하지 않고 템플릿을 썼다는 뜻
    expect(find.textContaining('AI 생성 실패'), findsNothing);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_diet_result.png'),
    );
  });

  testWidgets('온보딩: 흔하지 않은 목표는 (키 없을 때) 기본 퀘스트로 폴백한다',
      (tester) async {
    await _setPhoneSize(tester);
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );
    await tester.pumpAndSettle();

    await _goThroughCharacterStep(tester);
    await _enterGoalAndSubmit(tester, '화성에 식민지 건설하기');

    expect(find.text('✨ 분석 완료 ✨'), findsOneWidget);
    expect(find.textContaining('화성에 식민지 건설하기'), findsWidgets);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_uncommon_result.png'),
    );
  });
}
