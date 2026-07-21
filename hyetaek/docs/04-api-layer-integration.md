# 04. API 레이어 설계 + API 문서

## 1. 전체 데이터 흐름

```
[정부 Open API들]  ──(배치 수집)──▶  [수집 파이프라인]  ──정규화──▶  [내부 DB]
   (정부24, 공공데이터포털,                 │
    청년정책, 고용24, 주거 API 등)           ▼
                                    [내부 REST API 서버]
                                          │
                                          ▼
                                  [Flutter 앱 (Dio)]
                                          │
                                          ▼
                                  [Drift 로컬 캐시]
```

핵심 설계 결정: **Flutter 앱은 정부 Open API를 직접 호출하지 않는다.** 대신 자체 백엔드가 여러 정부 API를 배치로 수집·정규화하여 하나의 내부 API로 통합 제공한다.

이유:
1. 정부 API마다 인증방식/응답 포맷/Rate Limit이 제각각이라 클라이언트에서 직접 다루면 파편화된다.
2. API 키를 클라이언트에 노출하지 않는다 (보안).
3. 룰 엔진 평가, 랭킹 계산처럼 무거운 연산을 서버에서 선계산해 클라이언트 배터리/성능을 아낀다.
4. 새 데이터 소스 추가 시 서버의 어댑터만 추가하면 되고 앱 배포가 필요 없다.

## 2. 정부 Open API 어댑터 패턴 (서버 측)

```dart
// 서버 측 개념 모델 (언어 무관, Dart 의사코드로 계약만 표현)
abstract class GovernmentApiAdapter {
  String get sourceName;
  Future<List<RawBenefitDto>> fetchLatest({DateTime? since});
  NormalizedBenefit normalize(RawBenefitDto raw);
}

class Gov24Adapter implements GovernmentApiAdapter { ... }
class PublicDataPortalAdapter implements GovernmentApiAdapter { ... }
class YouthPolicyAdapter implements GovernmentApiAdapter { ... }
class Employment24Adapter implements GovernmentApiAdapter { ... }
class HousingApiAdapter implements GovernmentApiAdapter { ... }
```

- 각 어댑터는 원본 응답을 `NormalizedBenefit`(공통 스키마, [02번 문서](02-database-schema-erd.md)의 `benefit` 테이블과 1:1 대응)으로 변환.
- 수집 스케줄러(cron/큐)가 어댑터를 순회하며 증분 동기화(`since` 파라미터) 수행 → `benefit_source.last_synced_at` 갱신.
- 신규 소스 추가 = 새 어댑터 클래스 구현 + 스케줄러 등록. 기존 코드 변경 없음 (OCP).

## 3. 클라이언트 API 레이어 (Dio)

```
core/network/
├── api_client.dart          # Dio 인스턴스, baseUrl, timeout
├── interceptors/
│   ├── auth_interceptor.dart      # 토큰 첨부, 401 시 refresh
│   ├── logging_interceptor.dart   # 디버그 로깅 (release 비활성)
│   ├── retry_interceptor.dart     # 지수 백오프 재시도 (네트워크 오류/5xx)
│   └── cache_interceptor.dart     # ETag 기반 조건부 요청
└── api_exception.dart        # Dio 에러 → 앱 Failure로 매핑
```

- Repository 구현체는 `RemoteDataSource`(Dio 호출) + `LocalDataSource`(Drift)를 함께 주입받아, **네트워크 우선 시도 → 실패 시 로컬 캐시 폴백** 전략을 기본으로 한다.
- 에러는 Dio 예외를 도메인 레벨의 `Failure`(freezed sealed class: `NetworkFailure`, `ServerFailure`, `CacheFailure`)로 변환해 Presentation에 전달한다.

## 4. 내부 REST API 문서 (서버가 앱에 제공하는 API)

### `GET /v1/benefits`
개인화되지 않은 전체 혜택 목록 (필터/페이지네이션)

Query: `category`, `region`, `sort=deadline|amount|popularity`, `page`, `size`

```json
// Response 200
{
  "items": [
    {
      "id": "b_123",
      "title": "청년월세 특별지원",
      "amountMin": 200000,
      "amountMax": 200000,
      "deadline": "2026-12-31",
      "category": "housing",
      "popularityScore": 87
    }
  ],
  "page": 1,
  "totalPages": 12
}
```

### `POST /v1/eligibility/evaluate`
프로필을 보내면 룰 엔진이 전체 혜택에 대해 평가 후 랭킹된 결과 반환 (핵심 엔드포인트)

```json
// Request
{
  "profile": {
    "birthYear": 1999,
    "regionCode": "41111",
    "employmentStatus": "employee",
    "incomeAnnual": 32000000,
    "isMarried": false
  }
}

// Response 200
{
  "results": [
    {
      "benefitId": "b_123",
      "status": "ELIGIBLE",
      "amountEstimate": 2400000,
      "reasons": [
        { "field": "age", "passed": true, "detail": "만 26세는 19~34세 조건 충족" },
        { "field": "income", "passed": true, "detail": "연소득 3,200만원은 5,000만원 이하 조건 충족" }
      ],
      "score": 92
    }
  ],
  "estimatedMonthlyTotal": 200000,
  "estimatedYearlyTotal": 2400000
}
```

### `GET /v1/benefits/{id}`
혜택 상세 (FAQ, AI 요약 포함)

### `POST /v1/ai/chat`
AI 챗 메시지 전송 (상세 계약은 [06-ai-integration-design.md](06-ai-integration-design.md))

### `GET /v1/notifications`, `PATCH /v1/notifications/{id}/read`

### `GET /v1/sync/benefits?since={timestamp}`
클라이언트 증분 동기화용 (변경분만 반환)

## 5. 에러 처리 & 재시도 전략

| 상황 | 클라이언트 동작 |
|---|---|
| 네트워크 끊김 | 즉시 로컬 캐시 데이터 표시 + 상단 배너로 "오프라인" 안내 |
| 5xx / 타임아웃 | 지수 백오프로 최대 3회 재시도 후 캐시 폴백 |
| 정부 API 자체 장애 (서버 배치 실패) | `benefit_source.sync_status`로 감지 → 관리자 알림, 클라이언트는 마지막 정상 데이터 계속 제공 |
| 401 | refresh token으로 1회 재시도, 실패 시 재로그인 유도 |

## 6. Rate Limit 대응

- 정부 Open API는 보통 일일 호출 제한이 있으므로, 서버 배치 수집 시 소스별 호출 큐 + 속도 제한(rate limiter)을 적용.
- API 키는 소스당 여러 개 발급받아 로테이션(부하 분산), 서버 환경변수/시크릿 매니저에서만 관리 — 클라이언트에는 절대 배포하지 않음.
