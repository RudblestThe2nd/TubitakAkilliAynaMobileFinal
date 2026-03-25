import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimalist koyu tema — akıllı ayna estetğiyle uyumlu.
class AppTheme {
  AppTheme._();

  // ── Renk Paleti ───────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryVariant = Color(0xFF4B44CC);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFF00E5FF);
  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(0xFFFFB74D);
  static const Color success = Color(0xFF66BB6A);

  // Dark surfaces
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF121218);
  static const Color surfaceVariant = Color(0xFF1A1A24);
  static const Color cardColor = Color(0xFF1E1E2A);
  static const Color dividerColor = Color(0xFF2A2A3A);

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textDisabled = Color(0xFF555566);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2A), Color(0xFF252535)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient mirrorGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF1A1A30)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 12,
          color: textDisabled,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(color: textDisabled),
        labelStyle: GoogleFonts.outfit(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textDisabled,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: dividerColor,
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Yeniden kullanılabilir gölge efektleri.
class AppShadows {
  static List<BoxShadow> glow({
    Color color = AppTheme.primary,
    double blurRadius = 20,
    double spreadRadius = 0,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
