import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../work_transition/presentation/providers/work_session_provider.dart';
import '../../domain/entities/npc_order.dart';
import '../../minigame/cooking_game_screen.dart';
import '../providers/cafe_provider.dart';
import '../widgets/order_card.dart';

class CafeScreen extends ConsumerWidget {
  const CafeScreen({super.key});

  Future<void> _handleCook(
    BuildContext context,
    WidgetRef ref,
    NpcOrder order,
    bool isMastered,
  ) async {
    if (isMastered) {
      final outcome = await ref.read(cafeProvider.notifier).serveMasteredOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.serveCompleteMessage('⭐' * outcome.stars),
            ),
          ),
        );
      }
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CookingGameScreen(recipe: order.recipe)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cafeAsync = ref.watch(cafeProvider);
    final session = ref.watch(workSessionProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cafeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: () => context.push('/cafe/shop'),
          ),
        ],
      ),
      body: cafeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorMessage('$error'))),
        data: (state) {
          final order = state.currentOrder;
          final isMastered = state.masteredRecipeIds.contains(order.recipe.id);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    l10n.ordersServedToday(session.ordersServed),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  OrderCard(
                    order: order,
                    isMastered: isMastered,
                    onCook: () => _handleCook(context, ref, order, isMastered),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/cafe/commute-result'),
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.clockOutButton),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
