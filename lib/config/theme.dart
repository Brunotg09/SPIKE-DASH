import 'package:flutter/material.dart';

/// Constantes de cores do tema cyberpunk do SPIKE DASH.
/// Substitui os 100+ valores hardcoded Color(0xFF...) espalhados pelo projeto.
class AppColors {
  AppColors._();

  // ==================== CORES PRIMARIAS ====================
  static const Color primary = Color(0xFF00FF66);
  static const Color secondary = Color(0xFF00FFFF);
  static const Color accent = Color(0xFFFFE600);
  static const Color danger = Color(0xFFFF0055);
  static const Color warning = Color(0xFFFF5500);

  // ==================== CORES DE FUNDO ====================
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF09090B);
  static const Color surfaceLight = Color(0xFF050505);
  static const Color surfaceElevated = Color(0xFF111111);

  // ==================== CORES DE BORDA ====================
  static const Color border = Color(0xFF18181B);
  static const Color borderLight = Color(0xFF27272A);
  static const Color borderSubtle = Color(0xFF141416);

  // ==================== CORES DE TEXTO ====================
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFF4F4F5);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDim = Color(0xFFA1A1AA);
  static const Color textHint = Color(0xFF52525B);
  static const Color textLabel = Color(0xFFE4E4E7);

  // ==================== CORES DOS MODOS DE JOGO ====================
  static const Color tapPrecision = Color(0xFF00FF66);
  static const Color reflexDuel = Color(0xFFFF5500);
  static const Color perfectTiming = Color(0xFF00FFFF);
  static const Color stroopShot = Color(0xFFFF0055);

  // ==================== CORES DE JOGADOR ====================
  static const Color player1 = Color(0xFFFF3366);
  static const Color player2 = Color(0xFF3366FF);

  // ==================== CORES DE ESTADO DO DUELO ====================
  static const Color tensionDark = Color(0xFF0B0805);
  static const Color fireGreen = Color(0xFF003311);
  static const Color penaltyRed = Color(0xFF330000);

  // ==================== CORES DE CONQUISTA ====================
  static const Color conquistaFast = Color(0xFF00FF66);
  static const Color conquistaCombo = Color(0xFFFF5500);
  static const Color conquistaRitmo = Color(0xFF00FFFF);
  static const Color conquistaGloria = Color(0xFFFFE600);
}

/// Tema principal do aplicativo SPIKE DASH.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Rajdhani',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
    );
  }
}
