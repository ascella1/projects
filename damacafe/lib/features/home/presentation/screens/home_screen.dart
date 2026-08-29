import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gauge_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../character/domain/character_mood.dart';
import '../../../character/presentation/providers/character_provider.dart';
import '../../../work_transition/presentation/providers/work_session_provider.dart';
import '../widgets/character_avatar.dart';
import '../widgets/feed_widget.dart';
import '../widgets/play_minigame_widget.dart';
import '../widgets/sleep_toggle_widget.dart';
import '../widgets/wash_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(characterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: characterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(l10n.errorMessage('$error'))),
        data: (character) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CharacterAvatar(mood: character.mood),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('${character.coins}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GaugeBar(
                    label: l10n.gaugeSatiationLabel,
                    value: character.satiation,
                    color: AppColors.gaugeSatiation,
                    icon: Icons.restaurant,
                  ),
                  const SizedBox(height: 12),
                  GaugeBar(
                    label: l10n.gaugeCleanlinessLabel,
                    value: character.cleanliness,
                    color: AppColors.gaugeCleanliness,
                    icon: Icons.bubble_chart,
                  ),
                  const SizedBox(height: 12),
                  GaugeBar(
                    label: l10n.gaugeAffectionLabel,
                    value: character.affection,
                    color: AppColors.gaugeAffection,
                    icon: Icons.favorite,
                  ),
                  const SizedBox(height: 24),
                  const FeedWidget(),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: const [WashWidget(), PlayMinigameWidget(), SleepToggleWidget()],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(workSessionProvider.notifier).clockIn();
                      if (context.mounted) context.go('/cafe');
                    },
                    icon: const Icon(Icons.storefront),
                    label: Text(l10n.clockInButton),
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
