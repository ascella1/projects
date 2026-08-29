import 'package:flutter/material.dart';

import '../../game/line_slice_game.dart';
import '../../game/models/run_summary.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game, required this.onExit});

  final LineSliceGame game;
  final VoidCallback onExit;

  String _formatTime(double seconds) {
    final totalSeconds = seconds.floor();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RunSummary?>(
      valueListenable: game.gameOverSummary,
      builder: (context, summary, _) {
        if (summary == null) return const SizedBox.shrink();
        return Container(
          color: Colors.black87,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _StatRow(label: '생존 시간', value: _formatTime(summary.survivedSeconds)),
              _StatRow(label: '도달 레벨', value: '${summary.levelReached}'),
              _StatRow(label: '총 절단 수', value: '${summary.totalCuts}'),
              _StatRow(label: '크리티컬', value: '${summary.criticalCuts}'),
              _StatRow(label: '최대 콤보', value: '${summary.maxCombo}'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => game.restart(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Text('다시하기', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onExit,
                child: const Text('홈으로', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
