# 캐릭터 & 아이템 디자인 가이드

지금 앱은 동물 캐릭터(고양이/강아지/토끼/여우)와 악세사리 아이템을 전부
**이모지**로 표현합니다. 나중에 직접 그린 이미지(일러스트)로 바꾸고 싶을 때,
"코드 전체를 뒤질 필요 없이 어디만 고치면 되는지"를 정리한 문서입니다.

## 지금 구조: 왜 수정이 쉬운가

캐릭터와 아이템 모두 "어떻게 그릴지"를 딱 한 함수가 결정합니다. 화면 코드
(`tabs/garden_tab.dart`, `tabs/inventory_tab.dart`, `goal_wizard_screen.dart` 등)는
전부 이 함수를 호출할 뿐, 이모지인지 이미지인지 전혀 신경 쓰지 않습니다.

| 대상 | 결정하는 함수 | 위치 |
|---|---|---|
| 동물 캐릭터 | `characterVisual(type, size: ...)` | `lib/core/utils/character_util.dart` |
| 아이템(악세사리) | `itemVisual(item, size: ...)` | `lib/core/utils/item_util.dart` |

즉, **이미지로 바꿀 때 이 두 함수의 내부 구현만 고치면 앱 전체(캐릭터 선택
화면, 나의 정원 캐릭터, 인벤토리, 아이템 획득 팝업 등)에 한 번에 반영됩니다.**

## 캐릭터를 실제 이미지로 바꾸는 방법

1. **이미지 준비**: `cat.png`, `dog.png`, `rabbit.png`, `fox.png` 같은 정사각형
   투명 배경 PNG를 준비합니다. 512×512 권장(96px 크기로도, 22px 아주 작은
   크기로도 쓰이기 때문에 고해상도로 준비해야 작게 써도 선명합니다).
2. **에셋 폴더에 추가**: `assets/images/characters/cat.png` 형태로 저장.
3. **pubspec.yaml에 등록**:
   ```yaml
   flutter:
     assets:
       - assets/data/mokpyo_item.json
       - assets/data/mokpyo_level_config.json
       - assets/images/characters/
   ```
4. **`character_util.dart`의 `characterVisual()`만 수정**:
   ```dart
   Widget characterVisual(String type, {required double size}) {
     return Image.asset(
       'assets/images/characters/$type.png',
       width: size,
       height: size,
     );
   }
   ```
   `characterEmoji()` 함수는 그대로 둬도 됩니다(대사/기분 로직 등 다른 곳에서
   문자열이 필요할 수 있음). `characterVisual()`만 이미지로 바뀌면 됩니다.

### 기분(mood)별로 다른 그림을 쓰고 싶다면

지금은 캐릭터가 배고픔(hungry)/평온(neutral)/기쁨(happy) 상태에 따라 투명도만
살짝 낮아지는 정도입니다(`lib/features/home/presentation/views/tabs/garden_tab.dart`의
캐릭터를 그리는 `Opacity` 부분). 만약 `cat_happy.png` / `cat_hungry.png`처럼
표정이 다른 그림을 쓰고 싶다면:

1. `character_util.dart`의 `CharacterMood` enum을 그대로 활용.
2. `characterVisual()`에 `CharacterMood? mood` 파라미터를 추가하고, mood가
   있으면 `'assets/images/characters/${type}_${mood.name}.png'`를 쓰도록 분기.
3. 호출하는 쪽(`garden_tab.dart`)에서 이미 `mood` 값을 계산해두고 있으니
   `characterVisual(type, size: 96, mood: mood)`로 넘기기만 하면 됩니다.

## 아이템(악세사리)을 실제 이미지로 바꾸는 방법

아이템은 `assets/data/mokpyo_item.json`에 `{id, name, desc}`로 정의돼 있고,
`name`은 `"👑 전설의 왕관"`처럼 "이모지 + 이름" 형식입니다.

1. **이미지 준비**: 아이템 `id`와 같은 이름의 PNG(`crown.png`, `sunglasses.png`
   등)를 512×512 정도로 준비.
2. **에셋 폴더/등록**: `assets/images/items/crown.png` 추가 후 pubspec.yaml에
   `assets/images/items/` 등록(위 캐릭터와 동일한 방식).
3. **`item_util.dart`의 `itemVisual()`만 수정**:
   ```dart
   Widget itemVisual(Map<String, String> item, {required double size}) {
     return Image.asset(
       'assets/images/items/${item['id']}.png',
       width: size,
       height: size,
     );
   }
   ```
   `itemEmoji()`/`itemLabel()`은 이름 텍스트 파싱용이라 그대로 둬도 됩니다.

## 왜 이렇게 만들었는지

동물 캐릭터 4종만 해도 실제로는 크기가 22px(작은 아바타)부터 96px(메인 화면
큰 캐릭터)까지 다양한 곳에서 쓰입니다. 만약 각 화면에서 직접
`Text(characterEmoji(type), style: TextStyle(fontSize: ...))`처럼 흩어져
있었다면, 이미지로 바꿀 때 화면 파일을 전부 찾아 고쳐야 했을 것입니다.
지금처럼 `characterVisual()`/`itemVisual()` 한 곳으로 모아뒀기 때문에,
**그림을 그려서 넣을 때 이 두 파일만 열면 됩니다.**

## 요약

- 캐릭터 이미지 교체 → `lib/core/utils/character_util.dart`의 `characterVisual()`
- 아이템 이미지 교체 → `lib/core/utils/item_util.dart`의 `itemVisual()`
- 새 이미지 파일은 `assets/images/characters/`, `assets/images/items/`에 넣고
  `pubspec.yaml`의 `flutter > assets`에 폴더째로 등록
- 이모지 자체(문구/이름)를 바꾸고 싶을 뿐이라면 이미지 작업 없이
  `character_util.dart`의 switch문이나 `assets/data/mokpyo_item.json`만
  고치면 됩니다 (자세한 내용은 `APP_DESIGN.md` 참고).
