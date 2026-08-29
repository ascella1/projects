import 'package:hive_ce/hive.dart';

part 'character_hive_model.g.dart';

/// Hive 저장 전용 모델. 도메인 모델(Character)과 분리해서, 나중에 서버 동기화용
/// remote repository를 추가할 때 이 파일만 영향을 받도록 한다.
@HiveType(typeId: 0)
class CharacterHiveModel extends HiveObject {
  CharacterHiveModel({
    required this.satiation,
    required this.cleanliness,
    required this.affection,
    required this.coins,
    required this.ownedItemIds,
    required this.lastUpdatedAt,
  });

  @HiveField(0)
  int satiation;

  @HiveField(1)
  int cleanliness;

  @HiveField(2)
  int affection;

  @HiveField(3)
  int coins;

  @HiveField(4)
  List<String> ownedItemIds;

  @HiveField(5)
  DateTime lastUpdatedAt;
}
