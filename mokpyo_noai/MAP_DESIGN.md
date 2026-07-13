# 여정 지도(Journey Map) 디자인 가이드

여정 지도의 모든 시각 요소는 `lib/features/home/presentation/views/journey_map_screen.dart`
파일 상단 "🎨 지도 디자인 커스터마이징" 블록에 상수/리스트로 모여 있습니다.
화면을 그리는 로직(위젯 빌드, 탭 처리)은 건드릴 필요 없이, 이 블록만 고치면
지도의 생김새가 바뀝니다.

## 1. 배경(하늘 → 산 → 숲 → 초원) 색상

```dart
const List<Color> mapBackgroundColors = [
  Color(0xFFBBDEFB), // 하늘 (대목표 근처, 맨 위)
  Color(0xFFD1C4E9), // 산
  Color(0xFFC8E6C9), // 숲
  Color(0xFFE8F5E9), // 초원 (오늘의 실천 근처, 맨 아래)
];
const List<double> mapBackgroundStops = [0.0, 0.32, 0.62, 1.0];
```
색상 4개와 그 색이 나타나는 위치(0.0=맨 위, 1.0=맨 아래)를 정의합니다. 색을
더 추가/제거하려면 두 리스트의 길이를 맞춰서 같이 늘리거나 줄이면 됩니다.

## 2. 배경 장식 이모지 (구름/산/나무/꽃)

```dart
const List<MapDecoration> mapDecorations = [
  MapDecoration(emoji: '☁️', fontSize: 26, top: 16, left: 28),
  MapDecoration(emoji: '⛰️', fontSize: 32, top: 130, left: 50),
  ...
];
```
`MapDecoration` 하나가 이모지 하나입니다. `top`/`bottom` 중 하나, `left`/`right`
중 하나를 지정하면 그 위치에 놓입니다(픽셀 단위, 화면 전체 기준). 이모지를
추가하고 싶으면 이 리스트에 항목을 하나 더 넣기만 하면 됩니다. 예를 들어
무지개를 추가하려면:
```dart
MapDecoration(emoji: '🌈', fontSize: 30, top: 80, right: 20),
```

## 3. 오솔길(트레일) 스타일

```dart
const Color trailBaseColor = Color(0xFFD9C9A3); // 흙길 바탕색(굵은 선)
const Color trailDashColor = Color(0xFF8D6E4B); // 흙길 위 점선
const double trailBaseWidth = 10;   // 바탕 선 굵기
const double trailDashWidth = 3;    // 점선 굵기
const double trailDashLength = 10;  // 점선 하나 길이
const double trailGapLength = 8;    // 점선 사이 간격
```
길을 더 두껍게/얇게, 색을 다르게(예: 눈길이면 흰색+하늘색), 점선 간격을
촘촘하게/성기게 하고 싶을 때 이 6개 값만 바꾸면 됩니다.

## 4. 핀(노드) 배치 — 간격과 지그재그 정도

```dart
const double nodeSpacing = 150;  // 핀과 핀 사이 세로 간격(클수록 여정이 길어 보임)
const double topPadding = 50;
const double bottomPadding = 70;
const List<double> zigzagPattern = [0.0, 0.55, 0.0, -0.55]; // -1(완전 왼쪽) ~ 1(완전 오른쪽)
```
`zigzagPattern`은 핀이 놓이는 좌우 위치를 순서대로 반복하는 패턴입니다.
`[0.0, 0.55, 0.0, -0.55]`는 "가운데 → 오른쪽 → 가운데 → 왼쪽"을 반복해서
구불구불한 길을 만듭니다. 더 크게 흔들리게 하려면 값을 `0.8`처럼 늘리고,
일직선에 가깝게 하려면 `0.2`처럼 줄이세요. 패턴 길이를 늘리면(예: 6개) 더
복잡한 곡선을 만들 수 있습니다.

## 5. 목표 단계(대목표/중목표/소목표/일일퀘스트)별 핀 모양

```dart
const Map<int, String> tierEmoji = {1: '🏆', 2: '🥈', 3: '🥉', 4: '🌱'};
const Map<int, String> tierLabel = {1: '대목표', 2: '중목표', 3: '소목표', 4: '일일 퀘스트'};
const Map<int, double> tierPinSize = {1: 60, 2: 52, 3: 46, 4: 40};
```
key는 퀘스트 depth(1~4)입니다. 이모지, 화면에 보이는 이름표, 핀의 지름(px)을
단계별로 다르게 줄 수 있습니다. 지금은 대목표(1) 핀이 가장 크고 일일퀘스트(4)
핀이 가장 작습니다.

핀 색상은 여기서 관리하지 않고 `lib/core/theme/app_colors.dart`의
`AppColors.depthColors` 배열(인덱스 0~4, 0은 미사용)을 그대로 재사용합니다 —
색은 앱 전체 색상표에서, 크기/이모지는 이 파일에서 관리하는 구조입니다.

## 6. "여기부터!" 위치 표시

오늘의 실천 목표(맨 아래) 쪽에서부터 훑어 첫 미완료 항목에 자동으로
"📍 여기부터!" 배지가 붙습니다. 이 배지의 색은 `AppColors.streakBadgeFg`를
씁니다. 문구나 배지 스타일을 바꾸려면 `_mapNode()` 함수 안의 `if (isCurrent)`
블록을 수정하세요.

## 7. 나중에 이모지 대신 실제 이미지로 바꾸고 싶다면

- **배경을 그림으로**: `_MapBackground` 위젯의 `Container(decoration: BoxDecoration(gradient: ...))`
  부분을 `Image.asset('assets/images/map_background.png', fit: BoxFit.cover)`로
  교체하면 됩니다. 장식 이모지(`mapDecorations`)는 그대로 유지해도 되고, 배경
  그림에 이미 포함시켰다면 리스트를 비워도 됩니다.
- **핀을 아이콘 이미지로**: `_mapNode()` 함수의 `Container` 안 `Text(emoji, ...)` 부분을
  `Image.asset('assets/images/map_pins/tier_${quest.depth}.png', width: pinSize*0.6)`처럼
  교체하면 됩니다.
- 동물 캐릭터/아이템 이미지 교체 방법은 `CHARACTER_DESIGN.md`에 별도로 정리돼
  있으니 같이 참고하세요.

## 요약

| 바꾸고 싶은 것 | 수정할 위치 |
|---|---|
| 배경 색(하늘/산/숲/초원) | `mapBackgroundColors`, `mapBackgroundStops` |
| 배경 장식(구름/나무 등) | `mapDecorations` 리스트 |
| 길(트레일) 색/굵기/점선 간격 | `trailBaseColor` 등 6개 상수 |
| 핀 사이 간격, 지그재그 정도 | `nodeSpacing`, `zigzagPattern` |
| 단계별 이모지/이름/핀 크기 | `tierEmoji`, `tierLabel`, `tierPinSize` |
| 핀/카드 색상 | `AppColors.depthColors` (app_colors.dart) |
| 이모지 → 실제 이미지 전환 | `_MapBackground`, `_mapNode()` 내부만 수정 |

모두 `lib/features/home/presentation/views/journey_map_screen.dart` 파일 상단
블록 또는 `app_colors.dart` 안에 있습니다.
