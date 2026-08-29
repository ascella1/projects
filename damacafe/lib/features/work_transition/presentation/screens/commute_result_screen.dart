import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/settlement_calculator.dart';
import '../providers/work_session_provider.dart';

/// 퇴근 정산 결과를 서프라이즈 방식으로 한 번에 공개하는 화면.
class CommuteResultScreen extends ConsumerStatefulWidget {
  const CommuteResultScreen({super.key});

  @override
  ConsumerState<CommuteResultScreen> createState() => _CommuteResultScreenState();
}

class _CommuteResultScreenState extends ConsumerState<CommuteResultScreen> {
  late final Future<SettlementResult> _settlementFuture;

  @override
  void initState() {
    super.initState();
    _settlementFuture = ref.read(workSessionProvider.notifier).clockOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.commuteResultTitle)),
      body: FutureBuilder<SettlementResult>(
        future: _settlementFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(l10n.ordersServedToday(result.ordersServed)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.settlementCoinsEarned(result.totalCoinsEarned),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.settlementConditionScore(result.conditionScore),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home),
                    label: Text(l10n.backHomeButton),
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
