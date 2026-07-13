# mokpyo_noai 디자인 가이드

이 앱의 디자인은 mokpyo(원본)의 초록 정원 라이트 테마를 그대로 재현하고 있습니다.
디자인을 바꾸고 싶을 때 "어떤 파일을 봐야 하는지"를 아래 우선순위대로 확인하세요.

> 동물 캐릭터/아이템을 이모지에서 실제 이미지로 바꾸는 방법은 별도로
> `CHARACTER_DESIGN.md`에, 여정 지도(배경/길/핀 디자인)를 커스터마이징하는
> 방법은 `MAP_DESIGN.md`에 정리했습니다.

## 1. 색상만 바꾸고 싶다면 → `lib/core/theme/app_colors.dart`

앱 전체에서 쓰이는 색이 전부 여기 상수로 정의돼 있습니다. 이 파일의 값만 바꾸면
버튼, 카드, 배지, 능력치 색 등 앱 전체에 자동으로 반영됩니다. 다른 파일은 건드릴
필요가 없습니다.

| 상수 | 현재 값 | 어디에 쓰이는지 |
|---|---|---|
| `backgroundStart` / `backgroundEnd` | `#E8F5E9` → `#FFF3E0` | 전체 화면 배경 그라데이션(상단→하단) |
| `primary` | `#2E7D32` (진한 초록) | 버튼, 강조 텍스트, 선택 상태 |
| `primaryLight` | `#81C784` (연한 초록) | EXP 진행바 채움색 |
| `primarySoft` | `#E8F5E9` | 칩/배지 옅은 배경 |
| `avatarBg` | `#C8E6C9` | 캐릭터 아바타 원형 배경 |
| `textPrimary` | `#3E2723` (브라운) | 제목/본문 텍스트 |
| `textSecondary` | `Colors.grey` | 보조 설명 텍스트 |
| `boxBadgeBg` / `boxBadgeFg` | `#FFECEB` / `#D84315` | "🎁 상자 N개" 배지 |
| `streakBadgeBg` / `streakBadgeFg` | `#FFF8E1` / `#E65100` | "🔥 N일 연속" 배지, 레벨업 강조 |
| `levelUpBg` | `#1B5E20` (짙은 초록) | 레벨업 다이얼로그 배경 |
| `statKnowledge/Career/Health/Money/Communication` | 파랑/초록/빨강/주황/보라 | 능력치별 색 (지식/커리어/체력/자산/소통) |
| `depthColors` | 회색/보라/남색/청록/초록 | 업적 탭에서 대목표~일일퀘스트 구분 색 |

## 2. 버튼/카드/다이얼로그 모양(둥근 정도, 그림자, 폰트 굵기 등) → `lib/core/theme/app_theme.dart`

`AppTheme.light()`가 앱 전역 `ThemeData`를 만듭니다. 여기서 다음을 바꿀 수 있습니다:
- `cardTheme` — 카드 모서리 둥글기, 투명도
- `dialogTheme` — 다이얼로그 모양, 제목/본문 텍스트 스타일
- `bottomNavigationBarTheme` — 하단 탭바 색
- `elevatedButtonTheme` / `outlinedButtonTheme` — 버튼 모양, 패딩, 모서리
- `inputDecorationTheme` — 입력창(텍스트필드) 배경/테두리

색 자체는 여기서 직접 하드코딩하지 말고 `AppColors.xxx`를 참조하도록 되어 있으니,
색은 1번 파일에서, 모양/굵기는 이 파일에서 바꾸세요.

## 3. 화면 레이아웃/구성 요소를 바꾸고 싶다면

메인 화면은 셸(shell) + 탭별 파일로 나뉘어 있습니다.

- **셸(하단 탭 전환 + 전역 다이얼로그)**: `lib/features/home/presentation/views/home_screen.dart`
  - 하단 탭 순서/아이콘/라벨은 `BottomNavigationBar`의 `items`와 `_buildMainApp()`의
    `switch`문에 있습니다. 이 둘의 순서를 반드시 같이 맞춰야 합니다.
  - 스트릭 보상(🔥)/등급 해금(🔓) 다이얼로그처럼 "어느 탭에 있든 떠야 하는" 전역
    팝업만 여기 있습니다. 특정 탭 전용 팝업은 각 탭 파일에 있습니다.
- **탭별 파일**: `lib/features/home/presentation/views/tabs/`
  - `garden_tab.dart` — 나의 정원. 상단 유저 정보 카드, 캐릭터(탭 반응/기분 표시/
    "🍖 먹이주기"·"🎾 놀아주기" 상호작용은 `_onFeedOrPlay`/`_interactionButton`,
    "체크인" 다이얼로그는 `_showCheckInDialog`), 오늘의 실천 목표 목록(즉석 추가는
    `_questSectionHeaderWithAdd`/`_showAddAdHocQuestDialog`), 퀘스트 완료/레벨업
    다이얼로그(`_showSuccessRewardDialog`/`_showLevelUpDialog`).
  - `loot_box_tab.dart` — 상자 오픈. 상자 흔들기 애니메이션과 아이템 획득 다이얼로그.
  - `inventory_tab.dart` — 인벤토리. 악세사리 그리드, 장착/해제.
  - `achievements_tab.dart` — 업적 & 스탯. 능력치 바, 달성 기록, 데이터 초기화.
  - 이 파일들은 전부 `lib/core/services/item_service.dart`의 `itemListProvider`를
    통해 아이템 목록을 각자 독립적으로 읽습니다 — 한 탭의 상태가 다른 탭에 영향을
    주지 않으므로, 탭 하나만 골라서 안전하게 수정할 수 있습니다.
