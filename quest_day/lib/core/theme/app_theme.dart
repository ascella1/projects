import 'package:flutter/material.dart';

// ── 테마 독립적 정적 컬러 (라이트/다크 공통) ─────────────────────────────────────
class AppColors {
  // Brand
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF9D5CF6);
  static const primaryDark = Color(0xFF5B21B6);
  static const accent = Color(0xFFF59E0B);
  static const accentLight = Color(0xFFFBBF24);

  // Comfort levels
  static const safe = Color(0xFF10B981);
  static const normal = Color(0xFF3B82F6);
  static const challenge = Color(0xFFF59E0B);
  static const crazy = Color(0xFFEF4444);

  // Quest categories
  static const exploration = Color(0xFF06B6D4);
  static const social = Color(0xFFF97316);
  static const creative = Color(0xFFEC4899);
  static const thinking = Color(0xFF8B5CF6);
  static const action = Color(0xFF10B981);
  static const relationship = Color(0xFFF43F5E);
  static const random = Color(0xFFFFD700);
}

// ── 테마 종속 컬러 (라이트/다크 전환) ────────────────────────────────────────────
@immutable
class QColors extends ThemeExtension<QColors> {
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final bool isDark;

  const QColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.isDark,
  });

  static const dark = QColors(
    background: Color(0xFF0A0A14),
    surface: Color(0xFF13132A),
    card: Color(0xFF1A1A35),
    textPrimary: Color(0xFFF0F0FF),
    textSecondary: Color(0xFF9090AA),
    textMuted: Color(0xFF55556A),
    divider: Color(0xFF2A2A4A),
    isDark: true,
  );

  static const light = QColors(
    background: Color(0xFFF4F1FF),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E0B3B),
    textSecondary: Color(0xFF5C4B8A),
    textMuted: Color(0xFF9B8AB5),
    divider: Color(0xFFE6E0F5),
    isDark: false,
  );

  @override
  QColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    bool? isDark,
  }) =>
      QColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        card: card ?? this.card,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        divider: divider ?? this.divider,
        isDark: isDark ?? this.isDark,
      );

  @override
  QColors lerp(QColors? other, double t) {
    if (other == null) return this;
    return QColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

// BuildContext 단축키
extension QColorsX on BuildContext {
  QColors get qc => Theme.of(this).extension<QColors>()!;
}

// ── ThemeData 팩토리 ──────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark => _build(QColors.dark, Brightness.dark);
  static ThemeData get light => _build(QColors.light, Brightness.light);

  static ThemeData _build(QColors qc, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: qc.background,
      extensions: [qc],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.crazy,
        onError: Colors.white,
        surface: qc.surface,
        onSurface: qc.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: qc.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: qc.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: qc.card,
        elevation: qc.isDark ? 0 : 1,
        shadowColor: const Color(0x1A7C3AED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: qc.divider, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: qc.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: qc.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
