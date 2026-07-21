import 'package:flutter/material.dart';

import '../../features/home_dashboard/presentation/providers/ranked_benefits_provider.dart';
import '../../shared/entities/benefit.dart';
import 'status_badge.dart';

class BenefitListTile extends StatelessWidget {
  final RankedBenefit ranked;
  final VoidCallback onTap;

  const BenefitListTile({super.key, required this.ranked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final benefit = ranked.benefit;
    final days = benefit.daysUntilDeadline;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(benefit.category.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(benefit.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(benefit.amountLabel, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: ranked.result.status, compact: true),
                        if (days != null && days >= 0) ...[
                          const SizedBox(width: 8),
                          Text('D-$days', style: theme.textTheme.labelLarge),
                        ] else if (benefit.deadline == null) ...[
                          const SizedBox(width: 8),
                          Text('상시', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
