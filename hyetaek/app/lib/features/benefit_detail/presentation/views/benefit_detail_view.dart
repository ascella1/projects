import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/status_badge.dart';
import '../../../../shared/entities/benefit.dart';
import '../../../eligibility_engine/rule_models.dart';
import '../../../home_dashboard/presentation/providers/ranked_benefits_provider.dart';

/// docs/01 section 4.3 "혜택 상세" — 자격 판정 결과 + WHY 설명 + 신청 링크.
class BenefitDetailView extends ConsumerWidget {
  final String benefitId;
  const BenefitDetailView({super.key, required this.benefitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final benefits = ref.watch(benefitsProvider);
    final rankedList = ref.watch(rankedBenefitsProvider);

    final benefit = benefits.firstWhere((b) => b.id == benefitId);
    final matches = rankedList.where((r) => r.benefit.id == benefitId).toList();
    final result = matches.isNotEmpty ? matches.first.result : null;

    return Scaffold(
      appBar: AppBar(title: Text(benefit.category.label)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(benefit.category.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                if (result != null) StatusBadge(status: result.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(benefit.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(benefit.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('지원 금액', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(benefit.amountLabel, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('마감일', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          if (benefit.deadline == null)
                            Text('상시 모집', style: theme.textTheme.titleMedium)
                          else ...[
                            Text(_formatDate(benefit.deadline!), style: theme.textTheme.titleMedium),
                            Text(
                              _deadlineStatusLabel(benefit.daysUntilDeadline!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: (benefit.daysUntilDeadline! <= 7)
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (result != null) ...[
              Text('왜 이런 결과가 나왔을까요?', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '자격 여부는 룰 엔진이 결정론적으로 계산해요. AI는 이 결과를 설명만 할 뿐, 판정을 바꾸지 않아요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              ...result.trace.map((t) => _TraceRow(trace: t)),
              const SizedBox(height: 24),
            ],
            _InfoSection(title: '지원 대상', body: benefit.targetSummary),
            _InfoSection(title: '신청 방법', body: benefit.applicationProcess),
            _InfoSection(title: '필요 서류', body: benefit.requiredDocuments.join(', ')),
            _InfoSection(title: '출처', body: benefit.sourceName),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(benefit.officialUrl), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('공식 페이지에서 신청하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  static String _deadlineStatusLabel(int days) {
    if (days < 0) return '마감';
    if (days == 0) return '오늘 마감';
    return 'D-$days';
  }
}

class _TraceRow extends StatelessWidget {
  final ConditionTrace trace;
  const _TraceRow({required this.trace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = trace.passed == null
        ? theme.colorScheme.outline
        : trace.passed!
            ? const Color(0xFF16A34A)
            : theme.colorScheme.error;
    final icon = trace.passed == null
        ? Icons.help_outline_rounded
        : trace.passed!
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(trace.detail, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;
  const _InfoSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
