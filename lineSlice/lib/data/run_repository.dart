import 'package:hive_flutter/hive_flutter.dart';

import '../game/models/run_summary.dart';

/// 런 기록을 로컬(Hive)에 저장/조회한다. MVP 범위에서는 영구 메타 업그레이드는
/// 다루지 않고, 런 기록만 남긴다 (스펙 10번: 메타 업그레이드는 추후 확장).
class RunRepository {
  static const String boxName = 'run_records';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  Future<void> saveRun(RunSummary summary) async {
    await _box.add(summary.toMap());
  }

  List<RunSummary> allRuns() {
    return _box.values
        .cast<Map<dynamic, dynamic>>()
        .map(RunSummary.fromMap)
        .toList();
  }

  RunSummary? bestRun() {
    final runs = allRuns();
    if (runs.isEmpty) return null;
    runs.sort((a, b) => b.survivedSeconds.compareTo(a.survivedSeconds));
    return runs.first;
  }
}
