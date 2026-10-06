import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xfff6f7fb);
  static const ink = Color(0xff22242b);
  static const muted = Color(0xff9299a8);
  static const lime = Color(0xffbde530);
  static const teal = Color(0xff4db99a);
  static const amber = Color(0xffb98022);
  static const red = Color(0xffbd5147);
  static const line = Color(0xffe5e8ee);
}

ThemeData boxerTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lime, surface: Colors.white),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -.8),
        headlineMedium: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -.6),
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line)),
      ),
    );
