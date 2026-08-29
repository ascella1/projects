import 'package:flutter/material.dart';

import '../../game/line_slice_game.dart';
import '../../game/models/hud_snapshot.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.game});

  final LineSliceGame game;

  String _formatTime(double seconds) {
    final totalSeconds = seconds.floor();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<HudSnapshot>(
        valueListenable: game.hud,
        builder: (context, hud, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          hud.maxHp,
                          (i) => Icon(
                            Icons.favorite,
                            color: i < hud.hp ? Colors.redAccent : Colors.white24,
                            size: 20,
                          ),
                        ),
                        if (hud.shield > 0) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.shield, color: Colors.lightBlueAccent, size: 20),
                          Text(
                            ' x${hud.shield}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatTime(hud.elapsedSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Lv.${hud.level}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hud.xpToNext == 0
                              ? 0
                              : hud.xpCurrent / hud.xpToNext,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.amberAccent),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hud.combo > 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${hud.combo} COMBO',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
