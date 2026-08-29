import 'dart:math';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../work_transition/domain/condition_calculator.dart';
import '../../../work_transition/presentation/providers/work_session_provider.dart';
import '../../data/models/recipe_hive_model.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/entities/npc_order.dart';
import '../../domain/entities/recipe.dart';

part 'cafe_provider.g.dart';

@riverpod
RecipeRepository recipeRepository(Ref ref) {
  return RecipeRepositoryImpl(Hive.box<RecipeHiveModel>(HiveBoxes.recipe));
}

class CafeState {
  const CafeState({required this.masteredRecipeIds, required this.currentOrder});

  final Set<String> masteredRecipeIds;
  final NpcOrder currentOrder;

  CafeState copyWith({Set<String>? masteredRecipeIds, NpcOrder? currentOrder}) {
    return CafeState(
      masteredRecipeIds: masteredRecipeIds ?? this.masteredRecipeIds,
      currentOrder: currentOrder ?? this.currentOrder,
    );
  }
}

/// 카페 화면의 주문/레시피 숙련도 상태. 코인은 여기서 캐릭터에 바로 반영하지 않고
/// work_session_provider에 누적시켰다가 퇴근 시 한 번에 정산한다 (실시간 노출 X).
/// keepAlive: 상점 화면을 오가는 동안에도 현재 주문/숙련도 상태가 유지되어야 한다.
@Riverpod(keepAlive: true)
class CafeNotifier extends _$CafeNotifier {
  final Random _random = Random();

  @override
  Future<CafeState> build() async {
    final repository = ref.watch(recipeRepositoryProvider);
    final mastered = await repository.loadMasteredRecipeIds();
    return CafeState(masteredRecipeIds: mastered, currentOrder: _generateOrder());
  }

  NpcOrder _generateOrder() {
    final recipe = kRecipes[_random.nextInt(kRecipes.length)];
    final npcName = kNpcNames[_random.nextInt(kNpcNames.length)];
    return NpcOrder(npcName: npcName, recipe: recipe);
  }

  OrderOutcome _evaluateCurrentOrder(Recipe recipe) {
    final conditionScore = ref.read(workSessionProvider).conditionScore;
    return evaluateOrder(recipeReward: recipe.reward, conditionScore: conditionScore);
  }

  /// 이미 숙련된 레시피: 미니게임 없이 바로 서빙.
  Future<OrderOutcome> serveMasteredOrder() async {
    final current = await future;
    final outcome = _evaluateCurrentOrder(current.currentOrder.recipe);
    ref.read(workSessionProvider.notifier).recordOrderResult(outcome);
    state = AsyncData(current.copyWith(currentOrder: _generateOrder()));
    return outcome;
  }

  /// 요리 미니게임 클리어 후 호출: 레시피를 숙련 처리하고 서빙한다.
  Future<OrderOutcome> completeCookingMinigame(String recipeId) async {
    final current = await future;
    await ref.read(recipeRepositoryProvider).markMastered(recipeId);
    final outcome = _evaluateCurrentOrder(current.currentOrder.recipe);
    ref.read(workSessionProvider.notifier).recordOrderResult(outcome);
    state = AsyncData(
      current.copyWith(
        masteredRecipeIds: {...current.masteredRecipeIds, recipeId},
        currentOrder: _generateOrder(),
      ),
    );
    return outcome;
  }
}
