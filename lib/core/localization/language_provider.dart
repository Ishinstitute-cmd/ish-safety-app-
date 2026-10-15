import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'app_locale.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.english) {
    _loadSavedLanguage();
  }

  static const String _boxName = 'settingsBox';
  static const String _keyLanguage = 'selected_language';

  void _loadSavedLanguage() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final String? savedCode = box.get(_keyLanguage) as String?;
        if (savedCode != null) {
          state = AppLanguage.fromCode(savedCode);
        }
      }
    } catch (_) {
      // Fallback to default
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_keyLanguage, language.code);
      }
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final newLanguage = state == AppLanguage.english ? AppLanguage.urdu : AppLanguage.english;
    await setLanguage(newLanguage);
  }
}
