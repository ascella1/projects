import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyetaek_app/app.dart';

void main() {
  testWidgets('shows onboarding first launch screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HyetaekApp()));
    await tester.pumpAndSettle();

    expect(find.text('언제 태어나셨나요?'), findsOneWidget);
  });
}
