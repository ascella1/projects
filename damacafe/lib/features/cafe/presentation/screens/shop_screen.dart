import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../character/presentation/providers/character_provider.dart';
import '../../domain/entities/shop_item.dart';

/// 음식/장난감/침대 아이템을 구매하는 상점. 카테고리를 늘리면 자동으로 목록에 반영된다.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  String _categoryLabel(AppLocalizations l10n, ShopItemCategory category) => switch (category) {
    ShopItemCategory.food => l10n.shopCategoryFood,
    ShopItemCategory.toy => l10n.shopCategoryToy,
    ShopItemCategory.bed => l10n.shopCategoryBed,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(characterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopTitle)),
      body: characterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorMessage('$error'))),
        data: (character) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kShopCatalog.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = kShopCatalog[index];
              final owned = character.ownedItemIds.contains(item.id);
              return Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${_categoryLabel(l10n, item.category)} · ${l10n.careBonusLabel(item.careBonus)}',
                  ),
                  trailing: owned
                      ? Chip(label: Text(l10n.ownedLabel))
                      : ElevatedButton(
                          onPressed: character.coins >= item.price
                              ? () async {
                                  final success = await ref
                                      .read(characterProvider.notifier)
                                      .purchaseItem(item);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? l10n.purchaseSuccessMessage(item.name)
                                              : l10n.purchaseFailMessage,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: Text(l10n.priceCoinsLabel(item.price)),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
