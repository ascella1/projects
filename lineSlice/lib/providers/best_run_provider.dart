import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/run_repository.dart';
import '../game/models/run_summary.dart';

final runRepositoryProvider = Provider((ref) => RunRepository());

final bestRunProvider = Provider<RunSummary?>((ref) {
  return ref.watch(runRepositoryProvider).bestRun();
});
