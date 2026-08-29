import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../data/run_repository.dart';
import 'components/bamboo_forest_background_component.dart';
import 'components/combo_popup_component.dart';
import 'components/obstacle_component.dart';
import 'components/player_component.dart';
import 'components/screen_flash_component.dart';
import 'components/shockwave_ring_component.dart';
import 'components/spark_burst_component.dart';
import 'components/slice_particle_component.dart';
import 'components/swipe_trail_component.dart';
import 'components/xp_gem_component.dart';
import 'managers/audio_manager.dart';
import 'managers/difficulty_manager.dart';
import 'models/hud_snapshot.dart';
import 'models/player_stats.dart';
import 'models/obstacle_material.dart';
import 'models/run_summary.dart';
import 'models/upgrade.dart';
import 'utils/geometry.dart';

class LineSliceGame extends FlameGame with PanDetector, HasTimeScale {
  LineSliceGame({RunRepository? runRepository})
      : runRepository = runRepository ?? RunRepository();

  final RunRepository runRepository;
  final AudioManager audio = AudioManager();
  final PlayerStats playerStats = PlayerStats();
  final Random _random = Random();

  final ValueNotifier<HudSnapshot> hud = ValueNotifier(HudSnapshot.initial);
  final ValueNotifier<List<UpgradeDef>?> pendingUpgradeChoices =
      ValueNotifier(null);
  final ValueNotifier<RunSummary?> gameOverSummary = ValueNotifier(null);

  static const int _maxHp = 3;

  late PlayerComponent _player;
  late BambooForestBackgroundComponent _road;
  late ComboPopupComponent _comboPopup;
  late ScreenFlashComponent _screenFlash;

  double _shakeTime = 0;
  double _shakeDuration = 0;
  double _shakeMagnitude = 0;

  double _elapsedSeconds = 0;
  double _spawnTimer = 0;
  int _hp = _maxHp;
  int _shield = 0;
  int _level = 1;
  int _xpCurrent = 0;
  int _xpToNext = 85; // 50 + level(1)*35
  int _combo = 0;
  double _comboTimer = 0;
  double _slowmoTimer = 0;
  int _totalCuts = 0;
  int _criticalCuts = 0;
  int _maxCombo = 0;

  bool _isLevelUpActive = false;
  bool _isGameOver = false;

  SwipeTrailComponent? _activeTrail;
  Vector2? _lastDragPoint;
  final Set<ObstacleComponent> _cutThisSwipe = {};

  @override
  Color backgroundColor() => const Color(0xFF10151A);

  @override
  Future<void> onLoad() async {
    _road = BambooForestBackgroundComponent(
      scrollSpeed: DifficultyManager.fallSpeedFor(0),
      random: _random,
    );
    await add(_road);
    _player = PlayerComponent()
      ..position = Vector2(size.x / 2, size.y * 0.85);
    await add(_player);
    _comboPopup = ComboPopupComponent()..position = Vector2(size.x / 2, size.y * 0.36);
    await add(_comboPopup);
    _screenFlash = ScreenFlashComponent();
    await add(_screenFlash);
    _resetRunState();
  }

  void _resetRunState() {
    _elapsedSeconds = 0;
    _spawnTimer = DifficultyManager.spawnIntervalFor(0);
    _hp = _maxHp;
    _shield = 0;
    _level = 1;
    _xpCurrent = 0;
    _xpToNext = 85;
    _combo = 0;
    _comboTimer = 0;
    _slowmoTimer = 0;
    _totalCuts = 0;
    _criticalCuts = 0;
    _maxCombo = 0;
    _isLevelUpActive = false;
    _isGameOver = false;
    pendingUpgradeChoices.value = null;
    gameOverSummary.value = null;
    timeScale = 1.0;
    _pushHud();
  }

  /// 게임 오버 화면에서 "다시하기"를 눌렀을 때 호출.
  void restart() {
    playerStats.upgradeLevels.updateAll((key, value) => 0);
    children.whereType<ObstacleComponent>().toList().forEach(remove);
    children.whereType<XpGemComponent>().toList().forEach(remove);
    _resetRunState();
  }

  double get _missLineY => size.y * 0.82;

