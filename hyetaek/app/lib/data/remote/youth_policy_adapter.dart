import '../../features/eligibility_engine/rule_models.dart';
import '../../shared/entities/benefit.dart';
import 'category_classifier.dart';
import 'youth_policy_dto.dart';

/// docs/04 원칙 "새 데이터 소스 추가 = 새 어댑터"의 클라이언트판.
/// `YouthPolicyDto`(방어적 원본 필드) → 앱이 이미 쓰고 있는 `Benefit`/`EligibilityRule` 모델로 정규화한다.
/// 정보가 부족한 필드(금액, 신청 절차 등)는 seed처럼 엄밀하지 않고 "공식 페이지 확인" 식으로 안내한다.
Benefit? youthPolicyToBenefit(YouthPolicyDto dto) {
  final title = dto.plcyNm;
  final no = dto.plcyNo;
  if (title == null || no == null) return null; // 최소 식별자가 없으면 안전하게 건너뜀

  final id = 'gov-$no';
  final minAge = dto.sprtTrgtMinAge;
  final maxAge = dto.sprtTrgtMaxAge;

  final conditions = <RuleCondition>[];
  if (minAge != null && maxAge != null) {
    conditions.add(RuleCondition(
      field: 'age',
      operator: ConditionOperator.between,
      value: [minAge, maxAge],
      humanFieldName: '나이',
    ));
  } else if (minAge != null) {
    conditions.add(RuleCondition(field: 'age', operator: ConditionOperator.gte, value: minAge, humanFieldName: '나이'));
  } else if (maxAge != null) {
    conditions.add(RuleCondition(field: 'age', operator: ConditionOperator.lte, value: maxAge, humanFieldName: '나이'));
  }

  final targetParts = <String>[
    if (minAge != null && maxAge != null) '만 $minAge~$maxAge세',
    if (dto.mclsfNm != null) dto.mclsfNm!,
  ];

  return Benefit(
    id: id,
    title: title,
    description: dto.plcyExplnCn ?? dto.plcySprtCn ?? '',
    category: classifyCategory(
      [dto.lclsfNm, dto.mclsfNm, dto.plcyKywdNm].whereType<String>().join(' '),
      fallback: BenefitCategory.youth,
    ),
    regionCodes: _parseRegionCodes(dto),
    amountType: AmountType.unknown,
    targetSummary: targetParts.isEmpty ? '자세한 대상 조건은 공식 페이지에서 확인하세요' : targetParts.join(' · '),
    applicationProcess: '온통청년(청년정책) 공식 페이지에서 신청 절차를 확인하세요',
    requiredDocuments: const ['공식 페이지에서 확인'],
    officialUrl: dto.refUrlAddr1 ?? dto.rqutUrlAddr ?? 'https://www.youthcenter.go.kr',
    sourceName: dto.sprvsnInstCdNm ?? '온통청년',
    popularityScore: 50,
    deadline: _parseDeadline(dto),
    rule: EligibilityRule(
      benefitId: id,
      rootGroup: RuleGroup(operator: GroupOperator.and, conditions: conditions),
    ),
  );
}

/// 법정동코드 시도 2자리 → 앱의 단순화된 지역 코드(`user_profile.dart`의 `regionOptions`).
/// 앱 지역 모델에는 울산/충북·충남/전북·전남/경북·경남 구분이 없어 인접 권역으로 근사한다.
const Map<String, String> _sidoToRegionCode = {
  '11': 'seoul',
  '26': 'busan',
  '27': 'daegu',
  '28': 'incheon',
  '29': 'gwangju',
  '30': 'daejeon',
  '31': 'gyeongsang', // 울산
  '36': 'sejong',
  '41': 'gyeonggi',
  '42': 'gangwon',
  '43': 'chungcheong',
  '44': 'chungcheong',
  '45': 'jeolla',
  '46': 'jeolla',
  '47': 'gyeongsang',
  '48': 'gyeongsang',
  '50': 'jeju',
};

List<String> _parseRegionCodes(YouthPolicyDto dto) {
  final zip = dto.zipCd;
  if (zip == null) return [];
  final codes = zip.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  if (codes.isEmpty || codes.any((c) => c.startsWith('00'))) return []; // 전국

  final mapped = codes
      .map((c) => c.length >= 2 ? c.substring(0, 2) : c)
      .map((c) => _sidoToRegionCode[c])
      .whereType<String>()
      .toSet()
      .toList();
  return mapped; // 매핑 실패 시 빈 리스트 = 전국 취급 (지역 제한으로 실수로 숨기지 않기 위함)
}

DateTime? _parseDeadline(YouthPolicyDto dto) {
  final aply = dto.aplyYmd;
  if (aply != null && !aply.contains('상시')) {
    final parts = aply.split(RegExp(r'[~\-]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      final end = _parseYmd(parts.last);
      if (end != null) return end;
    }
  }
  final biz = dto.bizPrdEndYmd;
  if (biz != null && !biz.contains('9999')) {
    return _parseYmd(biz);
  }
  return null;
}

DateTime? _parseYmd(String s) {
  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 8) return null;
  final year = int.tryParse(digits.substring(0, 4));
  final month = int.tryParse(digits.substring(4, 6));
  final day = int.tryParse(digits.substring(6, 8));
  if (year == null || month == null || day == null) return null;
  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}
