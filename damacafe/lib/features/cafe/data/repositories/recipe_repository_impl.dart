import 'package:hive_ce/hive.dart';

import '../models/recipe_hive_model.dart';
import 'recipe_repository.dart';

const String _recipeProgressKey = 'recipe_progress';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl(this._box);

  final Box<RecipeHiveModel> _box;

  @override
  Future<Set<String>> loadMasteredRecipeIds() async {
    final model = _box.get(_recipeProgressKey);
    return model?.masteredRecipeIds.toSet() ?? <String>{};
  }

  @override
  Future<void> markMastered(String recipeId) async {
    final current = await loadMasteredRecipeIds();
    final updated = {...current, recipeId};
    await _box.put(
      _recipeProgressKey,
      RecipeHiveModel(masteredRecipeIds: updated.toList()),
    );
  }
}
