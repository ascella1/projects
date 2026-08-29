import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/npc_order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.isMastered,
    required this.onCook,
  });

  final NpcOrder order;
  final bool isMastered;
  final VoidCallback onCook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              l10n.npcOrderLabel(order.npcName),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(order.recipe.name, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            if (!isMastered)
              Text(
                l10n.newRecipeHint,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onCook,
              icon: const Icon(Icons.restaurant_menu),
              label: Text(isMastered ? l10n.cookNowButton : l10n.cookWithMinigameButton),
            ),
          ],
        ),
      ),
    );
  }
}
