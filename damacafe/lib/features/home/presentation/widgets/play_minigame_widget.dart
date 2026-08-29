import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../character/presentation/providers/character_provider.dart';

enum _SwipeDirection { up, down, left, right }

/// 놀아주기: 터치/스와이프 미니게임 1개. 화살표 방향대로 3회 스와이프하면 클리어.
class PlayMinigameWidget extends ConsumerWidget {
  const PlayMinigameWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _openMinigame(context, ref),
      icon: const Icon(Icons.sports_esports),
      label: Text(AppLocalizations.of(context)!.playButton),
    );
  }

  Future<void> _openMinigame(BuildContext context, WidgetRef ref) async {
    final cleared = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SwipeMinigameDialog(),
    );
    if (cleared == true) {
      await ref.read(characterProvider.notifier).completePlayMinigame();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.playSuccessMessage)),
        );
      }
    }
  }
}

class _SwipeMinigameDialog extends StatefulWidget {
  const _SwipeMinigameDialog();

  @override
  State<_SwipeMinigameDialog> createState() => _SwipeMinigameDialogState();
}

class _SwipeMinigameDialogState extends State<_SwipeMinigameDialog> {
  static const int _targetRounds = 3;
  final Random _random = Random();
  late _SwipeDirection _current;
  int _cleared = 0;

  @override
  void initState() {
    super.initState();
    _current = _randomDirection();
  }

  _SwipeDirection _randomDirection() =>
      _SwipeDirection.values[_random.nextInt(_SwipeDirection.values.length)];

  IconData get _arrowIcon => switch (_current) {
    _SwipeDirection.up => Icons.arrow_upward,
    _SwipeDirection.down => Icons.arrow_downward,
    _SwipeDirection.left => Icons.arrow_back,
    _SwipeDirection.right => Icons.arrow_forward,
  };

  void _handleSwipe(_SwipeDirection direction) {
    if (direction != _current) return;
    setState(() {
      _cleared++;
      if (_cleared >= _targetRounds) {
        Navigator.of(context).pop(true);
      } else {
        _current = _randomDirection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.swipeMinigameTitle),
      content: GestureDetector(
        onPanEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond;
          if (velocity.distance < 100) return;
          final direction = velocity.dx.abs() > velocity.dy.abs()
              ? (velocity.dx > 0 ? _SwipeDirection.right : _SwipeDirection.left)
              : (velocity.dy > 0 ? _SwipeDirection.down : _SwipeDirection.up);
          _handleSwipe(direction);
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.gaugeTrack,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_arrowIcon, size: 64, color: AppColors.primary),
              const SizedBox(height: 8),
              Text('$_cleared / $_targetRounds'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context)!.stopPlayingButton),
        ),
      ],
    );
  }
}
