/// 먹이주기 MVP 범위: 재료 3종, 각각 캐릭터의 선호도가 고정되어 있다.
enum IngredientPreference { liked, neutral, disliked }

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.preference,
  });

  final String id;
  final String name;
  final IngredientPreference preference;
}

const List<Ingredient> kIngredients = [
  Ingredient(id: 'fish', name: '생선', preference: IngredientPreference.liked),
  Ingredient(id: 'vegetable', name: '채소', preference: IngredientPreference.neutral),
  Ingredient(id: 'medicine', name: '영양제', preference: IngredientPreference.disliked),
];
