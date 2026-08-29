import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../character/domain/character_mood.dart';

/// 실제 아트가 들어오기 전까지 도형+색상으로 캐릭터 기분을 표현하는 placeholder.
class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar({super.key, required this.mood});

  final CharacterMood mood;

  Color get _color => switch (mood) {
    CharacterMood.happy => AppColors.secondary,
    CharacterMood.moping => AppColors.primary,
    CharacterMood.sulking => AppColors.accent,
    CharacterMood.longing => AppColors.textSecondary,
  };

  String _reaction(AppLocalizations l10n) => switch (mood) {
    CharacterMood.happy => l10n.moodHappyReaction,
    CharacterMood.moping => l10n.moodMopingReaction,
    CharacterMood.sulking => l10n.moodSulkingReaction,
    CharacterMood.longing => l10n.moodLongingReaction,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 140,
          height: 140,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.pets, size: 56, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          _reaction(l10n),
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
