import 'package:flutter/material.dart';

class VoyagoColors {
  static const Color primary = Color(0xFF58CC02);
  static const Color primaryDark = Color(0xFF4CAF00);
  static const Color primaryLight = Color(0xFF89E219);
  static const Color blue = Color(0xFF1CB0F6);
  static const Color yellow = Color(0xFFFFC800);
  static const Color orange = Color(0xFFFF9600);
  static const Color coral = Color(0xFFFF4B4B);
  static const Color green = Color(0xFF58CC02);
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1D27);
  static const Color text = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF8A8A9B);
  static const Color cardBorder = Color(0xFF2A2D3A);
}

ThemeData voyagoTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: VoyagoColors.background,
  primaryColor: VoyagoColors.primary,
  colorScheme: const ColorScheme.dark(
    primary: VoyagoColors.primary,
    secondary: VoyagoColors.blue,
    surface: VoyagoColors.surface,
    error: VoyagoColors.coral,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: VoyagoColors.text,
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: VoyagoColors.background,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: VoyagoColors.text),
    titleTextStyle: TextStyle(
      color: VoyagoColors.text,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    color: VoyagoColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: VoyagoColors.cardBorder, width: 1),
    ),
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: VoyagoColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: VoyagoColors.primary,
      side: const BorderSide(color: VoyagoColors.primary, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: VoyagoColors.primary,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: VoyagoColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: VoyagoColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: VoyagoColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: VoyagoColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: VoyagoColors.coral),
    ),
    labelStyle: const TextStyle(color: VoyagoColors.muted),
    hintStyle: const TextStyle(color: VoyagoColors.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  dividerTheme: const DividerThemeData(
    color: VoyagoColors.cardBorder,
    thickness: 1,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: VoyagoColors.primary,
    unselectedLabelColor: VoyagoColors.muted,
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: VoyagoColors.primary, width: 3),
    ),
    indicatorSize: TabBarIndicatorSize.label,
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: VoyagoColors.primary,
    inactiveTrackColor: VoyagoColors.cardBorder,
    thumbColor: VoyagoColors.primary,
    overlayColor: Color(0x2958CC02),
    valueIndicatorColor: VoyagoColors.primaryDark,
    valueIndicatorTextStyle: TextStyle(color: Colors.white),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: VoyagoColors.surface,
    selectedColor: VoyagoColors.primary,
    disabledColor: VoyagoColors.surface,
    labelStyle: const TextStyle(color: VoyagoColors.text),
    secondaryLabelStyle: const TextStyle(color: Colors.white),
    side: const BorderSide(color: VoyagoColors.cardBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: VoyagoColors.primary,
    linearTrackColor: VoyagoColors.cardBorder,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: VoyagoColors.text,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      color: VoyagoColors.text,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineLarge: TextStyle(
      color: VoyagoColors.text,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: VoyagoColors.text,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: TextStyle(
      color: VoyagoColors.text,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      color: VoyagoColors.text,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      color: VoyagoColors.text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: VoyagoColors.text, fontSize: 16),
    bodyMedium: TextStyle(color: VoyagoColors.text, fontSize: 14),
    bodySmall: TextStyle(color: VoyagoColors.muted, fontSize: 12),
    labelLarge: TextStyle(
      color: VoyagoColors.text,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  ),
);
