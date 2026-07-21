import '../../shared/entities/user_profile.dart';
import 'rule_models.dart';

enum _GroupResult { allPassed, missingData, failed }

/// docs/05 section 2 "평가 알고리즘"의 Dart 구현.
/// 판단(YES/NO/금액)은 여기서 결정론적으로 계산되고, AI는 이 결과를 설명만 한다 (docs/00 설계 원칙 1).
EligibilityResult evaluate(EligibilityRule rule, Map<String, dynamic> fields) {
  final trace = <ConditionTrace>[];
  final result = _evaluateGroup(rule.rootGroup, fields, trace);

  final status = switch (result) {
    _GroupResult.allPassed => EligibilityStatus.eligible,
    _GroupResult.missingData => EligibilityStatus.possiblyEligible,
    _GroupResult.failed => EligibilityStatus.notEligible,
  };

  return EligibilityResult(status: status, trace: trace);
}

_GroupResult _evaluateGroup(RuleGroup group, Map<String, dynamic> fields, List<ConditionTrace> trace) {
  final conditionResults = group.conditions.map((c) => _evaluateCondition(c, fields, trace)).toList();
  final subGroupResults = group.subGroups.map((g) => _evaluateGroup(g, fields, trace)).toList();
  final all = [...conditionResults, ...subGroupResults];

  bool passed(dynamic r) => r == true || r == _GroupResult.allPassed;
  bool missing(dynamic r) => r == null || r == _GroupResult.missingData;

  switch (group.operator) {
    case GroupOperator.and:
      if (all.every(passed)) return _GroupResult.allPassed;
      if (all.any(missing)) return _GroupResult.missingData;
      return _GroupResult.failed;
    case GroupOperator.or:
      if (all.any(passed)) return _GroupResult.allPassed;
      if (all.any(missing)) return _GroupResult.missingData;
      return _GroupResult.failed;
    case GroupOperator.not:
      final single = all.single;
      if (missing(single)) return _GroupResult.missingData;
      return passed(single) ? _GroupResult.failed : _GroupResult.allPassed;
  }
}

/// bool? 반환: true=통과, false=불충족, null=정보 부족(exists 실패) — docs/05 "missingData" 개념.
bool? _evaluateCondition(RuleCondition c, Map<String, dynamic> fields, List<ConditionTrace> trace) {
  final actual = fields[c.field];

  if (actual == null) {
    trace.add(ConditionTrace(
      field: c.field,
      humanFieldName: c.humanFieldName,
      passed: null,
      detail: '${c.humanFieldName} 정보가 없어 이 조건은 판정할 수 없습니다. 프로필을 채우면 확인할 수 있어요.',
    ));
    return null;
  }

  final passed = _matches(actual, c.operator, c.value);
  trace.add(ConditionTrace(
    field: c.field,
    humanFieldName: c.humanFieldName,
    passed: passed,
    detail: _describe(c, actual, passed),
  ));
  return passed;
}

bool _matches(dynamic actual, ConditionOperator op, dynamic expected) {
  switch (op) {
    case ConditionOperator.eq:
      return actual == expected;
    case ConditionOperator.neq:
      return actual != expected;
    case ConditionOperator.gte:
      return (actual as num) >= (expected as num);
    case ConditionOperator.lte:
      return (actual as num) <= (expected as num);
    case ConditionOperator.between:
      final range = expected as List;
      return (actual as num) >= (range[0] as num) && actual <= (range[1] as num);
    case ConditionOperator.inList:
      return (expected as List).contains(actual);
    case ConditionOperator.notInList:
      return !(expected as List).contains(actual);
    case ConditionOperator.exists:
      return true; // null 케이스는 위에서 이미 걸러짐
  }
}

/// docs/05 "WHY 설명 생성" — 템플릿 기반 정적 문자열 조합, LLM 호출 없이 즉시/결정론적으로 생성.
String _describe(RuleCondition c, dynamic actual, bool passed) {
  final actualLabel = _formatValue(c.field, actual);
  final verb = passed ? '충족합니다' : '충족하지 못합니다';

  switch (c.operator) {
    case ConditionOperator.between:
      final range = c.value as List;
      return '${c.humanFieldName} $actualLabel(은)는 ${_formatValue(c.field, range[0])}~${_formatValue(c.field, range[1])} 조건을 $verb.';
    case ConditionOperator.gte:
      return '${c.humanFieldName} $actualLabel(은)는 ${_formatValue(c.field, c.value)} 이상 조건을 $verb.';
    case ConditionOperator.lte:
      return '${c.humanFieldName} $actualLabel(은)는 ${_formatValue(c.field, c.value)} 이하 조건을 $verb.';
    case ConditionOperator.eq:
      return '${c.humanFieldName} $actualLabel(은)는 ${_formatValue(c.field, c.value)} 조건을 $verb.';
    case ConditionOperator.neq:
      return '${c.humanFieldName} $actualLabel(은)는 ${_formatValue(c.field, c.value)}가 아니어야 하는 조건을 $verb.';
    case ConditionOperator.inList:
      final options = (c.value as List).map((v) => _formatValue(c.field, v)).join(', ');
      return '${c.humanFieldName} $actualLabel(은)는 [$options] 중 하나여야 하는 조건을 $verb.';
    case ConditionOperator.notInList:
      final options = (c.value as List).map((v) => _formatValue(c.field, v)).join(', ');
      return '${c.humanFieldName} $actualLabel(은)는 [$options]에 해당하지 않아야 하는 조건을 $verb.';
    case ConditionOperator.exists:
      return '${c.humanFieldName} 정보가 등록되어 있습니다.';
  }
}

String _formatValue(String field, dynamic value) {
  if (value == null) return '정보 없음';
  switch (field) {
    case 'age':
      return '$value세';
    case 'incomeAnnual':
      final won = value as num;
      if (won >= 100000000) return '${(won / 100000000).toStringAsFixed(won % 100000000 == 0 ? 0 : 1)}억원';
      return '${(won / 10000).toStringAsFixed(0)}만원';
    case 'regionCode':
      return regionOptions[value] ?? value.toString();
    case 'employmentStatus':
      return EmploymentStatus.values.byName(value as String).label;
    case 'housingStatus':
      return HousingStatus.values.byName(value as String).label;
    case 'militaryStatus':
      return switch (value as String) {
        'notApplicable' => '해당없음',
        'active' => '복무중',
        'completed' => '복무완료',
        'exempted' => '면제',
        _ => value,
      };
    case 'isMarried':
      return value == true ? '기혼' : '미혼';
    case 'isStudent':
      return value == true ? '학생' : '비학생';
    case 'hasDisability':
      return value == true ? '해당' : '비해당';
    case 'childrenCount':
      return '자녀 $value명';
    default:
      return value.toString();
  }
}
