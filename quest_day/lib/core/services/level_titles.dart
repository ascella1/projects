import 'dart:convert';
import 'package:flutter/services.dart';

class LevelTitles {
  static List<({int level, String title})> _entries = [];

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/level_titles.json');
    final list = jsonDecode(raw) as List;
    _entries = list
        .map((e) => (level: e['level'] as int, title: e['title'] as String))
        .toList();
  }

  static String? titleForLevel(int level) {
    String? result;
    for (final e in _entries) {
      if (level >= e.level) result = e.title;
    }
    return result;
  }

  static String? unlockedAt(int level) {
    for (final e in _entries) {
      if (e.level == level) return e.title;
    }
    return null;
  }
}
