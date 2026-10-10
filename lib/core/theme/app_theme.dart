import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const radiusSm = 4.0;
  static const radiusMd = 8.0;
  static const radiusLg = 12.0;

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(color: Color(0x0F0F172A), blurRadius: 16, offset: Offset(0, 4)),
      ];

  /// Tabular numerics for telemetry values (°C, kW, timestamps).
  static TextStyle numeric({double size = 14, Color color = AppColors.textMain}) =>
      GoogleFonts.exo2(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle badge(Color color) => GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: color,
      );

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
    );
    final text = GoogleFonts.exo2TextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.exo2(fontSize: 34, fontWeight: FontWeight.w700, height: 1.15, color: AppColors.textMain),
      headlineSmall: GoogleFonts.exo2(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25, color: AppColors.textMain),
      titleMedium: GoogleFonts.exo2(fontSize: 18, fontWeight: FontWeight.w600, height: 1.25, color: AppColors.textMain),
      bodyMedium: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textMain),
      bodySmall: GoogleFonts.exo2(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textMuted),
      labelLarge: GoogleFonts.exo2(fontSize: 14, fontWeight: FontWeight.w600),
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textMain,
        titleTextStyle: text.titleMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textSubtle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.exo2(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSubtle,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSubtle,
          ),
        ),
      ),
    );
  }
}
