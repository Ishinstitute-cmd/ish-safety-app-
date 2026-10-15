import 'package:flutter/material.dart';

enum AppLanguage {
  english('en', 'English', 'English', TextDirection.ltr),
  urdu('ur', 'اردو', 'Urdu', TextDirection.rtl);

  final String code;
  final String nativeName;
  final String englishName;
  final TextDirection direction;

  const AppLanguage(this.code, this.nativeName, this.englishName, this.direction);

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}
