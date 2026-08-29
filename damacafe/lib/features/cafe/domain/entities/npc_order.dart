import 'recipe.dart';

/// 초반 MVP는 고정 NPC 손님을 사용한다. 이후 단계에서 다른 유저 캐릭터로
/// 교체하는 비동기 소셜 구조로 확장할 수 있도록, 주문은 NPC 이름 + 레시피만 알면 된다.
class NpcOrder {
  const NpcOrder({required this.npcName, required this.recipe});

  final String npcName;
  final Recipe recipe;
}

const List<String> kNpcNames = ['모카', '두부', '초코'];
