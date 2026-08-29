import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../character/presentation/providers/character_provider.dart';

/// 씻기기: 터치 인터랙션 1종. 탭할 때마다 청결도가 조금씩 올라간다.
class WashWidget extends ConsumerWidget {
  const WashWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () {
        ref.read(characterProvider.notifier).washTap();
      },
      icon: const Icon(Icons.bubble_chart),
      label: Text(AppLocalizations.of(context)!.washButton),
    );
  }
}
