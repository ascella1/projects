import 'package:flutter_test/flutter_test.dart';
import 'package:mokpyo_noai/core/utils/character_util.dart';

String _isoDaysAgo(int days) {
  final d = DateTime.now().subtract(Duration(days: days));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void main() {
  group('daysSince', () {
    test('빈 문자열이면 -1(기록 없음)을 반환한다', () {
      expect(daysSince(''), -1);
    });

    test('오늘 날짜면 0을 반환한다', () {
      expect(daysSince(_isoDaysAgo(0)), 0);
    });

    test('3일 전 날짜면 3을 반환한다', () {
      expect(daysSince(_isoDaysAgo(3)), 3);
    });
  });

  group('moodFor', () {
    const neutralAfter = 1;
    const hungryAfter = 2;

    test('기록이 없는 신규 유저는 happy로 시작한다', () {
      expect(
        moodFor('', neutralAfterDays: neutralAfter, hungryAfterDays: hungryAfter),
        CharacterMood.happy,
      );
    });

    test('오늘 루틴을 완료했으면 happy', () {
      expect(
        moodFor(_isoDaysAgo(0),
            neutralAfterDays: neutralAfter, hungryAfterDays: hungryAfter),
        CharacterMood.happy,
      );
    });

    test('하루 지났으면 neutral', () {
      expect(
        moodFor(_isoDaysAgo(1),
            neutralAfterDays: neutralAfter, hungryAfterDays: hungryAfter),
        CharacterMood.neutral,
      );
    });

    test('이틀 이상 지났으면 hungry', () {
      expect(
        moodFor(_isoDaysAgo(2),
            neutralAfterDays: neutralAfter, hungryAfterDays: hungryAfter),
        CharacterMood.hungry,
      );
      expect(
        moodFor(_isoDaysAgo(10),
            neutralAfterDays: neutralAfter, hungryAfterDays: hungryAfter),
        CharacterMood.hungry,
      );
    });
  });

  group('randomSpeech', () {
    test('모든 캐릭터 타입 × 모든 기분에 대해 빈 문자열이 아닌 대사를 반환한다', () {
      for (final type in ['cat', 'dog', 'rabbit', 'fox', 'unknown']) {
        for (final mood in CharacterMood.values) {
          final speech = randomSpeech(type, mood);
          expect(speech, isNotEmpty);
        }
      }
    });
  });
}
