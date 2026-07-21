import '../../shared/entities/benefit.dart';

/// 정부 API 응답의 자유 텍스트(대분류/중분류/키워드 등)를 앱의 `BenefitCategory`로 매핑.
/// 온통청년/복지로 등 여러 소스 어댑터가 공유하는 키워드 매칭 로직 (docs/04 원칙: 소스가 늘어도 공통 로직은 한 곳에).
BenefitCategory classifyCategory(String text, {BenefitCategory fallback = BenefitCategory.welfare}) {
  if (text.contains('주거') || text.contains('주택')) return BenefitCategory.housing;
  if (text.contains('일자리') || text.contains('고용') || text.contains('취업')) return BenefitCategory.employment;
  if (text.contains('창업')) return BenefitCategory.startup;
  if (text.contains('교육') || text.contains('학자금')) return BenefitCategory.education;
  if (text.contains('건강') || text.contains('의료')) return BenefitCategory.health;
  if (text.contains('결혼') || text.contains('출산') || text.contains('가족') || text.contains('육아')) {
    return BenefitCategory.family;
  }
  if (text.contains('청년')) return BenefitCategory.youth;
  if (text.contains('복지')) return BenefitCategory.welfare;
  return fallback;
}
