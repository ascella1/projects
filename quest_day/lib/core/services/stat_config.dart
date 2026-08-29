import 'dart:convert';
import 'package:flutter/services.dart';

class StatDef {
  final String key;
  final String label;
  final String icon;
  final Color color;

  const StatDef({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  factory StatDef.fromJson(Map<String, dynamic> json) => StatDef(
        key: json['key'] as String,
        label: json['label'] as String,
        icon: json['icon'] as String,
        color: _parseColor(json['color'] as String),
      );

  static Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));
}

class StatConfig {
  static List<StatDef> _defs = [];

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/stats.json');
    final list = jsonDecode(raw) as List;
    _defs = list.map((e) => StatDef.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<StatDef> get all => _defs;
}
