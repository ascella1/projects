/// 로컬/원격 구현을 교체할 수 있도록 인터페이스로 분리한다.
abstract class RecipeRepository {
  Future<Set<String>> loadMasteredRecipeIds();
  Future<void> markMastered(String recipeId);
}
