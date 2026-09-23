import 'package:flutter/material.dart';

/// Central design tokens for the whole app.
///
/// Every colour, corner radius, spacing step, and elevation level lives
/// here so the UI stays consistent and can be re-skinned in one place.
class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF8B83FF);
  static const primaryDark = Color(0xFF4E4BC8);
  static const accent = Color(0xFFFF6584);
  static const success = Color(0xFF34A853);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE5523F);
  static const info = Color(0xFF00BCD4);

  // Mode accents (deliberately distinct, saturate subtly)
  static const focusColor = Color(0xFF6C63FF);
  static const shortBreakColor = Color(0xFF34A853);
  static const longBreakColor = Color(0xFFFF9800);

  // Surfaces & text
  static const backgroundLight = Color(0xFFF4F5F9);
  static const backgroundDark = Color(0xFF0E1020);
  static const surfaceDark = Color(0xFF1A1D3A);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F1F6);
  static const textLight = Color(0xFF1F2430);
  static const textDark = Color(0xFFF0F1F7);
  static const textMutedLight = Color(0xFF8A93A6);
  static const textMutedDark = Color(0xFF9AA2B8);

  // Borders / dividers
  static const borderLight = Color(0xFFE4E7EF);
  static const borderDark = Color(0xFF2A2E4F);

  // Semantic stars
  static const star = Color(0xFFFFB300);
  static const tasbeehGreen = Color(0xFF34A853);

  // Accessible project palette (kept for backward data compatibility)
  static const projectColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF34A853),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF5722),
  ];
}

/// Corner-radius scale.
class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 100.0;

  static const smR = Radius.circular(sm);
  static const mdR = Radius.circular(md);
  static const lgR = Radius.circular(lg);
  static const xlR = Radius.circular(xl);
}

/// 4px-based spacing scale.
class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Shared elevation shadows for light/dark surfaces.
class AppShadow {
  static const subtle = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 14,
    offset: Offset(0, 3),
  );
  static const soft = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  static const focus = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 40,
    offset: Offset(0, 14),
  );
}

class AppConstants {
  static const dailyGoalDefault = 8;

  static const projectIcons = [
    '🎯', '💻', '📚', '🎨', '🔬', '📝', '🎵', '🏋️',
    '🌟', '🔧', '📱', '🎮', '🧠', '💡', '🚀', '⭐',
    '🛠️', '📊', '🌍', '🎭',
  ];
}

/// Shared duration/easing for a consistent motion system.
class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 480);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;
  static const elastic = Curves.easeOutBack;
}

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
          letterSpacing: -0.5,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: AppColors.textMutedLight,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: AppColors.textMutedLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
          letterSpacing: -0.5,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: AppColors.textDark,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: AppColors.textMutedDark,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: BorderSide(color: AppColors.borderDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }
}

