import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// docs/01 section 5 "UI/UX 스타일 가이드" 구현 — 모던 핀테크 톤, 브랜드 1색 + 중립 그레이,
/// 라운드 카드(16~20px), 다크모드 전 화면 지원.
class AppTheme {
  AppTheme._();

  static const _brand = Color(0xFF4F46E5); // indigo — 신뢰감 있는 핀테크 브랜드 컬러
  static const _brandLight = Color(0xFF818CF8);

  static const radius = 20.0;
  static const radiusSm = 14.0;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _brand,
      brightness: brightness,
      primary: isDark ? _brandLight : _brand,
    );

    final background = isDark ? const Color(0xFF0B0D12) : const Color(0xFFF7F8FA);
    final surface = isDark ? const Color(0xFF15181F) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(surface: surface),
      scaffoldBackgroundColor: background,
      textTheme: _textTheme(isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111318),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF111318),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1F232C) : const Color(0xFFF0F1F5),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF4B5563), fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : const Color(0xFF111318),
          side: BorderSide(color: isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE5E7EB)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B1F27) : const Color(0xFFF0F1F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF23272F) : const Color(0xFFEDEEF1),
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final color = isDark ? Colors.white : const Color(0xFF111318);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    return TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
      bodyLarge: TextStyle(fontSize: 15, color: color, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: subColor, height: 1.5),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor),
    );
  }
}
