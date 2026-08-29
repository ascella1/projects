import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/cafe/data/models/recipe_hive_model.dart';
import '../../features/character/data/models/character_hive_model.dart';
import '../../hive_registrar.g.dart';
import 'hive_boxes.dart';

/// 앱 시작 시 한 번 호출해서 Hive를 초기화하고 필요한 박스를 전부 열어둔다.
class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await registerAdaptersAndOpenBoxes();
  }

  /// 플랫폼 채널 없이도(위젯 테스트 등) 어댑터 등록/박스 오픈만 재사용할 수 있도록 분리.
  static Future<void> registerAdaptersAndOpenBoxes() async {
    Hive.registerAdapters();

    await Hive.openBox<CharacterHiveModel>(HiveBoxes.character);
    await Hive.openBox<RecipeHiveModel>(HiveBoxes.recipe);
  }
}
