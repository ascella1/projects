// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '펫카페';

  @override
  String get homeTitle => '🏠 우리 집';

  @override
  String get cafeTitle => '☕ 카페';

  @override
  String get shopTitle => '상점';

  @override
  String get commuteResultTitle => '오늘의 정산';

  @override
  String errorMessage(String error) {
    return '오류가 발생했어요: $error';
  }

  @override
  String get gaugeSatiationLabel => '배고픔(포만감)';

  @override
  String get gaugeCleanlinessLabel => '청결도';

  @override
  String get gaugeAffectionLabel => '애정도';

  @override
  String get clockInButton => '출근하기';

  @override
  String get clockOutButton => '퇴근하기';

  @override
  String get moodHappyReaction => '오늘도 좋은 하루예요!';

  @override
  String get moodMopingReaction => '음... 조금 심심해요.';

  @override
  String get moodSulkingReaction => '흥, 저 삐졌어요.';

  @override
  String get moodLongingReaction => '많이... 보고 싶었어요.';

  @override
  String get feedReactionLiked => '냠냠! 최고예요 🐾';

  @override
  String get feedReactionNeutral => '음... 그냥 먹을게요.';

  @override
  String get feedReactionDisliked => '으엑... 억지로 먹었어요.';

  @override
  String get washButton => '문질러 씻기기';

  @override
  String get playButton => '놀아주기';

  @override
  String get playSuccessMessage => '신나게 놀았어요! 애정도 상승, 코인 획득 🎉';

  @override
  String get swipeMinigameTitle => '화살표 방향으로 스와이프!';

  @override
  String get stopPlayingButton => '그만하기';

  @override
  String get sleepDayLabel => '낮';

  @override
  String get sleepNightLabel => '밤';

  @override
  String ordersServedToday(int count) {
    return '오늘 처리한 주문: $count건';
  }

  @override
  String serveCompleteMessage(String stars) {
    return '$stars 서빙 완료!';
  }

  @override
  String get newRecipeHint => '처음 만드는 레시피예요! 미니게임을 거쳐야 해요.';

  @override
  String get cookNowButton => '바로 요리하기';

  @override
  String get cookWithMinigameButton => '미니게임으로 요리하기';

  @override
  String npcOrderLabel(String npcName) {
    return '$npcName 손님의 주문';
  }

  @override
  String get shopCategoryFood => '음식';

  @override
  String get shopCategoryToy => '장난감';

  @override
  String get shopCategoryBed => '침대';

  @override
  String careBonusLabel(int value) {
    return '케어 보너스 +$value';
  }

  @override
  String get ownedLabel => '보유중';

  @override
  String purchaseSuccessMessage(String itemName) {
    return '$itemName 구매 완료!';
  }

  @override
  String get purchaseFailMessage => '코인이 부족해요.';

  @override
  String priceCoinsLabel(int price) {
    return '$price 코인';
  }

  @override
  String cookingScreenTitle(String recipeName) {
    return '$recipeName 만들기';
  }

  @override
  String get cookingInstructions => '마커가 초록 구간에 있을 때 화면을 탭하세요!';

  @override
  String settlementCoinsEarned(int coins) {
    return '획득한 코인: $coins';
  }

  @override
  String settlementConditionScore(int score) {
    return '컨디션 점수: $score점';
  }

  @override
  String get backHomeButton => '집으로 돌아가기';
}
