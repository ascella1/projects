/// MVP 레시피 카탈로그. 처음 만들 때는 미니게임을 거쳐야 하고,
/// 한 번 클리어하면 숙련도가 생겨 이후엔 미니게임 없이 즉시 제작 가능하다.
class Recipe {
  const Recipe({required this.id, required this.name, required this.reward});

  final String id;
  final String name;

  /// 손님에게 받는 기본 코인 보상 (컨디션 페널티 적용 전 기준값).
  final int reward;
}

const List<Recipe> kRecipes = [
  Recipe(id: 'latte', name: '카페라떼', reward: 15),
  Recipe(id: 'sandwich', name: '샌드위치', reward: 25),
];
