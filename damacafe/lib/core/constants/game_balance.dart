/// 게임 밸런스 상수 모음. 튜닝 시 이 파일만 수정하면 되도록 값들을 한 곳에 모아둔다.
class GameBalance {
  GameBalance._();

  /// 배고픔(포만감)/청결도/애정도 게이지는 모두 0(최악)~100(최고)로 정규화한다.
  static const int maxGauge = 100;
  static const int minGauge = 0;

  /// 방치 시 시간당 감소량 (집 화면을 열 때 마지막 상호작용 시각과의 경과 시간으로 계산).
  static const double satiationDecayPerHour = 4.0;
  static const double cleanlinessDecayPerHour = 3.0;
  static const double affectionDecayPerHour = 2.0;

  /// 먹이주기: 재료 선호도에 따른 포만감 증가량.
  static const int feedGainLiked = 30;
  static const int feedGainNeutral = 18;
  static const int feedGainDisliked = 8;

  /// 씻기기: 터치 1회당 청결도 증가량.
  static const int washGainPerTap = 20;

  /// 놀아주기 미니게임 클리어 보상.
  static const int playAffectionGain = 15;
  static const int playCoinReward = 10;

  /// mood 단계 전환 기준값 (세 게이지 중 최솟값 기준).
  static const int moodMopingThreshold = 50; // 시무룩
  static const int moodSulkingThreshold = 25; // 삐짐
  static const int moodLongingThreshold = 5; // 그리워함

  /// 컨디션 점수 = 세 게이지의 평균. 카페 성공률/만족도 페널티 기준값.
  static const int conditionPenaltyThreshold = 40;
}
