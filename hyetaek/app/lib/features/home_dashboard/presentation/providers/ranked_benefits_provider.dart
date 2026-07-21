import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/remote/bokjiro_adapter.dart';
import '../../../../data/remote/bokjiro_dto.dart';
import '../../../../data/remote/youth_policy_adapter.dart';
import '../../../../data/remote/youth_policy_dto.dart';
import '../../../../data/repository/benefit_sync_repository.dart';
import '../../../../data/seed/benefits_seed.dart';
import '../../../../shared/entities/benefit.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../eligibility_engine/evaluator.dart';
import '../../../eligibility_engine/rule_models.dart';
import '../../../eligibility_engine/scoring.dart' as scoring;

/// 서버 소스 레지스트리(`server/sources/index.js`)와 1:1 대응하는 클라이언트 쪽 소스 목록.
/// 새 소스를 추가할 때 서버에 등록하고 여기에 한 줄 추가 + 어댑터 함수만 연결하면 된다.
typedef _SourceConfig = ({String id, String label, Benefit? Function(Map<String, dynamic>) toBenefit});

Benefit? _youthToBenefit(Map<String, dynamic> json) => youthPolicyToBenefit(YouthPolicyDto.fromJson(json));
Benefit? _bokjiroToBenefit(Map<String, dynamic> json) => bokjiroToBenefit(BokjiroDto.fromJson(json));

const _sourceConfigs = <_SourceConfig>[
  (id: 'youth-policies', label: '온통청년(청년)', toBenefit: _youthToBenefit),
  (id: 'bokjiro', label: '복지로(전 생애주기)', toBenefit: _bokjiroToBenefit),
];

class SourceSyncStatus {
  final String id;
  final String label;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final bool keyMissing;
  final String? error;

  const SourceSyncStatus({
    required this.id,
    required this.label,
    this.lastSyncedAt,
    this.isSyncing = false,
    this.keyMissing = false,
    this.error,
  });

