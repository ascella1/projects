import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../character/domain/ingredient.dart';
import '../../../character/presentation/providers/character_provider.dart';

/// 먹이주기: 재료 3종을 보여주고, 선호도에 따라 다른 반응 문구를 보여준다.
class FeedWidget extends ConsumerWidget {
  const FeedWidget({super.key});

  String _reactionFor(AppLocalizations l10n, IngredientPreference preference) =>
      switch (preference) {
        IngredientPreference.liked => l10n.feedReactionLiked,
        IngredientPreference.neutral => l10n.feedReactionNeutral,
        IngredientPreference.disliked => l10n.feedReactionDisliked,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ingredient in kIngredients)
          ActionChip(
            avatar: const Icon(Icons.restaurant, size: 18, color: AppColors.primary),
            label: Text(ingredient.name),
            onPressed: () async {
              await ref.read(characterProvider.notifier).feed(ingredient.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_reactionFor(l10n, ingredient.preference))),
                );
              }
            },
          ),
      ],
    );
  }
}
