/// 스펙 6번 난이도 곡선 계산. 15초마다 계단식으로 스폰 간격은 줄고
/// 이동속도는 늘어난다.
class DifficultyManager {
  static const double _baseSpawnInterval = 1.2;
  static const double _spawnIntervalStep = 0.05;
  static const double _minSpawnInterval = 0.4;

  static const double _baseFallSpeed = 300;
  static const double _fallSpeedGrowthPerStep = 0.05;

  static const double _stepDurationSeconds = 15;

  static int _stepsFor(double elapsedSeconds) =>
      (elapsedSeconds / _stepDurationSeconds).floor();

  static double spawnIntervalFor(double elapsedSeconds) {
    final steps = _stepsFor(elapsedSeconds);
    final interval = _baseSpawnInterval - steps * _spawnIntervalStep;
    return interval < _minSpawnInterval ? _minSpawnInterval : interval;
  }

  static double fallSpeedFor(double elapsedSeconds) {
    final steps = _stepsFor(elapsedSeconds);
    return _baseFallSpeed * (1 + steps * _fallSpeedGrowthPerStep);
  }
}
