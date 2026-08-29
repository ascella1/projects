import 'package:flutter/material.dart';

import '../../game/line_slice_game.dart';
import '../../game/models/upgrade.dart';

/// 레벨업 3택1 강화 선택 오버레이. 게임은 완전정지가 아니라 슬로우모션
/// 상태를 유지한 채로 표시된다 (스펙 3번/9번).
class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key, required this.game});

  final LineSliceGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<UpgradeDef>?>(
      valueListenable: game.pendingUpgradeChoices,
      builder: (context, choices, _) {
        if (choices == null) return const SizedBox.shrink();
        return Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LEVEL UP!',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...choices.map(
                (def) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: SizedBox(
                    width: 320,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF263238),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => game.selectUpgrade(def),
                      child: Column(
                        children: [
                          Text(
                            def.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            def.description,
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
