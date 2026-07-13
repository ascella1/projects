import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// 여러 탭(나의 정원/상자 오픈/인벤토리/업적)이 각자 독립적으로 악세사리
// 목록을 watch할 수 있도록 하는 provider. ItemService가 이미 결과를
// static 캐싱하므로 실제 파일 로드는 앱 전체에서 한 번만 일어난다.
final itemListProvider =
    FutureProvider<List<Map<String, String>>>((ref) => ItemService.loadItems());