- **여정 지도(스킬트리형 시각화)**: `lib/features/home/presentation/views/journey_map_screen.dart`
  - 하단 탭의 두 번째 탭. 대목표(🏆, 맨 위)부터 일일퀘스트(🌱, 맨 아래)까지 구불구불한
    오솔길로 보여주는 화면. 디자인 커스터마이징은 `MAP_DESIGN.md` 참고.
- **목표 입력 위저드(7단계)**: `lib/features/onboarding/presentation/views/goal_wizard_screen.dart`
  - 캐릭터 선택 → 대목표 → 스탯 선택 → 중목표 → 소목표 → 일일퀘스트 → 확인 화면의
    레이아웃, 문구, 카드 스타일.
  - 각 단계 상단에 뜨는 "코칭 반응"(예: "그건 꽤 도전적인데요?") 문구 풀은
    `lib/features/onboarding/presentation/utils/wizard_reactions.dart`에 있습니다.
    AI 호출 없이 이전 답변(목표 텍스트, 선택한 스탯, 항목 개수)을 문구에 끼워
    넣는 방식이라, 반응 문구를 더 추가/수정하고 싶으면 이 파일만 고치면 됩니다.

이 파일들은 색상은 `AppColors`를 참조하되, 여백/정렬/위젯 구조(Column, Row, Card
배치 등)는 직접 정의합니다. "버튼 위치를 바꾸고 싶다", "탭 순서를 바꾸고 싶다" 같은
요청은 여기를 수정해야 합니다.

## 4. 캐릭터 이모지/대사, 능력치 이모지·라벨 → `lib/core/utils/`

- `character_util.dart` — 고양이/강아지/토끼/여우 이모지, 캐릭터별 대사, 라벨,
  그리고 아래에서 설명하는 "기분(mood)" 시스템의 판정 로직과 대사 풀이 모두 여기 있습니다.

### 캐릭터 기분(mood) 시스템 커스터마이징

캐릭터는 레벨업의 결과물이 아니라 "며칠간 루틴(일일 퀘스트)을 실천했는지"에 반응합니다.

- **기분이 바뀌는 기준(며칠 지나야 시무룩해지는지)** → `assets/data/mokpyo_level_config.json`의
  `"mood"` 항목 (`neutralAfterDays`, `hungryAfterDays`). 예를 들어 더 빨리 서운해하게
  하려면 숫자를 줄이면 됩니다.
- **기분별 대사 문구** → `character_util.dart`의 `_speechPool` 맵. 캐릭터 타입(cat/dog/rabbit/fox) ×
  기분(happy/neutral/hungry)별로 문구 리스트가 있고, 탭할 때마다 그중 하나가 무작위로 나갑니다.
  문구를 추가/수정하고 싶으면 이 리스트에 문자열만 추가하면 됩니다.
- **기분에 따른 시각 효과(반투명, 기울임, 우측 상단 이모지)** → `tabs/garden_tab.dart`의
  캐릭터를 그리는 `AnimatedBuilder`/`Opacity`/`moodIndicatorEmoji` 부분.
- **탭했을 때 반응(바운스 애니메이션)** → `tabs/garden_tab.dart`의 `_characterAnimController`와
  `_onCharacterTap`. 애니메이션 길이/세기를 바꾸려면 `AnimationController`의 `duration`과
  `bounce`/`wiggle` 계산식을 수정하세요.
- **하루 첫 탭에 뜨는 "체크인" 다이얼로그**(오늘 루틴 진행 상황 보고) → `tabs/garden_tab.dart`의
  `_showCheckInDialog`. 문구/레이아웃을 이 함수에서 바꿀 수 있습니다.
- `stat_util.dart` — 지식/커리어/체력/자산/소통 각각의 이모지·라벨·색(`AppColors.statXxx` 참조).

## 5. 아이템(악세사리) 이름/설명/이모지 → `assets/data/mokpyo_item.json`

색상이 아니라 텍스트 리소스입니다. 새 아이템을 추가하거나 이름/설명을 바꾸고
싶으면 이 JSON만 수정하면 됩니다 (코드 변경 불필요).

## 6. 레벨업 밸런스(경험치, 해금 레벨, 스트릭 보상) → `assets/data/mokpyo_level_config.json`

디자인은 아니지만 자주 같이 조정하게 되는 파일이라 함께 안내합니다. `LevelConfigService`가
이 JSON을 읽어 앱 전체에 반영합니다.

## 7. 폰트를 바꾸고 싶다면

1. `pubspec.yaml`의 `flutter > fonts` 섹션에 폰트 파일 등록
2. `lib/core/theme/app_theme.dart`의 `ThemeData(...)`에 `fontFamily: '폰트이름'` 추가

---

**요약**: 색만 바꾼다 → `app_colors.dart`. 모양/여백/폰트 크기 같은 전역 스타일 →
`app_theme.dart`. 탭 순서/전역 팝업 → `home_screen.dart`. 특정 탭의 배치 자체를
바꾼다 → `tabs/` 안의 해당 탭 파일. 목표 입력 위저드 → `goal_wizard_screen.dart`.
텍스트 리소스(아이템/능력치 이름) → `core/utils/` 또는 `assets/data/*.json`.
