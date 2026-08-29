import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../domain/entities/recipe.dart';
import '../presentation/providers/cafe_provider.dart';
import 'cooking_game.dart';

/// 새로운 레시피를 처음 만들 때 거쳐야 하는 요리 미니게임 화면.
/// 클리어하면 레시피가 숙련 처리되어 이후엔 이 화면을 다시 거치지 않는다.
class CookingGameScreen extends ConsumerStatefulWidget {
  const CookingGameScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<CookingGameScreen> createState() => _CookingGameScreenState();
}

class _CookingGameScreenState extends ConsumerState<CookingGameScreen> {
  late final CookingGame _game;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _game = CookingGame(onSuccess: _handleSuccess);
  }

  Future<void> _handleSuccess() async {
    if (_handled) return;
    _handled = true;
    await ref.read(cafeProvider.notifier).completeCookingMinigame(widget.recipe.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.cookingScreenTitle(widget.recipe.name))),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(l10n.cookingInstructions)),
          Expanded(child: GameWidget(game: _game)),
        ],
      ),
    );
  }
}
