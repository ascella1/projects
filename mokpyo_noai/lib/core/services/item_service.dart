import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// assets/data/mokpyo_item.json 에 정의된 인벤토리 악세사리 목록을 로드한다.
class ItemService {
  static const _assetPath = 'assets/data/mokpyo_item.json';

  static List<Map<String, String>>? _itemsCache;

  static Future<List<Map<String, String>>> loadItems() async {
    if (_itemsCache != null) return _itemsCache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((e) => e.map((key, value) => MapEntry(key, value as String)))
        .toList();
    _itemsCache = items;
    return items;
  }
}
