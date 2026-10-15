import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../storage/hive_boxes.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const String _keyTheme = 'app_theme_mode';

  void _loadTheme() {
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        final box = Hive.box(HiveBoxes.settings);
        final String? saved = box.get(_keyTheme) as String?;
        if (saved == 'dark') {
          state = ThemeMode.dark;
        } else if (saved == 'light') {
          state = ThemeMode.light;
        }
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        final box = Hive.box(HiveBoxes.settings);
        await box.put(_keyTheme, newMode == ThemeMode.dark ? 'dark' : 'light');
      }
    } catch (_) {}
  }
}
