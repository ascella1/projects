import 'package:flutter/material.dart';

import '../constants/game_balance.dart';
import '../theme/app_colors.dart';

/// 배고픔/청결도/애정도 등 0~100 게이지를 표시하는 공용 위젯.
class GaugeBar extends StatelessWidget {
  const GaugeBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(GameBalance.minGauge, GameBalance.maxGauge);
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: clamped / GameBalance.maxGauge,
                  minHeight: 10,
                  backgroundColor: AppColors.gaugeTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
