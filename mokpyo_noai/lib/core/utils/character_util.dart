// 캐릭터 타입(cat/dog/rabbit/fox)에 대응하는 이모지/대사 헬퍼.
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

String characterSpeech(String type) {
  switch (type) {
    case 'cat':
      return '"야옹, 오늘도 한걸음 나아가볼까?"';
    case 'dog':
      return '"멍멍! 포기하지 말고 시작하자!"';
    case 'rabbit':
      return '"깡충깡충! 작은 발걸음이 큰 변화를 만들어요!"';
    default:
      return '"천천히, 씨앗을 심듯 실천해봐."';
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
