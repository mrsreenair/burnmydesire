import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Single ThemeData: the warm-paper world. (The burn screen overrides
/// itself to [AppColors.night] — the one dark moment in the app.)
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.accent,
    secondary: AppColors.money,
    surface: AppColors.paper,
    surfaceContainerLow: AppColors.paper,
    surfaceContainer: AppColors.paperHigh,
    surfaceContainerHigh: AppColors.paperHigh,
    surfaceContainerHighest: AppColors.field,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.textMid,
    outlineVariant: AppColors.hairline,
    error: const Color(0xFFD8402C),
  );

  // Canopi-style editorial type: heavy black headings with tight
  // tracking, calm gray body.
  const display = TextStyle(
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.04,
    color: AppColors.ink,
  );
  final textTheme = Typography.blackMountainView.copyWith(
    displayLarge: display.copyWith(fontSize: 64, letterSpacing: -2),
    displayMedium: display.copyWith(fontSize: 52, letterSpacing: -1.8),
    displaySmall: display.copyWith(fontSize: 40, letterSpacing: -1.4),
    headlineMedium: display.copyWith(fontSize: 30, letterSpacing: -0.8),
    headlineSmall: display.copyWith(fontSize: 24, letterSpacing: -0.5),
    titleLarge: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.ink),
    titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: AppColors.inkSoft),
    titleSmall: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
    bodyLarge:
        const TextStyle(fontSize: 16, height: 1.5, color: AppColors.inkSoft),
    bodyMedium:
        const TextStyle(fontSize: 14, height: 1.5, color: AppColors.inkSoft),
    bodySmall: const TextStyle(
        fontSize: 12, height: 1.45, color: AppColors.textMid),
    labelLarge: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.ink),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.paperHigh,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    // Black pill — the Canopi default action.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.paperHigh,
        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.textMid),
    ),
    // Grey pill fields, borderless — type sits in soft recesses.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textMid),
      hintStyle: const TextStyle(color: AppColors.textLow),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.paperHigh,
      selectedColor: AppColors.accent.withValues(alpha: 0.14),
      checkmarkColor: AppColors.accent,
      side: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
      labelStyle: const TextStyle(color: AppColors.ink),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.field,
      thumbColor: AppColors.paperHigh,
      overlayColor: AppColors.accent.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.field),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paperHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textMid),
    dividerTheme: const DividerThemeData(color: AppColors.hairline),
  );
}
