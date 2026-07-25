import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark switch. Persisted under the same `pref_dark_mode` key the
/// Settings screen already used. `AppColors` reads [isDark] directly (no
/// BuildContext), and `main.dart` rebuilds the whole app when it changes, so
/// every screen that uses `AppColors.*` flips instantly.
class ThemeController {
  static const _key = 'pref_dark_mode';
  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    isDark.value = p.getBool(_key) ?? false;
  }

  static Future<void> set(bool dark) async {
    isDark.value = dark;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, dark);
  }

  static Future<void> toggle() => set(!isDark.value);
}

/// Semantic colors that resolve to a light or dark value based on the current
/// theme. Use these instead of hardcoded hex so screens flip with the toggle.
/// Brand red is intentionally the same in both themes.
class AppColors {
  static bool get _d => ThemeController.isDark.value;

  /// For the few places that need to branch on the theme (gradients, images).
  static bool get isDark => _d;

  // Surfaces
  static Color get bg => _d ? const Color(0xFF121212) : const Color(0xFFF6F6F6);
  static Color get surface => _d ? const Color(0xFF1E1E1E) : Colors.white;
  static Color get surfaceAlt => _d ? const Color(0xFF262626) : const Color(0xFFF0F0F0);

  // Text
  static Color get textPrimary => _d ? const Color(0xFFF3F3F3) : const Color(0xFF1A1A1A);
  static Color get textSecondary => _d ? const Color(0xFFB5B5B5) : const Color(0xFF4A4949);
  static Color get textMuted => _d ? const Color(0xFF8C8C8C) : const Color(0xFF999999);

  // Lines / dividers
  static Color get border => _d ? const Color(0xFF303030) : const Color(0xFFEEEEEE);

  // Brand (constant across themes)
  static const Color red = Color(0xFF9F1D1F);
  static const Color redBright = Color(0xFFE40101);

  /// Overlay for icon/chip tints that need to sit on [surface].
  static Color get faintRed => red.withValues(alpha: _d ? 0.18 : 0.06);
}
