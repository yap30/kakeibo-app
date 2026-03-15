import 'package:flutter/material.dart';

// ============================================================
// KAKEIBO COLOR PALETTE
// Inspired by Japanese aesthetics: washi paper, sumi ink, nature
// ============================================================
class KakeiboColors {
  // Primary - Sumi Ink (墨)
  static const Color ink = Color(0xFF1C1C1E);
  static const Color inkLight = Color(0xFF3A3A3C);
  static const Color inkFade = Color(0xFF636366);

  // Background - Washi Paper (和紙)
  static const Color paper = Color(0xFFF5F0E8);
  static const Color paperDark = Color(0xFFEDE8DF);
  static const Color paperWhite = Color(0xFFFAF8F5);

  // Kakeibo Category Colors
  static const Color needs = Color(0xFF3D6B4F);      // Forest green - 必要
  static const Color needsLight = Color(0xFFE8F2EC);
  static const Color wants = Color(0xFFB85C3A);      // Terracotta - 欲しい
  static const Color wantsLight = Color(0xFFF7EBE6);
  static const Color culture = Color(0xFF4A6FA5);    // Indigo blue - 文化
  static const Color cultureLight = Color(0xFFE8EEF7);
  static const Color unexpected = Color(0xFFB8963A);  // Amber gold - 予期せぬ
  static const Color unexpectedLight = Color(0xFFF7F0E4);

  // Accent
  static const Color accent = Color(0xFF8B4F6A);     // Sakura plum
  static const Color accentLight = Color(0xFFF2E8ED);

  // Income / Expense
  static const Color income = Color(0xFF3D6B4F);
  static const Color expense = Color(0xFFB85C3A);

  // Utility
  static const Color divider = Color(0xFFE5DFD5);
  static const Color shadow = Color(0x1A1C1C1E);
  static const Color overlay = Color(0x80000000);
}

// ============================================================
// TYPOGRAPHY
// ============================================================
class KakeiboTextStyles {
  // Display - for big numbers, headers (Japanese feel)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: KakeiboColors.ink,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: KakeiboColors.ink,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: KakeiboColors.ink,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // Body - clean, readable
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: KakeiboColors.ink,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: KakeiboColors.inkFade,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: KakeiboColors.inkFade,
    height: 1.4,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: KakeiboColors.ink,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: KakeiboColors.ink,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: KakeiboColors.inkFade,
    letterSpacing: 0.8,
  );

  // Amount
  static TextStyle amountLarge({Color? color}) => TextStyle(
    fontFamily: 'Georgia',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: color ?? KakeiboColors.ink,
    letterSpacing: -1,
    height: 1,
  );

  static TextStyle amountMedium({Color? color}) => TextStyle(
    fontFamily: 'Georgia',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: color ?? KakeiboColors.ink,
    letterSpacing: -0.5,
  );
}

// ============================================================
// THEME DATA
// ============================================================
class KakeiboTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: KakeiboColors.ink,
      secondary: KakeiboColors.accent,
      surface: KakeiboColors.paperWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: KakeiboColors.ink,
      outline: KakeiboColors.divider,
      error: KakeiboColors.wants,
    ),
    scaffoldBackgroundColor: KakeiboColors.paper,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: KakeiboColors.paper,
      foregroundColor: KakeiboColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Georgia',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: KakeiboColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: KakeiboColors.paperWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KakeiboColors.divider, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KakeiboColors.paperWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KakeiboColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KakeiboColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KakeiboColors.ink, width: 1.5),
      ),
      labelStyle: KakeiboTextStyles.bodyMedium,
      hintStyle: KakeiboTextStyles.bodyMedium.copyWith(
        color: KakeiboColors.inkFade.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KakeiboColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: KakeiboTextStyles.labelLarge.copyWith(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: KakeiboColors.ink,
        textStyle: KakeiboTextStyles.labelMedium,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: KakeiboColors.divider,
      thickness: 1,
      space: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: KakeiboColors.paperWhite,
      selectedItemColor: KakeiboColors.ink,
      unselectedItemColor: KakeiboColors.inkFade,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}

// ============================================================
// KAKEIBO TYPE CONFIG
// ============================================================
class KakeiboTypeConfig {
  final String type;
  final String label;
  final String description;
  final String kanji;
  final Color color;
  final Color lightColor;
  final IconData icon;

  const KakeiboTypeConfig({
    required this.type,
    required this.label,
    required this.description,
    required this.kanji,
    required this.color,
    required this.lightColor,
    required this.icon,
  });

  static const List<KakeiboTypeConfig> all = [needs, wants, culture, unexpected];

  static const KakeiboTypeConfig needs = KakeiboTypeConfig(
    type: 'needs',
    label: 'Kebutuhan',
    description: 'Pengeluaran yang wajib',
    kanji: '必要',
    color: KakeiboColors.needs,
    lightColor: KakeiboColors.needsLight,
    icon: Icons.home_outlined,
  );

  static const KakeiboTypeConfig wants = KakeiboTypeConfig(
    type: 'wants',
    label: 'Keinginan',
    description: 'Pengeluaran yang diinginkan',
    kanji: '欲しい',
    color: KakeiboColors.wants,
    lightColor: KakeiboColors.wantsLight,
    icon: Icons.favorite_outline,
  );

  static const KakeiboTypeConfig culture = KakeiboTypeConfig(
    type: 'culture',
    label: 'Budaya',
    description: 'Pengembangan diri',
    kanji: '文化',
    color: KakeiboColors.culture,
    lightColor: KakeiboColors.cultureLight,
    icon: Icons.auto_stories_outlined,
  );

  static const KakeiboTypeConfig unexpected = KakeiboTypeConfig(
    type: 'unexpected',
    label: 'Tak Terduga',
    description: 'Pengeluaran tak terduga',
    kanji: '予期せぬ',
    color: KakeiboColors.unexpected,
    lightColor: KakeiboColors.unexpectedLight,
    icon: Icons.bolt_outlined,
  );

  static KakeiboTypeConfig fromType(String type) {
    if (type == 'income') return const KakeiboTypeConfig(type: 'income', label: 'Pemasukan', description: 'Sumber penghasilan', kanji: '収入', color: KakeiboColors.needs, lightColor: KakeiboColors.needsLight, icon: Icons.arrow_downward);
    return all.firstWhere((c) => c.type == type, orElse: () => needs);
  }
}

// Extension for income type
extension KakeiboTypeConfigExtension on KakeiboTypeConfig {
  static KakeiboTypeConfig get income => const KakeiboTypeConfig(
    type: 'income',
    label: 'Pemasukan',
    description: 'Sumber penghasilan',
    kanji: '収入',
    color: KakeiboColors.needs,
    lightColor: KakeiboColors.needsLight,
    icon: Icons.arrow_downward,
  );
}
