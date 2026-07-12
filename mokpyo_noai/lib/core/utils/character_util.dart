import 'dart:math';

// 캐릭터 타입(cat/dog/rabbit/fox)에 대응하는 이모지/대사/기분(mood) 헬퍼.
//
// 캐릭터는 "레벨업의 결과물"이 아니라 사용자의 행동(일일 퀘스트 완료 여부)에
// 반응하는 존재로 다룬다. lastRoutineDate(마지막으로 일일 퀘스트를 완료한 날)를
// 기준으로 daysSince()를 계산해 mood를 결정한다.

enum CharacterMood { happy, neutral, hungry }

String characterEmoji(String type) {
  switch (type) {
    case 'cat':
      return '🐱';
    case 'dog':
      return '🐶';
    case 'rabbit':
      return '🐰';
    default:
      return '🦊';
  }
}

String characterLabel(String type) {
  switch (type) {
    case 'cat':
      return '귀여운 고양이';
    case 'dog':
      return '듬직한 강아지';
    case 'rabbit':
      return '사랑스런 토끼';
    default:
      return '지혜로운 여우';
  }
}

// lastRoutineDate(YYYY-MM-DD)로부터 오늘까지 며칠 지났는지 계산한다.
// 기록이 없거나(신규 유저) 파싱할 수 없으면 -1을 반환한다.
int daysSince(String isoDate) {
  if (isoDate.isEmpty) return -1;
  final date = DateTime.tryParse(isoDate);
  if (date == null) return -1;
  final day = DateTime(date.year, date.month, date.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(day).inDays;
}

// lastRoutineDate와 레벨 설정(JSON)의 임계값을 바탕으로 캐릭터의 기분을 판단한다.
CharacterMood moodFor(
  String lastRoutineDate, {
  required int neutralAfterDays,
  required int hungryAfterDays,
}) {
  final days = daysSince(lastRoutineDate);
  if (days < 0) return CharacterMood.happy; // 아직 기록 없는 신규 유저는 반갑게 시작
  if (days >= hungryAfterDays) return CharacterMood.hungry;
  if (days >= neutralAfterDays) return CharacterMood.neutral;
  return CharacterMood.happy;
}

String moodIndicatorEmoji(CharacterMood mood) {
  switch (mood) {
    case CharacterMood.happy:
      return '✨';
    case CharacterMood.neutral:
      return '💭';
    case CharacterMood.hungry:
      return '😢';
  }
}

String moodLabel(CharacterMood mood) {
  switch (mood) {
    case CharacterMood.happy:
      return '기분 좋음';
    case CharacterMood.neutral:
      return '심심함';
    case CharacterMood.hungry:
      return '서운함';
  }
}

final Map<String, Map<CharacterMood, List<String>>> _speechPool = {
  'cat': {
    CharacterMood.happy: [
      '"야옹~ 오늘도 기분 최고예요!"',
      '"주인님 덕분에 신나는 하루예요!"',
      '"오늘 목표 벌써 했어요? 대단해요!"',
    ],
    CharacterMood.neutral: [
      '"야옹... 오늘은 뭐 할까요?"',
      '"슬슬 몸을 움직여볼까요?"',
      '"어제는 잘 했는데, 오늘도 해볼까요?"',
    ],
    CharacterMood.hungry: [
      '"야옹... 저 좀 챙겨주세요, 심심해요..."',
      '"오랫동안 못 만난 것 같아서 서운해요..."',
      '"오늘의 목표, 저랑 같이 해봐요..."',
    ],
  },
  'dog': {
    CharacterMood.happy: [
      '"멍멍! 오늘도 신나는 하루예요!"',
      '"주인님 최고! 이 기세로 계속 가요!"',
      '"멍! 오늘 목표 완료 축하해요!"',
    ],
    CharacterMood.neutral: [
      '"멍... 오늘 할 일이 남았어요!"',
      '"슬슬 시작해볼까요? 멍!"',
      '"어제처럼 오늘도 힘내봐요!"',
    ],
    CharacterMood.hungry: [
      '"멍... 저 요즘 좀 심심하고 서운해요."',
      '"주인님 보고 싶었어요... 같이 해요!"',
      '"오늘은 저랑 목표 하나만 같이 해줘요..."',
    ],
  },
  'rabbit': {
    CharacterMood.happy: [
      '"깡충! 오늘 하루도 행복해요!"',
      '"작은 발걸음이 모여 큰 변화가 되고 있어요!"',
      '"우와, 오늘도 목표를 해냈군요!"',
    ],
    CharacterMood.neutral: [
      '"깡충깡충... 오늘은 뭘 해볼까요?"',
      '"조금씩이라도 움직여봐요!"',
      '"어제 잘했으니 오늘도 할 수 있어요!"',
    ],
    CharacterMood.hungry: [
      '"깡충... 요 며칠 좀 서운했어요..."',
      '"저를 잊은 건 아니죠? 보고 싶었어요..."',
      '"오늘은 저랑 같이 작은 것 하나만 해봐요..."',
    ],
  },
  'fox': {
    CharacterMood.happy: [
      '"오늘도 한 걸음 나아갔군요, 기특해요."',
      '"꾸준함이 결국 큰 힘이 됩니다."',
      '"당신의 오늘을 지켜봤어요, 멋져요."',
    ],
    CharacterMood.neutral: [
      '"천천히, 씨앗을 심듯 오늘도 실천해봐요."',
      '"오늘은 아직 아무것도 안 했네요. 시작해볼까요?"',
      '"어제의 나보다 조금만 더 나아가 봐요."',
    ],
    CharacterMood.hungry: [
      '"요 며칠 얼굴을 못 봐서 조금 서운했어요..."',
      '"괜찮아요, 다시 오늘부터 함께해요."',
      '"저는 여기서 계속 기다리고 있었어요..."',
    ],
  },
};

// 특정 캐릭터/기분에 맞는 대사를 무작위로 하나 골라 반환한다.
// 캐릭터를 탭할 때마다 새로운 대사를 보여주는 데 사용한다.
String randomSpeech(String type, CharacterMood mood) {
  final pool = _speechPool[type]?[mood] ?? _speechPool['fox']![mood]!;
  return pool[Random().nextInt(pool.length)];
}

// 먹이주기/놀아주기 상호작용 전용 대사 풀. 루틴 완료 여부와 무관하게
// 순수한 애정 표현용 반응이다.
final Map<String, List<String>> _feedSpeech = {
  'cat': ['"냠냠, 맛있어요!"', '"고마워요, 배부르네요!"', '"주인님 최고예요!"'],
  'dog': ['"멍멍! 맛있다!"', '"우와 잘 먹었어요!"', '"더 주세요! 멍!"'],
  'rabbit': ['"오물오물, 최고예요!"', '"당근보다 맛있어요!"', '"깡충! 잘 먹었습니다!"'],
  'fox': ['"고마워요, 든든하네요."', '"덕분에 힘이 나요."', '"오늘도 챙겨줘서 고마워요."'],
};

final Map<String, List<String>> _playSpeech = {
  'cat': ['"신난다! 같이 놀아요!"', '"야옹~ 재밌어요!"', '"더 놀아줘요!"'],
  'dog': ['"멍멍! 최고로 신나요!"', '"더 놀아요, 더!"', '"오늘 제일 신나는 시간이에요!"'],
  'rabbit': ['"깡충깡충! 즐거워요!"', '"폴짝폴짝, 신나요!"', '"이렇게 노는 거 좋아해요!"'],
  'fox': ['"오랜만에 웃었네요."', '"당신과 함께라 즐거워요."', '"이런 시간, 참 소중해요."'],
};

String _pick(Map<String, List<String>> pool, String type) {
  final list = pool[type] ?? pool['fox']!;
  return list[Random().nextInt(list.length)];
}

String randomFeedSpeech(String type) => _pick(_feedSpeech, type);
String randomPlaySpeech(String type) => _pick(_playSpeech, type);
