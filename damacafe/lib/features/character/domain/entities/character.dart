import 'package:freezed_annotation/freezed_annotation.dart';

part 'character.freezed.dart';

/// 집/카페 양쪽에서 공유되는 "내 캐릭터"의 핵심 상태.
/// satiation(포만감)/cleanliness(청결도)/affection(애정도)는 0~100으로 정규화되어 있으며,
/// 높을수록 좋은 상태를 의미한다 (배고픔 게이지 = 포만감으로 해석: 먹이를 주면 값이 올라간다).
@freezed
abstract class Character with _$Character {
  const factory Character({
    required int satiation,
    required int cleanliness,
    required int affection,
    required int coins,
    required List<String> ownedItemIds,
    required DateTime lastUpdatedAt,
  }) = _Character;
}
