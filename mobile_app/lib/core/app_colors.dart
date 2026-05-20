import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF006A18);
  static const Color primaryDark = Color(0xFF004D10);
  static const Color primaryLight = Color(0xFF2ECC71);
  static const Color primarySurface = Color(0xFFE5F7E5);

  static const List<Color> primaryGradient = [primary, primaryLight];

  // ── Neutral ────────────────────────────────────────────────────────────────
  static const Color grey50 = Color(0xFFF5F5F5);
  static const Color grey100 = Color(0xFFEEEEEE);
  static const Color grey200 = Color(0xFFCCCCCC);
  static const Color grey400 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey800 = Color(0xFF424242);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF2C2C2C);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFCCCCCC);
  static const Color textOnPrimary = Colors.white;
  static const Color headerSubtitle = Color(0xFFE5F7E5);

  // ── Surface / Background ───────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color fieldBg = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFCCCCCC);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color errorSurface = Color(0xFFFFEBEB);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningSurface = Color(0xFFFFF3E0);
  static const Color success = Color(0xFF2E7D32);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF1565C0);
  static const Color infoSurface = Color(0xFFE3F2FD);

  // ── Aliases legados (evitar quebrar código existente) ──────────────────────
  static const Color textDark = textSecondary;
}
