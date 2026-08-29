import 'package:hive_ce/hive.dart';

import '../../../../core/constants/game_balance.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/entities/character.dart';
import '../models/character_hive_model.dart';
import 'character_repository.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl(this._box);

  final Box<CharacterHiveModel> _box;

  @override
  Future<Character> load() async {
    final model = _box.get(characterHiveKey);
    if (model == null) {
      final fresh = _defaultCharacter();
      await save(fresh);
      return fresh;
    }
    return _toDomain(model);
  }

  @override
  Future<void> save(Character character) async {
    await _box.put(characterHiveKey, _toHive(character));
  }

  Character _defaultCharacter() => Character(
    satiation: GameBalance.maxGauge,
    cleanliness: GameBalance.maxGauge,
    affection: GameBalance.maxGauge,
    coins: 0,
    ownedItemIds: const [],
    lastUpdatedAt: DateTime.now(),
  );

  Character _toDomain(CharacterHiveModel model) => Character(
    satiation: model.satiation,
    cleanliness: model.cleanliness,
    affection: model.affection,
    coins: model.coins,
    ownedItemIds: model.ownedItemIds,
    lastUpdatedAt: model.lastUpdatedAt,
  );

  CharacterHiveModel _toHive(Character character) => CharacterHiveModel(
    satiation: character.satiation,
    cleanliness: character.cleanliness,
    affection: character.affection,
    coins: character.coins,
    ownedItemIds: character.ownedItemIds,
    lastUpdatedAt: character.lastUpdatedAt,
  );
}
