import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF5A65AB);
  static const primaryDark = Color(0xFF292E51);
  static const canvas = Color(0xFFF8F9FC);
  static const text = Color(0xFF1F1F1F);
  static const muted = Color(0xFF666666);
  static const border = Color(0xFFD4D4D4);
  static const success = Color(0xFF11A908);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'DM Sans',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32,
            height: 1,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171717)),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: AppColors.text),
        bodyMedium: TextStyle(
            fontSize: 14,
            height: 22 / 14,
            fontWeight: FontWeight.w400,
            color: AppColors.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w300,
          color: Color(0xFFA3A3A3),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(minHeight: 48),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: 2,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.primary),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
