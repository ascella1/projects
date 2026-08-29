/// 런 종료 시 기록되는 요약. Hive box에는 `Map<String, dynamic>`으로 저장된다.
class RunSummary {
  RunSummary({
    required this.survivedSeconds,
    required this.levelReached,
    required this.totalCuts,
    required this.criticalCuts,
    required this.maxCombo,
    required this.timestamp,
  });

  final double survivedSeconds;
  final int levelReached;
  final int totalCuts;
  final int criticalCuts;
  final int maxCombo;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
        'survivedSeconds': survivedSeconds,
        'levelReached': levelReached,
        'totalCuts': totalCuts,
        'criticalCuts': criticalCuts,
        'maxCombo': maxCombo,
        'timestamp': timestamp.toIso8601String(),
      };

  static RunSummary fromMap(Map<dynamic, dynamic> map) => RunSummary(
        survivedSeconds: (map['survivedSeconds'] as num).toDouble(),
        levelReached: map['levelReached'] as int,
        totalCuts: map['totalCuts'] as int,
        criticalCuts: map['criticalCuts'] as int,
        maxCombo: map['maxCombo'] as int,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
