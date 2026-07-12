import 'dart:math';
import '../../../../core/utils/character_util.dart';
import '../../../../core/utils/stat_util.dart';
import '../providers/goal_wizard_provider.dart';

// 위저드의 각 단계에 진입할 때, "바로 이전 단계에서 사용자가 답한 내용"에
// 대한 캐릭터의 한마디 반응을 만든다. 순수 텍스트 투두 앱과 달리 "코칭 받는
// 느낌"을 주기 위한 장치이며, 실제 AI 호출 없이 답변 내용을 문구에 끼워 넣거나
// 개수를 세는 방식으로 반응처럼 보이게 구성한다.
//
// step은 "지금 보여줄 화면"의 인덱스이고, 반환하는 문구는 그 이전 화면(step-1)의
// 답변에 대한 반응이다. step 0(캐릭터 선택)에는 반응할 이전 답변이 없으므로 null.
String? reactionForStep(int step, GoalWizardState state) {
  final rand = Random();
  switch (step) {
    case 1:
      return '${characterLabel(state.characterType)}(을)를 선택하셨군요! 좋은 파트너가 되어드릴게요.';
    case 2:
      if (state.mainGoalTitle.trim().isEmpty) return null;
      final pool = [
        '"${state.mainGoalTitle}"라니, 꽤 도전적인 목표네요!',
        '오, "${state.mainGoalTitle}"! 마음에 드는 목표예요.',
        '"${state.mainGoalTitle}"를 향해 함께 나아가 봐요!',
      ];
      return pool[rand.nextInt(pool.length)];
    case 3:
      if (state.selectedStats.isEmpty) return '능력치를 선택하셨군요!';
      final labels =
          state.selectedStats.map((s) => statInfo(s).label).join(', ');
      return '$labels 능력치를 키우고 싶으시군요! 좋은 선택이에요.';
    case 4:
      final n = state.midGoals.length;
      if (n == 0) return '중목표는 나중에 다시 추가할 수 있어요!';
      return '중목표를 $n개나 세우셨네요, 체계적이에요!';
    case 5:
      final n = state.subGoals.length;
      if (n == 0) return '소목표는 나중에 다시 추가할 수 있어요!';
      return '소목표까지 $n개, 아주 꼼꼼하네요!';
    case 6:
      final n = state.dailyQuests.length;
      return '오늘부터 실천할 습관이 $n개나 있네요. 벌써 기대돼요!';
    default:
      return null;
  }
}
