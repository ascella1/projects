import 'package:damacafe/features/character/domain/character_decay.dart';
import 'package:damacafe/features/character/domain/entities/character.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('경과 시간이 없으면 게이지가 그대로 유지된다', () {
    final now = DateTime(2026, 1, 1, 12, 0);
    final character = Character(
      satiation: 100,
      cleanliness: 100,
      affection: 100,
      coins: 0,
      ownedItemIds: const [],
      lastUpdatedAt: now,
    );

    final result = applyIdleDecay(character, now);
    expect(result, character);
  });

  test('시간이 지나면 세 게이지가 모두 감소한다', () {
    final start = DateTime(2026, 1, 1, 12, 0);
    final character = Character(
      satiation: 100,
      cleanliness: 100,
      affection: 100,
      coins: 0,
      ownedItemIds: const [],
      lastUpdatedAt: start,
    );

    final result = applyIdleDecay(character, start.add(const Duration(hours: 5)));

    expect(result.satiation, lessThan(100));
    expect(result.cleanliness, lessThan(100));
    expect(result.affection, lessThan(100));
  });

  test('게이지는 0 밑으로 내려가지 않는다', () {
    final start = DateTime(2026, 1, 1, 12, 0);
    final character = Character(
      satiation: 5,
      cleanliness: 5,
      affection: 5,
      coins: 0,
      ownedItemIds: const [],
      lastUpdatedAt: start,
    );

    final result = applyIdleDecay(character, start.add(const Duration(days: 10)));

    expect(result.satiation, 0);
    expect(result.cleanliness, 0);
    expect(result.affection, 0);
  });
}
