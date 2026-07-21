import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/benefit_card.dart';
import '../../../../core/widgets/benefit_list_tile.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../benefit_detail/presentation/views/benefit_detail_view.dart';
import '../../../eligibility_engine/rule_models.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../providers/ranked_benefits_provider.dart';

/// docs/01 section 4.1 "홈 / 대시보드" 구현.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final ranked = ref.watch(rankedBenefitsProvider);
    final monthly = ref.watch(estimatedMonthlyBenefitProvider);
    final annual = ref.watch(estimatedAnnualBenefitProvider);
    final syncState = ref.watch(benefitsSyncProvider);
    final theme = Theme.of(context);

    final urgent = ranked.where((r) {
      final d = r.benefit.daysUntilDeadline;
      return d != null && d >= 0 && d <= 7;
    }).toList();

    final eligibleCount = ranked.where((r) => r.result.status == EligibilityStatus.eligible).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('혜택'),
        actions: [
          IconButton(
            icon: const CircleAvatar(radius: 16, child: Icon(Icons.person_rounded, size: 18)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileView())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(benefitsSyncProvider.notifier).sync(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                profile.isOnboarded
                    ? '지금 받을 수 있는 혜택이 $eligibleCount개 있어요'
                    : '프로필을 등록하면 맞춤 혜택을 보여드려요',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SyncStatusRow(syncState: syncState),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _SummaryCard(label: '예상 월 혜택', amount: monthly)),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(label: '예상 연 혜택', amount: annual)),
                ],
              ),
            ),
            if (urgent.isNotEmpty) ...[
              _SectionHeader(title: '마감임박'),
              SizedBox(
                height: 176,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: urgent.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => BenefitCard(
                    ranked: urgent[i],
                    onTap: () => _openDetail(context, urgent[i].benefit.id),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _SectionHeader(title: profile.isOnboarded ? '추천 혜택' : '전체 혜택'),
            if (ranked.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text('조건에 맞는 혜택을 찾지 못했어요. 프로필을 조금 더 채워보세요.', style: theme.textTheme.bodyMedium),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final r in ranked) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BenefitListTile(ranked: r, onTap: () => _openDetail(context, r.benefit.id)),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String benefitId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BenefitDetailView(benefitId: benefitId)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;

  const _SummaryCard({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              _formatWon(amount),
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatWon(int won) {
    if (won <= 0) return '0원';
    if (won >= 100000000) return '${(won / 100000000).toStringAsFixed(1)}억원';
    if (won >= 10000) return '${(won / 10000).toStringAsFixed(0)}만원';
    return '$won원';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// 정부 오픈API 소스별 동기화 상태 — "온통청년: 5분 전 업데이트 · 복지로: 키 미설정"처럼 한 줄씩
/// 보여준다 (docs/04 5번 표 원칙: 소스 하나가 실패해도 나머지/기본 데이터는 그대로 표시).
class _SyncStatusRow extends StatelessWidget {
  final BenefitsSyncState syncState;
  const _SyncStatusRow({required this.syncState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outline;

    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: syncState.sources.map((s) {
        final (icon, label) = _describe(s);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text('${s.label}: $label', style: theme.textTheme.labelMedium?.copyWith(color: color)),
          ],
        );
      }).toList(),
    );
  }

  static (IconData, String) _describe(SourceSyncStatus s) {
    if (s.isSyncing) return (Icons.sync_rounded, '동기화 중…');
    if (s.keyMissing) return (Icons.vpn_key_off_rounded, '키 미설정');
    if (s.error != null) {
      return (
        Icons.cloud_off_rounded,
        s.lastSyncedAt != null ? '동기화 실패 · ${_relativeTime(s.lastSyncedAt!)} 데이터' : '동기화 실패',
      );
    }
    if (s.lastSyncedAt != null) return (Icons.cloud_done_rounded, '${_relativeTime(s.lastSyncedAt!)} 업데이트');
    return (Icons.cloud_outlined, '연동 대기');
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
