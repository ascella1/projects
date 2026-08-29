import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// 재우기: 낮/밤 토글. 실시간 연동은 이후 단계이므로 지금은 화면 표시만 바뀐다.
class SleepToggleWidget extends StatefulWidget {
  const SleepToggleWidget({super.key});

  @override
  State<SleepToggleWidget> createState() => _SleepToggleWidgetState();
}

class _SleepToggleWidgetState extends State<SleepToggleWidget> {
  bool _isNight = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _isNight ? Icons.nightlight_round : Icons.wb_sunny,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          _isNight
              ? AppLocalizations.of(context)!.sleepNightLabel
              : AppLocalizations.of(context)!.sleepDayLabel,
        ),
        Switch(
          value: _isNight,
          onChanged: (value) => setState(() => _isNight = value),
        ),
      ],
    );
  }
}
