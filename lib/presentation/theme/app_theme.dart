// lib/presentation/theme/app_theme.dart
// Dark-first Material 3 theme with premium minimal aesthetic.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  // Brand
  static const primary = Color(0xFF5B8FFF);
  static const primaryContainer = Color(0xFF1A2E6B);
  static const secondary = Color(0xFF7EFFF5);
  static const secondaryContainer = Color(0xFF003D38);

  // Backgrounds (dark)
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF13131A);
  static const surfaceVariant = Color(0xFF1C1C26);
  static const surfaceContainer = Color(0xFF1E1E2A);
  static const surfaceContainerHigh = Color(0xFF252535);

  // Status
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFFF5555);
  static const info = Color(0xFF60A5FA);

  // Text
  static const onBackground = Color(0xFFF0F0FF);
  static const onSurface = Color(0xFFE0E0F0);
  static const onSurfaceDim = Color(0xFF9090B0);
  static const onSurfaceMuted = Color(0xFF5A5A7A);

  // Divider / border
  static const outline = Color(0xFF2A2A3A);
  static const outlineVariant = Color(0xFF1E1E2E);

  // Light mode
  static const backgroundLight = Color(0xFFF5F5FF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const primaryLight = Color(0xFF3B6FFF);
}

class AppTheme {
  AppTheme._();

  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 57, fontWeight: FontWeight.w300, letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w300),
    displaySmall: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: GoogleFonts.inter(
      fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.3,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.2,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.1,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.1,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1,
    ),
    bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
    ),
  );

  // ─── Dark theme ─────────────────────────────────────────────────────────

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.background,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.secondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceContainerHigh,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      error: AppColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme.apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.onSurfaceDim),
        hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.onSurfaceDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.3);
          }
          return AppColors.outline;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x205B8FFF),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.onSurfaceDim,
        textColor: AppColors.onSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: GoogleFonts.inter(color: AppColors.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        selectedColor: AppColors.primaryContainer,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.onSurfaceMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.onSurfaceMuted);
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─── Light theme ─────────────────────────────────────────────────────────

  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: const Color(0xFF1A1A2E),
      outline: const Color(0xFFDDDDEE),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _textTheme,
    );
  }
}
