# 09. 테스트 / 보안 / 성능 전략

## 1. 테스트 전략

### 우선순위 1 — 룰 엔진 (유닛 테스트)
- 가장 높은 커버리지 목표(90%+). 자격 판정이 틀리면 제품 신뢰 자체가 무너짐.
- 조건 연산자별(eq/between/inList 등), 그룹 연산자(and/or/not), 중첩 그룹, 정보 부족(POSSIBLY_ELIGIBLE) 케이스를 표 기반 테스트(table-driven test)로 커버.
- 실제 정책 사례를 픽스처로 저장해 회귀 테스트 (정책 개정으로 룰이 바뀔 때 의도치 않은 회귀 방지).

### 우선순위 2 — Repository / DataSource (계약 테스트)
- 정부 API 어댑터: 응답 스키마 변경을 조기 감지하는 contract test (실제 API 대신 저장된 fixture 응답으로 검증, CI에서 실제 외부 호출 금지).
- 로컬-원격 폴백 로직 테스트 (네트워크 실패 시 캐시 반환 확인).

### 우선순위 3 — Widget / Golden 테스트
- `BenefitCard`, `StatusBadge` 등 공용 위젯의 골든 테스트로 다크모드/라이트모드 회귀 방지.
- 홈 대시보드, 상세 페이지의 상태별(Loading/Data/Error/Empty) 위젯 테스트.

### 우선순위 4 — 통합/E2E 테스트
- `integration_test`로 온보딩 → 홈 → 상세 → 신청 링크 이동까지 핵심 플로우 자동화.
- AI 챗은 실제 LLM 호출 대신 Mock Provider로 결정론적 응답 검증.

### CI 게이트
- PR마다: `flutter analyze` + 유닛/위젯 테스트 + 룰 엔진 커버리지 임계값 체크.

## 2. 보안 전략

### 개인정보 보호
- 소득, 연락처 등 민감 필드는 **클라이언트 로컬 DB에 암호화 저장** (Drift + SQLCipher 또는 OS Keystore 연동 암호화).
- 서버 DB에서도 민감 컬럼은 앱 레벨 암호화(AES-GCM) 후 저장, 평문 로그 금지.
- 룰 평가는 가능한 한 클라이언트에서 로컬로도 수행 가능하게 설계(룰 데이터는 캐시되어 있으므로) — 소득 정보를 매번 서버로 보내지 않고 로컬 평가 우선, 서버는 랭킹/AI 등 보강 용도로만 사용.

### 인증/인가
- 소셜 로그인(카카오/애플/구글) 우선, 게스트 모드 지원(온보딩만으로 로컬 사용 가능, 계정 연동은 선택).
- 서버 API는 JWT(access 짧게, refresh 길게) + 토큰 재발급 인터셉터.
- 관리자 API는 완전히 분리된 인증 도메인 + 역할기반 접근제어(RBAC) — [12 참고](12-admin-backend.md).

### 통신/인프라
- 모든 통신 TLS 1.2+, 인증서 핀닝(민감 API 한정) 검토.
- 정부 API 키는 서버 시크릿 매니저 보관, 클라이언트 미노출.
- OWASP Mobile Top 10 기준 점검 (루팅/탈옥 탐지는 필수 아님, 민감정보 로컬 암호화로 대응).

### 컴플라이언스
- 개인정보처리방침/이용약관에 공공데이터 활용 근거 명시, 개인정보 수집 항목 최소화 및 목적 명시.
- 회원 탈퇴 시 개인정보 즉시/유예기간 후 파기 프로세스.

## 3. 성능 최적화

### 클라이언트
- 홈 대시보드는 **로컬 캐시 우선 렌더** 후 백그라운드 동기화 (콜드스타트 체감속도 최우선).
- 리스트는 `ListView.builder` + 이미지 지연로딩/캐싱(`cached_network_image`).
- 룰 엔진 평가(수백 개 혜택 × 사용자 1명)는 메인 스레드 블로킹 방지를 위해 **Isolate**에서 실행 (`compute()` 또는 격리된 worker isolate).
- Riverpod `autoDispose` + `select`로 불필요한 리빌드 최소화.

### 서버
- 룰 평가 결과는 `(profile_hash, rule_version)` 키로 캐시(Redis) — 동일 프로필 재조회 시 재계산 생략.
- 혜택 목록/상세는 CDN 캐시 가능한 정적성 높은 데이터로 취급(짧은 TTL + 배치 갱신 시 invalidate).
- 검색은 Elasticsearch/PostgreSQL Full-Text Search로 자연어 키워드 매칭.

### 모니터링
- 크래시/성능: Firebase Crashlytics + Performance Monitoring 또는 Sentry.
- 핵심 지표: 콜드스타트 시간, API p95 latency, 룰엔진 평가 시간, AI 응답 첫 토큰까지 시간(TTFT).