  void _triggerShake(double duration, double magnitude) {
    _shakeDuration = duration;
    _shakeTime = 0;
    _shakeMagnitude = magnitude;
  }

  @override
  void render(Canvas canvas) {
    if (_shakeTime < _shakeDuration) {
      final progress = 1 - (_shakeTime / _shakeDuration);
      final dx = (_random.nextDouble() * 2 - 1) * _shakeMagnitude * progress;
      final dy = (_random.nextDouble() * 2 - 1) * _shakeMagnitude * progress;
      canvas.save();
      canvas.translate(dx, dy);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTime < _shakeDuration) {
      _shakeTime += dt;
    }
    if (_isGameOver) return;

    if (_isLevelUpActive) {
      timeScale = PlayerStats.slowMotionTimeScale;
      return;
    }

    timeScale = _slowmoTimer > 0 ? PlayerStats.slowMotionTimeScale : 1.0;
    if (_slowmoTimer > 0) {
      _slowmoTimer -= dt;
    }

    _elapsedSeconds += dt;
    _road.scrollSpeed = DifficultyManager.fallSpeedFor(_elapsedSeconds);

    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnObstacle();
      _spawnTimer = DifficultyManager.spawnIntervalFor(_elapsedSeconds);
    }

    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        _combo = 0;
      }
    }

    _checkMisses();
    _pushHud();
  }

  void _spawnObstacle() {
    final unlocked = ObstacleMaterial.unlockedAt(_elapsedSeconds);
    final material = unlocked[_random.nextInt(unlocked.length)];
    final fallSpeed = DifficultyManager.fallSpeedFor(_elapsedSeconds);
    final margin = 40.0;
    final targetX = margin + _random.nextDouble() * (size.x - margin * 2);
    add(
      ObstacleComponent(
        material: material,
        spawnX: size.x / 2,
        targetX: targetX,
        spawnY: _road.horizonY,
        fallSpeed: fallSpeed,
        growthStartY: _road.horizonY,
        growthEndY: _missLineY,
        random: _random,
      ),
    );
  }

  void _checkMisses() {
    final obstacles = children.whereType<ObstacleComponent>().toList();
    for (final obstacle in obstacles) {
      if (_isGameOver) break;
      if (obstacle.position.y - obstacle.size.y / 2 > _missLineY) {
        _handleMiss(obstacle);
      }
    }
  }

  void _handleMiss(ObstacleComponent obstacle) {
    obstacle.removeFromParent();
    audio.playMiss();
    if (_shield > 0) {
      _shield--;
    } else {
      _hp--;
      if (_hp <= 0) {
        _hp = 0;
        _triggerGameOver();
      }
    }
    _combo = 0;
    _comboTimer = 0;
  }

  // --- 스와이프 절단 판정 (선분 vs 히트박스 교차) + 탭 파괴 ---

  @override
  void onPanDown(DragDownInfo info) {
    if (_isLevelUpActive || _isGameOver) return;
    // 스와이프로 이어지지 않는 단순 터치만으로도 장애물을 즉시 파괴한다.
    final point = info.eventPosition.widget;
    final obstacles = children.whereType<ObstacleComponent>();
    for (final obstacle in obstacles) {
      if (obstacle.hitRect.contains(Offset(point.x, point.y))) {
        _performCut(obstacle, cutDirection: Vector2(0, -1));
        break;
      }
    }
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (_isLevelUpActive || _isGameOver) return;
    _cutThisSwipe.clear();
    _lastDragPoint = info.eventPosition.widget.clone();
    _activeTrail = SwipeTrailComponent()..addPoint(_lastDragPoint!);
    add(_activeTrail!);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_isLevelUpActive || _isGameOver || _lastDragPoint == null) return;
    final newPoint = info.eventPosition.widget;
    _activeTrail?.addPoint(newPoint);

    final canSliceMore =
        playerStats.hasPenetratingCut || _cutThisSwipe.length < playerStats.sliceCount;
    if (canSliceMore) {
      final obstacles = children.whereType<ObstacleComponent>();
      for (final obstacle in obstacles) {
        if (_cutThisSwipe.contains(obstacle)) continue;
        if (Geometry.segmentIntersectsRect(
          _lastDragPoint!,
          newPoint,
          obstacle.hitRect,
        )) {
          _performCut(obstacle, cutDirection: newPoint - _lastDragPoint!);
          if (!playerStats.hasPenetratingCut &&
              _cutThisSwipe.length >= playerStats.sliceCount) {
            break;
          }
        }
      }
    }
    _lastDragPoint = newPoint.clone();
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _endSwipe();
  }

  @override
  void onPanCancel() {
    _endSwipe();
  }

  void _endSwipe() {
    _lastDragPoint = null;
    _cutThisSwipe.clear();
    _activeTrail?.finish();
    _activeTrail = null;
  }

  void _performCut(ObstacleComponent obstacle, {required Vector2 cutDirection}) {
    _cutThisSwipe.add(obstacle);

    final isCritical = _random.nextDouble() < playerStats.criticalChance;
    final xpGain = isCritical ? 30 : 10;

    _combo++;
    _comboTimer = playerStats.comboHoldDuration;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _totalCuts++;
    if (isCritical) _criticalCuts++;
    _comboPopup.trigger(_combo);

    add(
      SliceParticleComponent(
        position: obstacle.position.clone(),
        color: obstacle.material.cutColor,
        cutDirection: cutDirection,
        isCritical: isCritical,
        random: _random,
      ),
    );

    add(
      SparkBurstComponent(
        position: obstacle.position.clone(),
        colors: [obstacle.material.color, obstacle.material.cutColor, const Color(0xFFFFFFFF)],
        count: isCritical ? 40 : 20,
        speedMultiplier: isCritical ? 1.6 : 1.0,
        random: _random,
      ),
    );

    add(
      ShockwaveRingComponent(
        position: obstacle.position.clone(),
        color: isCritical ? const Color(0xFFFFFFFF) : obstacle.material.color,
        maxRadius: (isCritical ? 110 : 70) * (obstacle.size.x / 46).clamp(0.4, 1.6),
      ),
    );

    _triggerShake(isCritical ? 0.22 : 0.09, isCritical ? 9.0 : 3.0);
    if (isCritical) {
      _screenFlash.flash(const Color(0xFFFFFFFF), duration: 0.18, peakAlpha: 0.45);
    }

    audio.playCut(obstacle.material.cutSoundKey, comboStep: min(_combo, 10));
    if (isCritical) {
      audio.playCritical();
    }

    _slowmoTimer = playerStats.slowMotionDuration;

    add(
      XpGemComponent(
        position: obstacle.position.clone(),
        xpValue: xpGain,
        getPlayerPosition: () => _player.position,
        onCollected: _addXp,
      ),
    );

    obstacle.removeFromParent();
  }

  // --- XP / 레벨업 ---

  void _addXp(int amount) {
    _xpCurrent += amount;
    while (_xpCurrent >= _xpToNext) {
      _xpCurrent -= _xpToNext;
      _levelUp();
    }
    _pushHud();
  }

  void _levelUp() {
    _level++;
    _xpToNext = 50 + _level * 35;
    _triggerLevelUpChoice();
  }

  void _triggerLevelUpChoice() {
    _isLevelUpActive = true;
    pendingUpgradeChoices.value = playerStats.rollChoices(3);
    audio.playLevelUp();
  }

  void selectUpgrade(UpgradeDef def) {
    playerStats.applyUpgrade(def.type);
    if (def.type == UpgradeType.guardianShield) {
      _shield++;
    }
    pendingUpgradeChoices.value = null;
    _isLevelUpActive = false;
    _pushHud();
  }

  // --- 게임 오버 ---

  void _triggerGameOver() {
    _isGameOver = true;
    audio.playGameOver();
    final summary = RunSummary(
      survivedSeconds: _elapsedSeconds,
      levelReached: _level,
      totalCuts: _totalCuts,
      criticalCuts: _criticalCuts,
      maxCombo: _maxCombo,
      timestamp: DateTime.now(),
    );
    gameOverSummary.value = summary;
    runRepository.saveRun(summary);
  }

  void _pushHud() {
    hud.value = HudSnapshot(
      hp: _hp,
      maxHp: _maxHp,
      shield: _shield,
      level: _level,
      xpCurrent: _xpCurrent,
      xpToNext: _xpToNext,
      combo: _combo,
      elapsedSeconds: _elapsedSeconds,
    );
  }
}
