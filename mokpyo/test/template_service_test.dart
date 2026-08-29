import 'package:flutter_test/flutter_test.dart';
import 'package:mokpyo/core/services/template_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('흔한 목표(다이어트)는 health 템플릿에 매칭되어 15개 퀘스트를 반환한다', () async {
    final match = await TemplateService.matchGoal('다이어트 10키로 하기', 'g_test');

    expect(match, isNotNull);
    expect(match!.stats, ['health']);
    expect(match.quests.length, 15);
    expect(match.quests.first.title, contains('다이어트 10키로 하기'));
    expect(
      match.quests.any((q) => q.title.contains('물 많이 마시기')),
      isTrue,
    );
  });

  test('흔하지 않은 목표는 매칭되는 템플릿이 없어 null을 반환한다', () async {
    final match =
        await TemplateService.matchGoal('화성에 식민지 건설하기', 'g_test');

    expect(match, isNull);
  });
}