  SourceSyncStatus copyWith({
    DateTime? lastSyncedAt,
    bool? isSyncing,
    bool? keyMissing,
    String? error,
    bool clearError = false,
  }) {
    return SourceSyncStatus(
      id: id,
      label: label,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSyncing: isSyncing ?? this.isSyncing,
      keyMissing: keyMissing ?? this.keyMissing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BenefitsSyncState {
  final List<Benefit> items;
  final List<SourceSyncStatus> sources;

  const BenefitsSyncState({required this.items, required this.sources});
}

/// 정부 오픈API(소스 여러 개) 동기화 상태를 들고 있는 notifier.
/// seed는 항상 그대로 유지하고, 각 소스의 결과는 독립적으로 추가/갱신한다 — 한 소스가 실패해도
/// (키 미설정 포함) 다른 소스/seed에는 영향을 주지 않는다 (docs/00 원칙 4, docs/04 5번 표).
class BenefitsSyncNotifier extends Notifier<BenefitsSyncState> {
  final _repository = const BenefitSyncRepository();
  final Map<String, List<Benefit>> _sourceBenefits = {};

  @override
  BenefitsSyncState build() {
    final initialSources = _sourceConfigs.map((c) => SourceSyncStatus(id: c.id, label: c.label)).toList();
    _loadCacheThenSync();
    return BenefitsSyncState(items: seedBenefits, sources: initialSources);
  }

  Future<void> _loadCacheThenSync() async {
    for (final config in _sourceConfigs) {
      final cache = await _repository.loadCache(config.id);
      if (cache.items.isNotEmpty) {
        _sourceBenefits[config.id] = _mapBenefits(cache.items, config.toBenefit);
        _updateSourceStatus(config.id, lastSyncedAt: cache.syncedAt);
      }
    }
    await sync();
  }

  /// 등록된 모든 소스를 동시에 동기화. 홈 화면 pull-to-refresh에서도 호출됨.
  Future<void> sync() async {
    await Future.wait(_sourceConfigs.map(_syncSource));
  }

  Future<void> _syncSource(_SourceConfig config) async {
    _updateSourceStatus(config.id, isSyncing: true, clearError: true, keyMissing: false);
    try {
      final raw = await _repository.fetchSourceItems(config.id);
      final syncedAt = DateTime.now();
      await _repository.saveCache(config.id, raw, syncedAt);
      _sourceBenefits[config.id] = _mapBenefits(raw, config.toBenefit);
      _updateSourceStatus(config.id, isSyncing: false, lastSyncedAt: syncedAt, clearError: true, keyMissing: false);
    } on SourceKeyMissingException {
      _updateSourceStatus(config.id, isSyncing: false, keyMissing: true);
    } catch (e) {
      _updateSourceStatus(config.id, isSyncing: false, error: e.toString());
    }
  }

  List<Benefit> _mapBenefits(List<Map<String, dynamic>> raw, Benefit? Function(Map<String, dynamic>) toBenefit) {
    final byId = <String, Benefit>{};
    for (final json in raw) {
      final benefit = toBenefit(json);
      if (benefit != null) byId[benefit.id] = benefit; // 같은 id면 최신 데이터로 교체(dedupe)
    }
    return byId.values.toList();
  }

  void _updateSourceStatus(
    String sourceId, {
    DateTime? lastSyncedAt,
    bool? isSyncing,
    bool? keyMissing,
    String? error,
    bool clearError = false,
  }) {
    final updatedSources = state.sources
        .map((s) => s.id == sourceId
            ? s.copyWith(
                lastSyncedAt: lastSyncedAt,
                isSyncing: isSyncing,
                keyMissing: keyMissing,
                error: error,
                clearError: clearError,
              )
            : s)
        .toList();

    final mergedItems = <Benefit>[
      ...seedBenefits,
      for (final config in _sourceConfigs) ...?_sourceBenefits[config.id],
    ];

    state = BenefitsSyncState(items: mergedItems, sources: updatedSources);
  }
}

final benefitsSyncProvider = NotifierProvider<BenefitsSyncNotifier, BenefitsSyncState>(BenefitsSyncNotifier.new);

/// 서버가 없는 MVP의 "혜택 목록" 데이터소스. seed + 정부 오픈API 소스들의 동기화 결과를 병합해 제공한다.
/// 시그니처(`Provider<List<Benefit>>`)는 그대로라 아래 rankedBenefitsProvider 등 소비 코드는 무수정.
final benefitsProvider = Provider<List<Benefit>>((ref) => ref.watch(benefitsSyncProvider).items);

class RankedBenefit {
  final Benefit benefit;
  final EligibilityResult result;
  final double score;

  const RankedBenefit({required this.benefit, required this.result, required this.score});
}

/// 파생 계산값: 프로필 + 룰 조합 → 자격 판정 + 랭킹 점수 (docs/03 section 3, docs/05 evaluate()).
/// `profileProvider`를 watch하므로 프로필이 바뀌면 즉시 재계산되어 화면이 자동 리빌드된다.
final rankedBenefitsProvider = Provider<List<RankedBenefit>>((ref) {
  final profile = ref.watch(profileProvider);
  final benefits = ref.watch(benefitsProvider);
  final fields = profile.toFieldMap();

  final maxAmount = benefits
      .map((b) => b.representativeAmount ?? 0)
      .fold<int>(0, (max, v) => v > max ? v : max);

  final ranked = benefits
      .where((b) => b.appliesToRegion(profile.regionCode))
      .map((b) {
        final result = evaluate(b.rule, fields);
        final s = scoring.score(status: result.status, benefit: b, maxAmountAcrossAll: maxAmount);
        return RankedBenefit(benefit: b, result: result, score: s);
      })
      .where((r) => r.result.status != EligibilityStatus.notEligible)
      .toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  return ranked;
});

/// 예상 월간 혜택 합계 — ELIGIBLE 상태인 혜택의 대표 금액을 12개월로 환산해 합산 (단순 근사치, 데모용).
final estimatedMonthlyBenefitProvider = Provider<int>((ref) {
  final ranked = ref.watch(rankedBenefitsProvider);
  final annual = ranked
      .where((r) => r.result.status == EligibilityStatus.eligible)
      .fold<int>(0, (sum, r) => sum + (r.benefit.representativeAmount ?? 0));
  return annual ~/ 12;
});

final estimatedAnnualBenefitProvider = Provider<int>((ref) {
  final ranked = ref.watch(rankedBenefitsProvider);
  return ranked
      .where((r) => r.result.status == EligibilityStatus.eligible)
      .fold<int>(0, (sum, r) => sum + (r.benefit.representativeAmount ?? 0));
});
