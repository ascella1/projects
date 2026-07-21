/// docs/05-eligibility-rule-engine.md 의 데이터 모델을 그대로 Dart로 옮긴 것.
/// UI(Flutter)에 의존하지 않는 순수 도메인 로직 — Presentation은 evaluator.dart의 결과만 소비한다.
library;

enum ConditionOperator { eq, neq, gte, lte, between, inList, notInList, exists }

enum GroupOperator { and, or, not }

enum EligibilityStatus { eligible, possiblyEligible, notEligible }

class RuleCondition {
  final String field; // 'age' | 'incomeAnnual' | 'regionCode' | 'employmentStatus' ...
  final ConditionOperator operator;
  final dynamic value;
  final String humanFieldName; // '나이', '연소득', '거주지' ...

  const RuleCondition({
    required this.field,
    required this.operator,
    required this.value,
    required this.humanFieldName,
  });
}

class RuleGroup {
  final GroupOperator operator;
  final List<RuleCondition> conditions;
  final List<RuleGroup> subGroups;

  const RuleGroup({
    required this.operator,
    this.conditions = const [],
    this.subGroups = const [],
  });
}

class EligibilityRule {
  final String benefitId;
  final int version;
  final RuleGroup rootGroup;

  const EligibilityRule({
    required this.benefitId,
    required this.rootGroup,
    this.version = 1,
  });
}

/// docs/05 ConditionTrace — WHY 설명의 원재료. 판정 자체가 아니라 "왜 그런 판정이 나왔는지"를 남긴다.
class ConditionTrace {
  final String field;
  final String humanFieldName;
  final bool? passed; // null = 정보 부족(exists 실패)
  final String detail;

  const ConditionTrace({
    required this.field,
    required this.humanFieldName,
    required this.passed,
    required this.detail,
  });
}

class EligibilityResult {
  final EligibilityStatus status;
  final List<ConditionTrace> trace;

  const EligibilityResult({required this.status, required this.trace});

  bool get isMissingInfo => trace.any((t) => t.passed == null);
}
