# 03. Flutter 폴더 구조 + Clean Architecture + 상태관리 전략

## 1. 아키텍처 레이어 원칙

Feature-first + Clean Architecture(Presentation / Domain / Data 3계층). 의존성은 항상 바깥(Presentation)에서 안쪽(Domain)으로만 향하고, Domain은 어떤 레이어에도 의존하지 않는다.

```
Presentation  ──depends on──▶  Domain  ◀──depends on──  Data
   (UI, Riverpod)              (Entity,                 (Repository Impl,
                                 UseCase,                 DataSource,
                                 Repository Interface)    DTO/Model)
```

- `Domain`은 순수 Dart. Flutter/Dio/Drift에 대한 import가 없어야 한다.
- `Data`는 `Domain`이 정의한 Repository 인터페이스를 구현한다.
- `Presentation`은 UseCase만 호출하고, Repository/DataSource를 직접 참조하지 않는다.

## 2. 폴더 구조

```
lib/
├── main.dart
├── app.dart                         # MaterialApp, 라우터, 테마 부착
│
├── core/
│   ├── config/                      # env, flavor 설정
│   ├── router/                      # GoRouter 설정, route guard
│   ├── theme/                       # 컬러/타이포/컴포넌트 테마
│   ├── network/                     # Dio 클라이언트, interceptor
│   ├── database/                    # Drift 스키마, DAO
│   ├── error/                       # Failure, Exception 타입
│   ├── utils/                       # 포맷터, 검증기
│   └── widgets/                     # 공용 위젯 (BenefitCard, StatusBadge 등)
│
├── features/
│   ├── onboarding/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/        # abstract interface
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/           # riverpod
│   │       ├── views/
│   │       └── widgets/
│   │
│   ├── profile/                     # 위와 동일한 3계층 구조
│   ├── home_dashboard/
│   ├── benefit_search/
│   ├── benefit_detail/
│   ├── eligibility_engine/          # 룰 평가 도메인 로직 (UI 없음, domain+data 중심)
│   ├── ai_chat/
│   ├── notifications/
│   ├── bookmarks/
│   ├── benefit_compare/
│   ├── savings_calculator/
│   └── government_calendar/
│
└── shared/
    ├── entities/                    # Benefit, Region, Category 등 여러 feature가 공유
    └── providers/                   # 전역 provider (currentProfile 등)
```

### 폴더 구조 설계 근거

- `eligibility_engine`은 UI가 없는 순수 도메인 feature다. `benefit_detail`, `home_dashboard`, `ai_chat`이 모두 이 feature의 UseCase(`EvaluateEligibilityUseCase`)를 재사용한다.
- `Benefit`, `Region`, `Category` 등 여러 feature가 공유하는 엔티티는 `shared/entities`에 두어 feature 간 순환 의존을 방지한다.

## 3. 상태관리 전략 (Riverpod)

| 상황 | 선택 |
|---|---|
| 서버/DB에서 비동기로 가져오는 리스트/상세 데이터 | `@riverpod` + `AsyncNotifier` (코드젠) |
| 사용자 입력 폼 상태 (온보딩, 프로필 편집) | `@riverpod` + `Notifier` (동기 상태) |
| 파생 계산값 (예: 자격 판정 결과 = 프로필 + 룰 조합) | `Provider` (family, autoDispose) — 입력이 바뀌면 자동 재계산 |
| 전역으로 앱 전체가 구독하는 상태 (현재 프로필, 인증 상태) | `shared/providers`에 위치한 최상위 Provider, `ref.watch`로 각 feature에서 구독 |
| 화면 로컬 UI 상태 (탭 인덱스, 바텀시트 열림 여부) | `StateProvider` 또는 `flutter_hooks`의 `useState` |

- 모든 Provider는 `riverpod_generator` 코드젠 방식(`@riverpod`)으로 통일 — 보일러플레이트 감소, 타입 안전성 확보.
- 자격 판정 결과처럼 프로필이 바뀔 때마다 전체 재계산이 필요한 값은 `Provider.family`로 만들어 `currentProfileProvider`를 `ref.watch`하게 하면, 프로필 갱신 시 의존하는 모든 화면이 자동으로 리빌드된다 (홈 화면 "즉시 재계산" 요구사항 충족).
- `autoDispose`를 기본으로 사용하고, 캐시가 필요한 데이터(홈 대시보드 등)만 `keepAlive`.

## 4. 코드 생성 도구

| 도구 | 용도 |
|---|---|
| `freezed` | Entity/State의 불변 데이터 클래스, `sealed class`로 상태(Loading/Data/Error) 모델링 |
| `json_serializable` | API DTO ↔ JSON 변환 |
| `riverpod_generator` | Provider 코드젠 |
| `drift` | 로컬 DB 스키마/DAO 코드젠 |
| `go_router_builder` (선택) | 타입 세이프 라우트 |

빌드 명령: `dart run build_runner watch -d`

## 5. 라우팅 (GoRouter)

- `ShellRoute`로 홈/검색/알림/프로필 하단 탭 구성
- 딥링크: `hyetaek://benefit/{id}` — 알림 탭 시 상세로 즉시 이동
- 온보딩 미완료 시 `redirect`로 강제 이동하는 라우트 가드
