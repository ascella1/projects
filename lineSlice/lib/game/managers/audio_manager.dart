import 'dart:math';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// 사운드 재생을 담당. 에셋 파일(assets/audio/*.mp3)이 아직 없는 상태이므로
/// 재생 실패는 조용히 무시한다 - 나중에 파일만 채워 넣으면 바로 동작한다.
///
/// 콤보 단계(1~10)에 따라 피치가 반음씩 상승하고, 매 재생마다 ±5% 랜덤
/// 변주가 더해진다 (스펙 4번).
class AudioManager {
  AudioManager() : _random = Random();

  final Random _random;
  bool _muted = false;

  static const double _semitoneRatio = 1.0594630943592953; // 2^(1/12)

  double _pitchForCombo(int comboStep) {
    final clampedStep = comboStep.clamp(0, 10);
    final semitoneShift = pow(_semitoneRatio, clampedStep).toDouble();
    final randomVariance = 1.0 + (_random.nextDouble() * 0.1 - 0.05);
    return semitoneShift * randomVariance;
  }

  Future<void> _playSafely(String assetKey, {double pitch = 1.0}) async {
    if (_muted) return;
    try {
      await FlameAudio.play('$assetKey.mp3', volume: 1.0);
    } catch (e) {
      debugPrint('[AudioManager] "$assetKey" 재생 실패 (에셋 미준비 추정): $e');
    }
  }

  /// 일반 절단음. [comboStep]은 현재 콤보 단계(0~10)로 피치를 결정한다.
  void playCut(String materialSoundKey, {required int comboStep}) {
    _playSafely(materialSoundKey, pitch: _pitchForCombo(comboStep));
  }

  /// 크리티컬 절단 시 별도 강조 사운드.
  void playCritical() {
    _playSafely('cut_critical');
  }

  void playMiss() {
    _playSafely('miss');
  }

  void playLevelUp() {
    _playSafely('level_up');
  }

  void playGameOver() {
    _playSafely('game_over');
  }

  void setMuted(bool muted) {
    _muted = muted;
  }
}
