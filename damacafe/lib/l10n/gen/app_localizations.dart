import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 이름
  ///
  /// In ko, this message translates to:
  /// **'펫카페'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'🏠 우리 집'**
  String get homeTitle;

  /// No description provided for @cafeTitle.
  ///
  /// In ko, this message translates to:
  /// **'☕ 카페'**
  String get cafeTitle;

  /// No description provided for @shopTitle.
  ///
  /// In ko, this message translates to:
  /// **'상점'**
  String get shopTitle;

  /// No description provided for @commuteResultTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 정산'**
  String get commuteResultTitle;

  /// No description provided for @errorMessage.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했어요: {error}'**
  String errorMessage(String error);

  /// No description provided for @gaugeSatiationLabel.
  ///
  /// In ko, this message translates to:
  /// **'배고픔(포만감)'**
  String get gaugeSatiationLabel;

  /// No description provided for @gaugeCleanlinessLabel.
  ///
  /// In ko, this message translates to:
  /// **'청결도'**
  String get gaugeCleanlinessLabel;

  /// No description provided for @gaugeAffectionLabel.
  ///
  /// In ko, this message translates to:
  /// **'애정도'**
  String get gaugeAffectionLabel;

  /// No description provided for @clockInButton.
  ///
  /// In ko, this message translates to:
  /// **'출근하기'**
  String get clockInButton;

  /// No description provided for @clockOutButton.
  ///
  /// In ko, this message translates to:
  /// **'퇴근하기'**
  String get clockOutButton;

  /// No description provided for @moodHappyReaction.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 좋은 하루예요!'**
  String get moodHappyReaction;

  /// No description provided for @moodMopingReaction.
  ///
  /// In ko, this message translates to:
  /// **'음... 조금 심심해요.'**
  String get moodMopingReaction;

  /// No description provided for @moodSulkingReaction.
  ///
  /// In ko, this message translates to:
  /// **'흥, 저 삐졌어요.'**
  String get moodSulkingReaction;

  /// No description provided for @moodLongingReaction.
  ///
  /// In ko, this message translates to:
  /// **'많이... 보고 싶었어요.'**
  String get moodLongingReaction;

  /// No description provided for @feedReactionLiked.
  ///
  /// In ko, this message translates to:
  /// **'냠냠! 최고예요 🐾'**
  String get feedReactionLiked;

  /// No description provided for @feedReactionNeutral.
  ///
  /// In ko, this message translates to:
  /// **'음... 그냥 먹을게요.'**
  String get feedReactionNeutral;

  /// No description provided for @feedReactionDisliked.
  ///
  /// In ko, this message translates to:
  /// **'으엑... 억지로 먹었어요.'**
  String get feedReactionDisliked;

  /// No description provided for @washButton.
  ///
  /// In ko, this message translates to:
  /// **'문질러 씻기기'**
  String get washButton;

  /// No description provided for @playButton.
  ///
  /// In ko, this message translates to:
  /// **'놀아주기'**
  String get playButton;

  /// No description provided for @playSuccessMessage.
  ///
  /// In ko, this message translates to:
  /// **'신나게 놀았어요! 애정도 상승, 코인 획득 🎉'**
  String get playSuccessMessage;

  /// No description provided for @swipeMinigameTitle.
  ///
  /// In ko, this message translates to:
  /// **'화살표 방향으로 스와이프!'**
  String get swipeMinigameTitle;

  /// No description provided for @stopPlayingButton.
  ///
  /// In ko, this message translates to:
  /// **'그만하기'**
  String get stopPlayingButton;

  /// No description provided for @sleepDayLabel.
  ///
  /// In ko, this message translates to:
  /// **'낮'**
  String get sleepDayLabel;

  /// No description provided for @sleepNightLabel.
  ///
  /// In ko, this message translates to:
  /// **'밤'**
  String get sleepNightLabel;

  /// No description provided for @ordersServedToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 처리한 주문: {count}건'**
  String ordersServedToday(int count);

  /// No description provided for @serveCompleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{stars} 서빙 완료!'**
  String serveCompleteMessage(String stars);

  /// No description provided for @newRecipeHint.
  ///
  /// In ko, this message translates to:
  /// **'처음 만드는 레시피예요! 미니게임을 거쳐야 해요.'**
  String get newRecipeHint;

  /// No description provided for @cookNowButton.
  ///
  /// In ko, this message translates to:
  /// **'바로 요리하기'**
  String get cookNowButton;

  /// No description provided for @cookWithMinigameButton.
  ///
  /// In ko, this message translates to:
  /// **'미니게임으로 요리하기'**
  String get cookWithMinigameButton;

  /// No description provided for @npcOrderLabel.
  ///
  /// In ko, this message translates to:
  /// **'{npcName} 손님의 주문'**
  String npcOrderLabel(String npcName);

  /// No description provided for @shopCategoryFood.
  ///
  /// In ko, this message translates to:
  /// **'음식'**
  String get shopCategoryFood;

  /// No description provided for @shopCategoryToy.
  ///
  /// In ko, this message translates to:
  /// **'장난감'**
  String get shopCategoryToy;

  /// No description provided for @shopCategoryBed.
  ///
  /// In ko, this message translates to:
  /// **'침대'**
  String get shopCategoryBed;

  /// No description provided for @careBonusLabel.
  ///
  /// In ko, this message translates to:
  /// **'케어 보너스 +{value}'**
  String careBonusLabel(int value);

  /// No description provided for @ownedLabel.
  ///
  /// In ko, this message translates to:
  /// **'보유중'**
  String get ownedLabel;

  /// No description provided for @purchaseSuccessMessage.
  ///
  /// In ko, this message translates to:
  /// **'{itemName} 구매 완료!'**
  String purchaseSuccessMessage(String itemName);

  /// No description provided for @purchaseFailMessage.
  ///
  /// In ko, this message translates to:
  /// **'코인이 부족해요.'**
  String get purchaseFailMessage;

  /// No description provided for @priceCoinsLabel.
  ///
  /// In ko, this message translates to:
  /// **'{price} 코인'**
  String priceCoinsLabel(int price);

  /// No description provided for @cookingScreenTitle.
  ///
  /// In ko, this message translates to:
  /// **'{recipeName} 만들기'**
  String cookingScreenTitle(String recipeName);

  /// No description provided for @cookingInstructions.
  ///
  /// In ko, this message translates to:
  /// **'마커가 초록 구간에 있을 때 화면을 탭하세요!'**
  String get cookingInstructions;

  /// No description provided for @settlementCoinsEarned.
  ///
  /// In ko, this message translates to:
  /// **'획득한 코인: {coins}'**
  String settlementCoinsEarned(int coins);

  /// No description provided for @settlementConditionScore.
  ///
  /// In ko, this message translates to:
  /// **'컨디션 점수: {score}점'**
  String settlementConditionScore(int score);

  /// No description provided for @backHomeButton.
  ///
  /// In ko, this message translates to:
  /// **'집으로 돌아가기'**
  String get backHomeButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
