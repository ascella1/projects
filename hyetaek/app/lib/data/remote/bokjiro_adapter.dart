import '../../features/eligibility_engine/rule_models.dart';
import '../../shared/entities/benefit.dart';
import 'bokjiro_dto.dart';
import 'category_classifier.dart';

/// `BokjiroDto`(방어적 원본 필드) → 앱의 `Benefit`/`EligibilityRule` 모델로 정규화.
/// 이 API는 나이/지역 필터나 마감일 필드를 제공하지 않아 각각 "조건 없음(항상 eligible)",
/// "전국", "상시"로 처리한다 — 있는 데이터만 정직하게 보여주는 편이 없는 조건을 지어내는 것보다 낫다.
Benefit? bokjiroToBenefit(BokjiroDto dto) {
  final title = dto.servNm;
  final id0 = dto.servId;
  if (title == null || id0 == null) return null; // 최소 식별자가 없으면 안전하게 건너뜀

  final id = 'bokjiro-$id0';
  final targetParts = <String>[
    if (dto.lifeNmArray != null) dto.lifeNmArray!,
    if (dto.trgterIndvdlNmArray != null) dto.trgterIndvdlNmArray!,
  ];

  return Benefit(
    id: id,
    title: title,
    description: dto.servDgst ?? '',
    category: classifyCategory([dto.lifeNmArray, dto.trgterIndvdlNmArray].whereType<String>().join(' ')),
    regionCodes: const [], // 중앙부처 서비스라 전국 공통
    amountType: AmountType.unknown,
    targetSummary: targetParts.isEmpty ? '자세한 대상 조건은 공식 페이지에서 확인하세요' : targetParts.join(' · '),
    applicationProcess: dto.aplyMtdNm ?? '복지로 공식 페이지에서 신청 절차를 확인하세요',
    requiredDocuments: const ['공식 페이지에서 확인'],
    officialUrl: dto.servDtlLink ?? 'https://www.bokjiro.go.kr',
    sourceName: dto.jurMnofNm ?? '복지로',
    popularityScore: 50,
    deadline: null, // 이 API는 마감일 필드를 제공하지 않음 (상시 지원 성격의 복지제도가 대부분)
    rule: EligibilityRule(
      benefitId: id,
      rootGroup: const RuleGroup(operator: GroupOperator.and, conditions: []),
    ),
  );
}
