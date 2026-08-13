import 'package:flutter/material.dart';

/// 应用核心配色方案
///
/// 基于 Material 3 设计规范，定义明暗两套主题色。
/// 主色调采用深紫色系，搭配琥珀色作为强调色。
class AppColors {
  AppColors._();

  // ── 种子色 (Material 3 ColorScheme 生成基准) ──
  static const Color seed = Color(0xFF6750A4);

  // ── 亮色主题 ──
  static const Color lightPrimary = Color(0xFF6750A4);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFEADDFF);
  static const Color lightSecondary = Color(0xFF625B71);
  static const Color lightSurface = Color(0xFFFEF7FF);
  static const Color lightOnSurface = Color(0xFF1D1B20);

  // ── 暗色主题 ──
  static const Color darkPrimary = Color(0xFFD0BCFF);
  static const Color darkOnPrimary = Color(0xFF381E72);
  static const Color darkPrimaryContainer = Color(0xFF4F378B);
  static const Color darkSecondary = Color(0xFFCCC2DC);
  static const Color darkSurface = Color(0xFF141218);
  static const Color darkOnSurface = Color(0xFFE6E0E9);

  // ── 功能色 ──
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);

  // ── 笔记优先级标签色 ──
  static const Color priorityLow = Color(0xFF4CAF50);
  static const Color priorityMedium = Color(0xFFFF9800);
  static const Color priorityHigh = Color(0xFFEF4444);
}
