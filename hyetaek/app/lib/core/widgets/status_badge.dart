import 'package:flutter/material.dart';

import '../../features/eligibility_engine/rule_models.dart';
import '../theme/status_colors.dart';

class StatusBadge extends StatelessWidget {
  final EligibilityStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = StatusColors.background(status, isDark);
    final fg = StatusColors.foreground(status, isDark);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusColors.icon(status), size: compact ? 12 : 14, color: fg),
          const SizedBox(width: 4),
          Text(
            StatusColors.label(status),
            style: TextStyle(color: fg, fontSize: compact ? 11 : 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
