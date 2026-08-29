import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../game/line_slice_game.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/level_up_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final LineSliceGame _game;

  @override
  void initState() {
    super.initState();
    _game = LineSliceGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10151A),
      body: GameWidget(
        game: _game,
        initialActiveOverlays: const ['hud', 'levelUp', 'gameOver'],
        overlayBuilderMap: {
          'hud': (context, LineSliceGame game) => HudOverlay(game: game),
          'levelUp': (context, LineSliceGame game) => LevelUpOverlay(game: game),
          'gameOver': (context, LineSliceGame game) => GameOverOverlay(
                game: game,
                onExit: () => Navigator.of(context).pop(),
              ),
        },
      ),
    );
  }
}
