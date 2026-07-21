# 06. AI 통합 설계 (LLM 벤더 비종속)

## 1. 설계 원칙 — "AI는 설명한다, 판정하지 않는다"

가장 중요한 안전장치: **자격 여부(ELIGIBLE/POSSIBLY/NOT)와 금액은 항상 [룰 엔진](05-eligibility-rule-engine.md)이 결정한다.** LLM은 그 결과 + 원본 혜택 문서를 컨텍스트로 받아서 **자연어로 요약/설명/추천 우선순위 부여**만 수행한다. 이렇게 분리하는 이유:

- LLM의 환각(hallucination)이 "받을 수 있다/없다", "얼마" 같은 사실 정보를 오염시키지 않도록 구조적으로 차단.
- 어떤 LLM 공급자를 쓰든(또는 나중에 교체하든) 판정 로직은 전혀 영향받지 않음.

## 2. Provider 비종속 추상화 계층

```dart
// domain/ai/ai_provider.dart — 특정 벤더에 의존하지 않는 인터페이스
abstract class AiProvider {
  Stream<String> chat({
    required List<AiMessage> history,
    required AiContext context,   // 룰엔진 결과, 프로필, 관련 혜택 문서
  });

  Future<ExtractedProfile> extractProfileFromText(String userInput);
}

class AiContext {
  final UserProfile? profile;
  final List<EligibilityResult> relevantResults; // 룰엔진이 이미 계산한 결과
  final List<Benefit> relevantBenefits;          // RAG로 검색된 관련 혜택 원문
}
```

- 구현체(`AnthropicProvider`, `OpenAiProvider`, `LocalLlmProvider` 등)는 이 인터페이스만 만족하면 되므로, `ai_chat` feature의 UseCase/Presentation 코드는 어떤 구현체를 쓰는지 전혀 몰라도 된다 (의존성 역전).
- 서버 사이드에서 Provider를 선택/교체할 수 있도록 API 계약(`POST /v1/ai/chat`)만 클라이언트와 고정하고, 실제 LLM 호출은 백엔드에서 수행 (API 키를 클라이언트에 노출하지 않기 위함이기도 함).

## 3. RAG 파이프라인

```
사용자 질문
   → (1) 프로필 추출/보강 시도 (extractProfileFromText)
   → (2) 관련 혜택 검색 (벡터/키워드 하이브리드 검색 — benefit.title/description 임베딩)
   → (3) 검색된 혜택 각각에 대해 룰 엔진 평가 실행 (evaluate)
   → (4) LLM에 프롬프트 조립:
        - 시스템: "너는 룰 엔진이 계산한 결과만 근거로 설명한다. 결과에 없는 자격/금액을 새로 만들지 마라."
        - 컨텍스트: 룰엔진 trace + 혜택 원문 요약
        - 질문: 사용자 원문
   → (5) LLM 응답 스트리밍 반환 + 각 혜택 카드에 "출처: 공식 페이지 링크" 첨부
```

## 4. 대화형 프로필 추출

자연어 → 구조화 필드 매핑 (LLM의 function-calling/structured-output 기능 활용, Provider별 구현은 캡슐화):

```json
// 입력: "저 26살이고 연봉 3500이고 수원 살아요"
// extractProfileFromText 결과
{
  "birthYear": 2000,
  "incomeAnnual": 35000000,
  "regionCode": "suwon",
  "confidence": { "birthYear": 0.95, "incomeAnnual": 0.9, "regionCode": 0.98 }
}
```

- 추출된 값은 **바로 프로필에 반영하지 않고** "이 정보를 프로필에 저장할까요?" confirm UI를 거친다 (사용자 동의 없는 자동 저장 금지 — 민감정보이므로).

## 5. 시나리오별 응답 설계

### 시나리오 A — 특정 혜택 질의 ("청년도약계좌 될까?")
1. 혜택명 매칭(퍼지 검색) → 해당 혜택의 룰 평가
2. 응답 템플릿: 자격여부 / 이유 / 필요서류 / 금액 / 마감일 / 신청 링크

### 시나리오 B — 상황 서술형 ("퇴사하려고 해요")
1. 상황 → 관련 카테고리 매핑 테이블 참조 (`resignation` → 실업급여, 국민내일배움카드, 건강보험 임의계속가입, 지역별 구직지원금)
2. 매핑된 카테고리 내 혜택들에 대해 현재 프로필 기준 일괄 평가
3. "지금은 해당 없지만 퇴사 후 조건이 바뀌면 자격이 생기는" 항목은 별도로 "퇴사 시 예상 자격" 섹션으로 분리 — 프로필의 가상 변경(what-if) 평가를 룰 엔진에 한 번 더 돌려서 만든다

### 시나리오 C — 생애 이벤트형 ("이사 가요")
- `moving` 카테고리 매핑: 주거지원, 이사비 지원, 청년 전월세, 전입 지역 신규 지원, 전기요금 할인 등
- 새 지역 코드를 임시로 가정한 what-if 평가 결과 제시

## 6. what-if 평가 (가상 프로필 시뮬레이션)

룰 엔진은 순수 함수이므로 실제 프로필을 변경하지 않고 임시 프로필을 넣어 평가할 수 있다. 이 특성을 활용해 "자격 타임라인"(나이가 1살씩 늘어날 때 자격이 어떻게 바뀌는지), "퇴사하면", "결혼하면" 같은 시나리오를 모두 동일한 평가 함수로 처리한다. AI는 이 what-if 결과들을 자연스러운 문장으로 엮어주는 역할만 한다.

## 7. 안전장치 요약

| 위험 | 대응 |
|---|---|
| LLM이 없는 혜택을 지어냄 | 응답에 언급 가능한 혜택은 반드시 검색된 `relevantBenefits` 목록 내로 제한 (프롬프트 제약 + 후처리 검증: 응답에서 언급된 혜택명이 컨텍스트 목록에 있는지 체크) |
| LLM이 잘못된 금액/자격을 말함 | 금액·자격 상태는 템플릿 슬롯으로 강제 삽입, LLM 자유생성 영역에서 제외 |
| 민감정보(소득 등) 로깅 | 대화 로그 저장 시 소득/연락처 등은 마스킹 후 저장, 원문은 세션 종료 후 일정 기간 뒤 파기 |
| 응답 지연 | 스트리밍 응답 + 룰엔진 결과(구조화 데이터)는 즉시 먼저 렌더링, 자연어 설명만 스트리밍으로 뒤따라옴 |
