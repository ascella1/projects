# 혜택(Hyetaek) — 제품 개요

## 한 줄 정의

**"내가 지금 당장 받을 수 있는 정부 혜택을, AI가 찾아서 왜 받을 수 있는지까지 설명해주는 개인화 대시보드"**

정부24, 복지로처럼 "찾아서 읽어야 하는" 포털이 아니라, 사용자의 프로필을 기반으로 **자격 요건을 자동 계산하고 금액·마감일·인기도로 랭킹**해서 보여주는 핀테크 앱 수준의 경험을 제공한다.

## 문제 정의

- 대한민국 정부·지자체 혜택은 수천 개가 존재하지만, 각 부처/지자체 사이트가 분산되어 있고 검색 UX가 나쁘다.
- 자격 요건은 텍스트로만 제공되어 본인이 해당되는지 스스로 판단해야 한다.
- 마감일을 놓치거나, 나이/소득 조건이 바뀌어 새로 자격이 생겨도 알 방법이 없다.
- "나에게 맞는 것"을 걸러주는 개인화 계층이 없다.

## 타겟 페르소나 (요약 — 상세는 [01-product-specification](01-product-specification.md))

| 페르소나 | 핵심 니즈 |
|---|---|
| 사회초년생/청년 구직자 | 청년정책(도약계좌, 월세지원, 구직수당) 자동 매칭 |
| 신혼부부/출산가구 | 결혼·출산·주거 관련 대규모 지원금 놓치지 않기 |
| 프리랜서/소상공인 | 고용보험 사각지대 지원, 창업 지원금 |
| 이직/퇴사 예정자 | 상황 변화에 따른 혜택 시나리오 안내 |

## 핵심 설계 원칙

1. **판단은 룰엔진, 설명은 AI** — 자격 여부(YES/NO)와 금액은 결정론적 룰 엔진이 계산하고, AI는 그 결과를 자연어로 설명·요약만 한다. AI가 자격을 "지어내지" 않도록 구조적으로 분리한다.
2. **출처 명시** — 모든 혜택 카드는 원본 공공 API/공식 페이지로 연결되는 링크를 항상 노출한다.
3. **오프라인 우선 캐시** — 정부 API는 느리고 불안정할 수 있으므로, 로컬 캐시(Drift)를 기본 데이터 소스로 삼고 백그라운드 동기화한다.
4. **데이터 소스 어댑터 확장성** — 새로운 정부 Open API가 추가되어도 기존 코드를 건드리지 않고 어댑터만 추가하면 되는 구조.
5. **개인정보 최소 수집 + 로컬 우선 처리** — 소득·자산 등 민감 정보는 가능한 로컬에서 계산하고, 서버 전송 시 암호화한다.

## 문서 목차

| # | 문서 | 내용 |
|---|---|---|
| 1 | [01-product-specification.md](01-product-specification.md) | 전체 제품 기획서, 페르소나, 핵심 플로우, UI 스타일 |
| 2 | [02-database-schema-erd.md](02-database-schema-erd.md) | DB 스키마 + ERD |
| 3 | [03-flutter-architecture.md](03-flutter-architecture.md) | 폴더 구조, Clean Architecture, 상태관리 전략 |
| 4 | [04-api-layer-integration.md](04-api-layer-integration.md) | API 레이어 설계 + API 문서 |
| 5 | [05-eligibility-rule-engine.md](05-eligibility-rule-engine.md) | 자격 판정 룰 엔진 설계 |
| 6 | [06-ai-integration-design.md](06-ai-integration-design.md) | AI 통합 설계 (LLM 비종속) |
| 7 | [07-ui-wireframes.md](07-ui-wireframes.md) | 화면별 와이어프레임 |
| 8 | [08-roadmap-mvp-premium.md](08-roadmap-mvp-premium.md) | 개발 로드맵, MVP, 프리미엄 기능 |
| 9 | [09-testing-security-performance.md](09-testing-security-performance.md) | 테스트/보안/성능 전략 |
| 10 | [10-deployment-scalability.md](10-deployment-scalability.md) | 배포 전략 + 확장성 (100만 유저 대비) |
| 11 | [11-monetization.md](11-monetization.md) | 수익화 전략 |
| 12 | [12-admin-backend.md](12-admin-backend.md) | 관리자 백엔드 / 룰 에디터 |

## 기술 스택 요약

- **클라이언트**: Flutter, Riverpod(코드젠), GoRouter, Dio, Drift(로컬 DB), Hive(경량 캐시/설정), Freezed + json_serializable
- **서버(백엔드)**: 별도 REST API 서버 (언어/프레임워크는 팀 상황에 맞게 선택 — 문서에서는 인터페이스 계약 중심으로 기술) + 배치 수집 파이프라인 + 관리자 API
- **AI**: LLM Provider 추상화 계층 (특정 벤더에 종속되지 않도록 인터페이스 설계, [06 참고](06-ai-integration-design.md))
