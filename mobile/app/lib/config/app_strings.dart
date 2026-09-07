import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// App language switch. 0 = Tamil, 1 = English (matches the Settings selector
/// and the persisted `app_language` key). `main.dart` rebuilds the whole app
/// when this changes, so every `t(...)` call re-evaluates to the new language.
class LocaleController {
  static const _key = 'app_language';
  static final ValueNotifier<int> lang = ValueNotifier<int>(1); // default English

  static bool get isTamil => lang.value == 0;
  static Locale get locale => isTamil ? const Locale('ta') : const Locale('en');

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    lang.value = p.getInt(_key) ?? 1;
  }

  static Future<void> set(int index) async {
    lang.value = index;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, index);
  }
}

/// Translation tables loaded from the JSON files `assets/i18n/en.json` and
/// `assets/i18n/ta.json` (flat key → string). Loaded once at startup.
class AppStrings {
  static Map<String, String> en = {};
  static Map<String, String> ta = {};

  static Future<void> load() async {
    en = await _loadMap('assets/i18n/en.json');
    ta = await _loadMap('assets/i18n/ta.json');
  }

  static Future<Map<String, String>> _loadMap(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }
}

/// Key-based lookup: `t('home.join_now')`. Returns the active language's value,
/// falling back to English, then to the key itself if missing.
String t(String key) {
  final m = LocaleController.isTamil ? AppStrings.ta : AppStrings.en;
  return m[key] ?? AppStrings.en[key] ?? key;
}

/// Inline fallback helper (kept for any call sites that pass both languages
/// directly). Prefer `t('key')` with the JSON tables.
String tr(String en, String ta) => LocaleController.isTamil ? ta : en;
