import '../../shared/entities/benefit.dart';
import 'rule_models.dart';

/// docs/05 section 5 "랭킹 스코어링" — score = w1*eligibilityConfidence + w2*normalizedAmount + w3*urgency + w4*popularity.
/// 가중치는 초기값으로 고정(관리자 튜닝은 MVP 범위 밖, docs/12 참고).
class RankingWeights {
  static const eligibility = 0.45;
  static const amount = 0.25;
  static const urgency = 0.15;
  static const popularity = 0.15;
}

double eligibilityConfidence(EligibilityStatus status) => switch (status) {
      EligibilityStatus.eligible => 1.0,
      EligibilityStatus.possiblyEligible => 0.5,
      EligibilityStatus.notEligible => 0.0,
    };

double normalizedAmount(Benefit benefit, int maxAmountAcrossAll) {
  final amount = benefit.representativeAmount;
  if (amount == null || maxAmountAcrossAll <= 0) return 0;
  return (amount / maxAmountAcrossAll).clamp(0, 1).toDouble();
}

double urgency(Benefit benefit) {
  final days = benefit.daysUntilDeadline;
  if (days == null) return 0.1; // 상시 모집은 낮은 긴급도
  if (days < 0) return 0;
  if (days <= 3) return 1.0;
  return (1 / (days + 1)).clamp(0, 1).toDouble();
}

double score({
  required EligibilityStatus status,
  required Benefit benefit,
  required int maxAmountAcrossAll,
}) {
  return RankingWeights.eligibility * eligibilityConfidence(status) +
      RankingWeights.amount * normalizedAmount(benefit, maxAmountAcrossAll) +
      RankingWeights.urgency * urgency(benefit) +
      RankingWeights.popularity * (benefit.popularityScore / 100);
}
