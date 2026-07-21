import '../../features/eligibility_engine/rule_models.dart';

enum BenefitCategory { youth, housing, employment, family, welfare, startup, education, health }

extension BenefitCategoryLabel on BenefitCategory {
  String get label => switch (this) {
        BenefitCategory.youth => '청년',
        BenefitCategory.housing => '주거',
        BenefitCategory.employment => '고용',
        BenefitCategory.family => '가족/출산',
        BenefitCategory.welfare => '복지',
        BenefitCategory.startup => '창업',
        BenefitCategory.education => '교육',
        BenefitCategory.health => '건강',
      };

  String get icon => switch (this) {
        BenefitCategory.youth => '🧑',
        BenefitCategory.housing => '🏠',
        BenefitCategory.employment => '💼',
        BenefitCategory.family => '👶',
        BenefitCategory.welfare => '🤝',
        BenefitCategory.startup => '🚀',
        BenefitCategory.education => '📚',
        BenefitCategory.health => '⚕️',
      };
}

enum AmountType { fixed, range, percentage, unknown }

/// docs/02 `benefit` 테이블 + docs/05 룰을 함께 들고 있는 클라이언트 표시 모델.
/// 서버가 없는 MVP이므로 `data/seed/benefits_seed.dart`가 이 테이블을 대신한다.
class Benefit {
  final String id;
  final String title;
  final String description;
  final BenefitCategory category;
  final List<String> regionCodes; // 빈 리스트면 전국
  final AmountType amountType;
  final int? amountMin;
  final int? amountMax;
  final String targetSummary;
  final String applicationProcess;
  final List<String> requiredDocuments;
  final DateTime? deadline;
  final String officialUrl;
  final String sourceName;
  final int popularityScore; // 0~100
  final EligibilityRule rule;

  const Benefit({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.regionCodes,
    required this.amountType,
    required this.targetSummary,
    required this.applicationProcess,
    required this.requiredDocuments,
    required this.officialUrl,
    required this.sourceName,
    required this.popularityScore,
    required this.rule,
    this.amountMin,
    this.amountMax,
    this.deadline,
  });

  bool appliesToRegion(String? regionCode) {
    if (regionCodes.isEmpty) return true;
    if (regionCode == null) return true;
    return regionCodes.contains(regionCode);
  }

  int? get representativeAmount {
    if (amountMax != null) return amountMax;
    if (amountMin != null) return amountMin;
    return null;
  }

  String get amountLabel {
    switch (amountType) {
      case AmountType.fixed:
        return amountMax != null ? _formatWon(amountMax!) : '금액 미정';
      case AmountType.range:
        if (amountMin != null && amountMax != null) {
          return '${_formatWon(amountMin!)} ~ ${_formatWon(amountMax!)}';
        }
        return amountMax != null ? '최대 ${_formatWon(amountMax!)}' : '금액 미정';
      case AmountType.percentage:
        return '금리/비율 우대';
      case AmountType.unknown:
        return '금액 미정';
    }
  }

  static String _formatWon(int won) {
    if (won >= 100000000) {
      final eok = won / 100000000;
      return '${eok % 1 == 0 ? eok.toStringAsFixed(0) : eok.toStringAsFixed(1)}억원';
    }
    if (won >= 10000) {
      final man = won / 10000;
      return '${man % 1 == 0 ? man.toStringAsFixed(0) : man.toStringAsFixed(1)}만원';
    }
    return '$won원';
  }

  int? get daysUntilDeadline {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }
}
