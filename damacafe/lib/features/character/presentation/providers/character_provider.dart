import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/game_balance.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../cafe/domain/entities/shop_item.dart';
import '../../data/models/character_hive_model.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/character_repository_impl.dart';
import '../../domain/character_decay.dart';
import '../../domain/entities/character.dart';
import '../../domain/ingredient.dart';

part 'character_provider.g.dart';

@riverpod
CharacterRepository characterRepository(Ref ref) {
  return CharacterRepositoryImpl(
    Hive.box<CharacterHiveModel>(HiveBoxes.character),
  );
}

/// 집/카페 화면이 공통으로 구독하는 캐릭터 상태 notifier.
/// 케어 액션, 상점 구매, 정산 반영이 전부 이 notifier를 통해 이루어진다.
/// keepAlive: 화면 전환 중에도 캐릭터 상태(코인 등)가 유실되지 않아야 한다.
@Riverpod(keepAlive: true)
class CharacterNotifier extends _$CharacterNotifier {
  @override
  Future<Character> build() async {
    final repository = ref.watch(characterRepositoryProvider);
    final loaded = await repository.load();
    final decayed = applyIdleDecay(loaded, DateTime.now());
    if (decayed != loaded) {
      await repository.save(decayed);
    }
    return decayed;
  }

  /// 보유한 상점 아이템의 총 케어 보너스. 카테고리 구분 없이 모든 케어 액션에 동일 적용.
  int _totalCareBonus(Character character) {
    return kShopCatalog
        .where((item) => character.ownedItemIds.contains(item.id))
        .fold(0, (sum, item) => sum + item.careBonus);
  }

  Future<void> _persist(Character character) async {
    state = AsyncData(character);
    await ref.read(characterRepositoryProvider).save(character);
  }

  Future<void> feed(String ingredientId) async {
    final current = await future;
    final ingredient = kIngredients.firstWhere((i) => i.id == ingredientId);
    final baseGain = switch (ingredient.preference) {
      IngredientPreference.liked => GameBalance.feedGainLiked,
      IngredientPreference.neutral => GameBalance.feedGainNeutral,
      IngredientPreference.disliked => GameBalance.feedGainDisliked,
    };
    final gain = baseGain + _totalCareBonus(current);
    await _persist(
      current.copyWith(
        satiation: (current.satiation + gain).clamp(
          GameBalance.minGauge,
          GameBalance.maxGauge,
        ),
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> washTap() async {
    final current = await future;
    final gain = GameBalance.washGainPerTap + _totalCareBonus(current);
    await _persist(
      current.copyWith(
        cleanliness: (current.cleanliness + gain).clamp(
          GameBalance.minGauge,
          GameBalance.maxGauge,
        ),
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> completePlayMinigame() async {
    final current = await future;
    final affectionGain = GameBalance.playAffectionGain + _totalCareBonus(current);
    await _persist(
      current.copyWith(
        affection: (current.affection + affectionGain).clamp(
          GameBalance.minGauge,
          GameBalance.maxGauge,
        ),
        coins: current.coins + GameBalance.playCoinReward,
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> purchaseItem(ShopItem item) async {
    final current = await future;
    if (current.coins < item.price || current.ownedItemIds.contains(item.id)) {
      return false;
    }
    await _persist(
      current.copyWith(
        coins: current.coins - item.price,
        ownedItemIds: [...current.ownedItemIds, item.id],
      ),
    );
    return true;
  }

  /// 퇴근 정산 결과(코인 획득분)를 캐릭터 상태에 반영한다.
  Future<void> applySettlement({required int coinsEarned}) async {
    final current = await future;
    await _persist(current.copyWith(coins: current.coins + coinsEarned));
  }
}
