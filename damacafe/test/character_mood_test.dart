import 'package:damacafe/features/character/domain/character_mood.dart';
import 'package:damacafe/features/character/domain/entities/character.dart';
import 'package:flutter_test/flutter_test.dart';

Character _character({int satiation = 100, int cleanliness = 100, int affection = 100}) {
  return Character(
    satiation: satiation,
    cleanliness: cleanliness,
    affection: affection,
    coins: 0,
    ownedItemIds: const [],
    lastUpdatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('CharacterMood', () {
    test('모든 게이지가 높으면 happy', () {
      expect(_character().mood, CharacterMood.happy);
    });

    test('가장 낮은 게이지가 50 이하이면 moping', () {
      expect(_character(cleanliness: 50).mood, CharacterMood.moping);
    });

    test('가장 낮은 게이지가 25 이하이면 sulking', () {
      expect(_character(affection: 20).mood, CharacterMood.sulking);
    });

    test('가장 낮은 게이지가 5 이하이면 longing', () {
      expect(_character(satiation: 3).mood, CharacterMood.longing);
    });

    test('다시 케어해서 게이지가 회복되면 happy로 돌아온다', () {
      final neglected = _character(satiation: 0);
      expect(neglected.mood, CharacterMood.longing);

      final caredFor = neglected.copyWith(satiation: 100);
      expect(caredFor.mood, CharacterMood.happy);
    });
  });
}
