/// 상점 아이템. 카테고리를 늘리면(costume 등) 자동으로 상점 화면에서 확장되는 구조.
enum ShopItemCategory { food, toy, bed }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.careBonus,
  });

  final String id;
  final String name;
  final ShopItemCategory category;
  final int price;

  /// 보유 시 집 케어 액션(먹이/씻기/놀기)의 게이지 증가량에 더해지는 보너스.
  final int careBonus;
}

/// MVP 상점 카탈로그. 실제 서비스에서는 원격에서 받아오도록 교체 가능하게
/// 이 리스트 하나만 갈아끼우면 되도록 분리해둔다.
const List<ShopItem> kShopCatalog = [
  ShopItem(
    id: 'premium_snack',
    name: '프리미엄 간식',
    category: ShopItemCategory.food,
    price: 20,
    careBonus: 2,
  ),
  ShopItem(
    id: 'squeaky_toy',
    name: '삑삑이 장난감',
    category: ShopItemCategory.toy,
    price: 30,
    careBonus: 2,
  ),
  ShopItem(
    id: 'cozy_bed',
    name: '포근한 침대',
    category: ShopItemCategory.bed,
    price: 50,
    careBonus: 3,
  ),
];
