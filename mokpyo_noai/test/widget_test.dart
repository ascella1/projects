import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mokpyo_noai/main.dart';

void main() {
  testWidgets('온보딩을 완료하지 않은 상태에서는 목표 위저드의 캐릭터 선택 단계가 보인다',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('선택 완료'), findsOneWidget);
    expect(find.text('🐱'), findsOneWidget);
    expect(find.text('🐶'), findsOneWidget);
    expect(find.text('🐰'), findsOneWidget);
    expect(find.text('🦊'), findsOneWidget);
  });
}
