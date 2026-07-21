# 05. 자격 판정 룰 엔진 설계 (Smart Eligibility Engine)

이 앱의 신뢰성은 전적으로 이 엔진에 달려 있다. **AI는 이 엔진의 판정을 절대 대체하지 않는다** — AI는 결과를 설명하는 역할만 한다 ([06 참고](06-ai-integration-design.md)).

## 1. 데이터 모델

```dart
enum ConditionOperator { eq, neq, gte, lte, between, inList, notInList, exists }
enum GroupOperator { and, or, not }
enum EligibilityStatus { eligible, possiblyEligible, notEligible }

class RuleCondition {
  final String field;              // 'age' | 'incomeAnnual' | 'regionCode' | 'employmentStatus' ...
  final ConditionOperator operator;
  final dynamic value;             // 18, [18,34], 'seoul', ['employee','freelancer'] 등
}

class RuleGroup {
  final GroupOperator operator;
  final List<RuleCondition> conditions;
  final List<RuleGroup> subGroups;  // 중첩 그룹 (예: (지역=서울 OR 지역=경기) AND 나이<=34)
}

class EligibilityRule {
  final String benefitId;
  final int version;
  final RuleGroup rootGroup;
}
```

### 예시 — 청년도약계좌 룰

```json
{
  "operator": "and",
  "conditions": [
    { "field": "age", "operator": "between", "value": [19, 34] },
    { "field": "incomeAnnual", "operator": "lte", "value": 75000000 }
  ],
  "subGroups": []
}
```

### 예시 — 중첩 그룹 (서울 또는 경기 거주 + 무주택)

```json
{
  "operator": "and",
  "conditions": [
    { "field": "housingStatus", "operator": "eq", "value": "no_house" }
  ],
  "subGroups": [
    {
      "operator": "or",
      "conditions": [
        { "field": "regionCode", "operator": "eq", "value": "seoul" },
        { "field": "regionCode", "operator": "eq", "value": "gyeonggi" }
      ]
    }
  ]
}
```

## 2. 평가 알고리즘 (의사코드)

```dart
EligibilityResult evaluate(EligibilityRule rule, UserProfile profile) {
  final trace = <ConditionTrace>[];
  final result = evaluateGroup(rule.rootGroup, profile, trace);

  final status = switch (result) {
    GroupResult.allPassed => EligibilityStatus.eligible,
    GroupResult.missingData => EligibilityStatus.possiblyEligible, // 필드 값이 없어 판정 불가
    GroupResult.failed => EligibilityStatus.notEligible,
  };

  return EligibilityResult(status: status, trace: trace);
}

GroupResult evaluateGroup(RuleGroup group, UserProfile profile, List<ConditionTrace> trace) {
  final conditionResults = group.conditions.map((c) => evaluateCondition(c, profile, trace));
  final subGroupResults = group.subGroups.map((g) => evaluateGroup(g, profile, trace));
  final all = [...conditionResults, ...subGroupResults];

  return switch (group.operator) {
    GroupOperator.and => all.every(passed) ? allPassed
                       : all.any(missingData) ? missingData
                       : failed,
    GroupOperator.or  => all.any(passed) ? allPassed
                       : all.any(missingData) ? missingData
                       : failed,
    GroupOperator.not => !all.single.passed ? allPassed : failed,
  };
}
```

핵심 포인트:
- 프로필에 해당 필드 값이 아예 없으면(`exists` 실패) `POSSIBLY_ELIGIBLE`로 분류 — "정보 부족" 상태를 명확히 구분해 사용자에게 "이 정보를 입력하면 더 정확한 판정이 가능합니다"라고 유도한다.
- 모든 조건 평가는 `ConditionTrace`(필드, 연산자, 기대값, 실제값, pass/fail)를 남겨 **WHY 설명**의 원재료가 된다.

## 3. WHY 설명 생성

```dart
class ConditionTrace {
  final String field;
  final String humanFieldName;   // '나이', '연소득', '거주지'
  final bool passed;
  final String detail;           // "만 26세는 19~34세 조건을 충족합니다"
}
```

- `humanFieldName`과 `detail` 문구는 **템플릿 기반**(정적 문자열 조합)으로 서버가 생성 — LLM 호출 없이도 즉시, 결정론적으로, 무료로 생성 가능.
- AI 챗은 이 trace 배열을 컨텍스트로 받아 자연스러운 문장으로 재구성만 한다 (숫자나 판정 자체를 새로 만들지 않음).

## 4. 결과 상태 3단계

| 상태 | 의미 | UI |
|---|---|---|
| `ELIGIBLE` | 모든 필수 조건 충족 | 초록 배지, 금액 강조 표시 |
| `POSSIBLY_ELIGIBLE` | 일부 정보 부족으로 확정 불가 | 노랑 배지, "프로필을 채우면 확인 가능" CTA |
| `NOT_ELIGIBLE` | 조건 명백히 불충족 | 회색, 리스트 하단/숨김 처리, 왜 안 되는지 표시 |

## 5. 랭킹 스코어링

`score = w1*eligibilityConfidence + w2*normalizedAmount + w3*urgency(마감임박) + w4*popularity`

- 초기 가중치는 관리자 설정값(운영 중 A/B 테스트로 튜닝), [12-admin-backend.md](12-admin-backend.md)의 룰 에디터에서 조정 가능하게 설계.
- `urgency`는 `deadline`까지 남은 일수의 역수 기반 (D-3 이내 급상승).

## 6. 룰 버전 관리

- 정부 정책은 연중 개정되므로 `eligibility_rule.version`을 증가시키며 이력을 보존한다.
- 특정 시점 기준 "그때는 자격이 있었는지"를 재현할 수 있어야 하므로(신청 이력 추적), 룰은 항상 append-only.
- 관리자가 룰을 수정하면 즉시 `is_current=true`로 전환되고, 서버는 영향받는 사용자에게 재평가 후 변경 알림을 트리거한다 ("당신의 자격 상태가 바뀌었습니다").
