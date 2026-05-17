import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Navy Palette
  static const Color bgDeep = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgSurface = Color(0xFF1A2235);
  static const Color bgElevated = Color(0xFF1F2D42);

  // Teal Accent
  static const Color tealPrimary = Color(0xFF00D4AA);
  static const Color tealLight = Color(0xFF4DFFDC);
  static const Color tealDark = Color(0xFF009E7F);
  static const Color tealGlow = Color(0x3300D4AA);

  // Expense / Income
  static const Color income = Color(0xFF00D4AA);
  static const Color expense = Color(0xFFFF5A7E);
  static const Color incomeGlow = Color(0x3300D4AA);
  static const Color expenseGlow = Color(0x33FF5A7E);

  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF00D4AA), // Teal
    Color(0xFF6C63FF), // Purple
    Color(0xFFFF5A7E), // Pink
    Color(0xFFFFB547), // Amber
    Color(0xFF4FC3F7), // Sky
    Color(0xFF81C784), // Green
    Color(0xFFFF7043), // Deep Orange
    Color(0xFFE91E63), // Rose
    Color(0xFF26C6DA), // Cyan
    Color(0xFFAB47BC), // Violet
    Color(0xFFFFEE58), // Yellow
    Color(0xFF8D6E63), // Brown
  ];

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8896B3);
  static const Color textMuted = Color(0xFF4A5568);

  // Borders & Dividers
  static const Color border = Color(0xFF1E2D42);
  static const Color divider = Color(0xFF1A2235);

  // Glassmorphism
  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // Gradients
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF0097A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF5A7E), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1525)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2235), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  // ── Dark Theme ───────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    bgDeep: AppColors.bgDeep, bgCard: AppColors.bgCard,
    bgSurface: AppColors.bgSurface, textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary, textMuted: AppColors.textMuted,
    border: AppColors.border,
  );

  // ── Light Theme ──────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    bgDeep: const Color(0xFFF0F4FF), bgCard: const Color(0xFFFFFFFF),
    bgSurface: const Color(0xFFF1F5F9), textPrimary: const Color(0xFF0A0E1A),
    textSecondary: const Color(0xFF475569), textMuted: const Color(0xFF94A3B8),
    border: const Color(0xFFDDE3F0),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bgDeep, required Color bgCard, required Color bgSurface,
    required Color textPrimary, required Color textSecondary,
    required Color textMuted, required Color border,
  }) {
    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: bgDeep,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.tealPrimary, secondary: AppColors.tealLight,
        surface: bgCard, error: AppColors.expense,
        onPrimary: AppColors.bgDeep, onSecondary: AppColors.bgDeep,
        onSurface: textPrimary, onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
        displaySmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted),
        labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.tealPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealPrimary, foregroundColor: AppColors.bgDeep,
          elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: bgSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.tealPrimary, width: 1.5)),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: AppColors.bgDeep,
        elevation: 8,
      ),
    );
  }
}
