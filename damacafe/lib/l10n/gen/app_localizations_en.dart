// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pet Cafe';

  @override
  String get homeTitle => '🏠 My Home';

  @override
  String get cafeTitle => '☕ Cafe';

  @override
  String get shopTitle => 'Shop';

  @override
  String get commuteResultTitle => 'Today\'s Settlement';

  @override
  String errorMessage(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get gaugeSatiationLabel => 'Hunger (Fullness)';

  @override
  String get gaugeCleanlinessLabel => 'Cleanliness';

  @override
  String get gaugeAffectionLabel => 'Affection';

  @override
  String get clockInButton => 'Go to work';

  @override
  String get clockOutButton => 'Clock out';

  @override
  String get moodHappyReaction => 'Having a great day!';

  @override
  String get moodMopingReaction => 'Hmm... a little bored.';

  @override
  String get moodSulkingReaction => 'Hmph, I\'m upset.';

  @override
  String get moodLongingReaction => 'I... missed you a lot.';

  @override
  String get feedReactionLiked => 'Yum! The best 🐾';

  @override
  String get feedReactionNeutral => 'Hmm, I\'ll just eat it.';

  @override
  String get feedReactionDisliked => 'Ugh... I ate it anyway.';

  @override
  String get washButton => 'Scrub and wash';

  @override
  String get playButton => 'Play';

  @override
  String get playSuccessMessage =>
      'Had so much fun! Affection up, coins earned 🎉';

  @override
  String get swipeMinigameTitle => 'Swipe in the arrow direction!';

  @override
  String get stopPlayingButton => 'Stop';

  @override
  String get sleepDayLabel => 'Day';

  @override
  String get sleepNightLabel => 'Night';

  @override
  String ordersServedToday(int count) {
    return 'Orders served today: $count';
  }

  @override
  String serveCompleteMessage(String stars) {
    return '$stars Order served!';
  }

  @override
  String get newRecipeHint =>
      'First time making this! You\'ll need to play a minigame.';

  @override
  String get cookNowButton => 'Cook now';

  @override
  String get cookWithMinigameButton => 'Cook via minigame';

  @override
  String npcOrderLabel(String npcName) {
    return '$npcName\'s order';
  }

  @override
  String get shopCategoryFood => 'Food';

  @override
  String get shopCategoryToy => 'Toy';

  @override
  String get shopCategoryBed => 'Bed';

  @override
  String careBonusLabel(int value) {
    return 'Care bonus +$value';
  }

  @override
  String get ownedLabel => 'Owned';

  @override
  String purchaseSuccessMessage(String itemName) {
    return 'Purchased $itemName!';
  }

  @override
  String get purchaseFailMessage => 'Not enough coins.';

  @override
  String priceCoinsLabel(int price) {
    return '$price coins';
  }

  @override
  String cookingScreenTitle(String recipeName) {
    return 'Making $recipeName';
  }

  @override
  String get cookingInstructions =>
      'Tap the screen when the marker is in the green zone!';

  @override
  String settlementCoinsEarned(int coins) {
    return 'Coins earned: $coins';
  }

  @override
  String settlementConditionScore(int score) {
    return 'Condition score: $score';
  }

  @override
  String get backHomeButton => 'Back home';
}
