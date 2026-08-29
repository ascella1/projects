import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:line_slice/data/run_repository.dart';
import 'package:line_slice/main.dart';

void main() {
  setUpAll(() async {
    Hive.init('.dart_tool/test_hive');
    await Hive.openBox(RunRepository.boxName);
  });

  testWidgets('홈 화면에 타이틀과 시작 버튼이 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LineSliceApp()));
    await tester.pump();

    expect(find.text('라인 슬라이스 런'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
