import 'package:flutter/material.dart';

import '../../features/home_dashboard/presentation/providers/ranked_benefits_provider.dart';
import '../../shared/entities/benefit.dart';
import 'status_badge.dart';

class BenefitCard extends StatelessWidget {
  final RankedBenefit ranked;
  final VoidCallback onTap;
  final double width;

  const BenefitCard({super.key, required this.ranked, required this.onTap, this.width = 240});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final benefit = ranked.benefit;
    final days = benefit.daysUntilDeadline;
    final isUrgent = days != null && days >= 0 && days <= 7;
    final isAlwaysOpen = benefit.deadline == null;

    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(benefit.category.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        benefit.category.label,
                        style: theme.textTheme.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'D-$days',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.error),
                        ),
                      )
                    else if (isAlwaysOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '상시',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.colorScheme.outline),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  benefit.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  benefit.amountLabel,
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: ranked.result.status, compact: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
