/// Hive box 이름 상수. 박스를 열 때는 반드시 이 상수를 통해서만 접근한다.
class HiveBoxes {
  HiveBoxes._();

  static const String character = 'character_box';
  static const String recipe = 'recipe_box';
}

/// 캐릭터 박스 안에서 캐릭터 데이터를 저장할 고정 키. 유저당 캐릭터가 하나뿐이므로
/// 리스트가 아닌 단일 키-값으로 저장한다.
const String characterHiveKey = 'character';
