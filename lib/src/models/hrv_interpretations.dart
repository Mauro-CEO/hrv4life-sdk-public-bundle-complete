import 'package:flutter/material.dart';

/// Centralized color and label mappings for HRV metric levels.
///
/// Use these helpers to render consistent UI across your app without
/// duplicating switch statements for every level string returned by the API.
class HrvInterpretations {
  HrvInterpretations._();

  // ── Readiness ────────────────────────────────────────────────────────────

  /// Color for a training readiness level string (optimal/good/moderate/low/rest).
  static Color readinessColor(String level) {
    switch (level.toLowerCase()) {
      case 'optimal':
        return const Color(0xFF4CAF50);
      case 'good':
        return const Color(0xFF8BC34A);
      case 'moderate':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFFFF5722);
      case 'rest':
        return const Color(0xFFFF5252);
      default:
        return Colors.grey;
    }
  }

  /// Short label for a training readiness level string.
  static String readinessLabel(String level) {
    switch (level.toLowerCase()) {
      case 'optimal':
        return 'Ótimo';
      case 'good':
        return 'Bom';
      case 'moderate':
        return 'Moderado';
      case 'low':
        return 'Baixo';
      case 'rest':
        return 'Descanso';
      default:
        return level;
    }
  }

  // ── Health Alert / Risk Classification ───────────────────────────────────

  /// Color for a health alert string (bom/regular/ruim or good/moderate/poor).
  static Color healthAlertColor(String alert) {
    switch (alert.toLowerCase()) {
      case 'bom':
      case 'good':
        return const Color(0xFF4CAF50);
      case 'regular':
      case 'moderate':
        return const Color(0xFFFF9800);
      case 'ruim':
      case 'poor':
        return const Color(0xFFFF5252);
      default:
        return Colors.grey;
    }
  }

  /// Color for a risk classification string (low/moderate/high/very_high).
  static Color riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
      case 'baixo':
        return const Color(0xFF4CAF50);
      case 'moderate':
      case 'moderado':
        return const Color(0xFFFF9800);
      case 'high':
      case 'alto':
        return const Color(0xFFFF5722);
      case 'very_high':
      case 'muito alto':
        return const Color(0xFFFF5252);
      default:
        return Colors.grey;
    }
  }

  // ── Recovery Score ───────────────────────────────────────────────────────

  /// Color for a recovery score level (high/good/moderate/low/critical).
  static Color recoveryColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return const Color(0xFF4CAF50);
      case 'good':
        return const Color(0xFF8BC34A);
      case 'moderate':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFFFF5722);
      case 'critical':
        return const Color(0xFFFF5252);
      default:
        return Colors.grey;
    }
  }

  /// Short label for a recovery score level.
  static String recoveryLabel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 'Excelente';
      case 'good':
        return 'Bom';
      case 'moderate':
        return 'Moderado';
      case 'low':
        return 'Baixo';
      case 'critical':
        return 'Crítico';
      default:
        return level;
    }
  }

  // ── Quality ──────────────────────────────────────────────────────────────

  /// Color for a signal quality level (excellent/good/moderate/poor/very_poor).
  static Color qualityColor(String level) {
    switch (level.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF4CAF50);
      case 'good':
      case 'bom':
        return const Color(0xFF8BC34A);
      case 'moderate':
        return const Color(0xFFFF9800);
      case 'poor':
      case 'ruim':
        return const Color(0xFFFF5252);
      case 'very_poor':
        return const Color(0xFFB71C1C);
      default:
        return Colors.grey;
    }
  }

  /// Short label for a signal quality level.
  static String qualityLabel(String level) {
    switch (level.toLowerCase()) {
      case 'excellent':
        return 'Excelente';
      case 'good':
        return 'Bom';
      case 'moderate':
        return 'Moderado';
      case 'poor':
        return 'Ruim';
      case 'very_poor':
        return 'Muito ruim';
      default:
        return level;
    }
  }

  // ── Stress Index ─────────────────────────────────────────────────────────

  /// Stress category from raw Baevsky Stress Index value.
  ///
  /// Returns 'very_low' | 'low' | 'normal' | 'moderate' | 'high' | 'very_high'.
  static String stressCategory(double index) {
    if (index < 50) return 'very_low';
    if (index < 100) return 'low';
    if (index < 150) return 'normal';
    if (index < 200) return 'moderate';
    if (index < 400) return 'high';
    return 'very_high';
  }

  /// Color for a stress index value.
  static Color stressColor(double index) {
    return stressCategoryColor(stressCategory(index));
  }

  /// Color for a stress category string.
  static Color stressCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'very_low':
        return const Color(0xFF2196F3);
      case 'low':
        return const Color(0xFF4CAF50);
      case 'normal':
        return const Color(0xFF8BC34A);
      case 'moderate':
        return const Color(0xFFFF9800);
      case 'high':
        return const Color(0xFFFF5722);
      case 'very_high':
        return const Color(0xFFFF5252);
      default:
        return Colors.grey;
    }
  }

  /// Short label for a stress category string.
  static String stressCategoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'very_low':
        return 'Muito baixo';
      case 'low':
        return 'Baixo';
      case 'normal':
        return 'Normal';
      case 'moderate':
        return 'Moderado';
      case 'high':
        return 'Alto';
      case 'very_high':
        return 'Muito alto';
      default:
        return category;
    }
  }
}
