import 'package:hive_ce/hive.dart';

part 'recipe_hive_model.g.dart';

/// 레시피 숙련도(한 번 클리어했는지 여부)를 저장하는 Hive 모델.
@HiveType(typeId: 1)
class RecipeHiveModel extends HiveObject {
  RecipeHiveModel({required this.masteredRecipeIds});

  @HiveField(0)
  List<String> masteredRecipeIds;
}
