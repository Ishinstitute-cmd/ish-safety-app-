import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../localization/app_locale.dart';

enum ControlLevel {
  elimination(
    rank: 1,
    nameEn: 'Elimination',
    nameUr: 'خاتمہ (Elimination)',
    descEn: 'Physically remove the hazard from workplace (Most Effective)',
    descUr: 'کام کی جگہ سے خطرے کو مکمل طور پر ختم کرنا (سب سے زیادہ مؤثر)',
    color: AppColors.controlElimination,
  ),
  substitution(
    rank: 2,
    nameEn: 'Substitution',
    nameUr: 'متبادل (Substitution)',
    descEn: 'Replace the hazard with a safer chemical, process, or machine',
    descUr: 'خطرے کو محفوظ کیمیکل یا مشینری سے تبدیل کرنا',
    color: AppColors.controlSubstitution,
  ),
  engineering(
    rank: 3,
    nameEn: 'Engineering Controls',
    nameUr: 'انجینئرنگ کنٹرولز',
    descEn: 'Isolate people from the hazard with physical barriers or enclosures',
    descUr: 'ملازمین کو رکاوٹوں اور حفاظتی انکلوژرز کے ذریعے خطرے سے دور رکھنا',
    color: AppColors.controlEngineering,
  ),
  administrative(
    rank: 4,
    nameEn: 'Administrative Controls',
    nameUr: 'انتظامی کنٹرولز',
    descEn: 'Change the way people work (Work procedures, signage, training)',
    descUr: 'کام کے طریقے، طریقہ کار، احتیاطی بورڈز اور تربیت میں تبدیلی',
    color: AppColors.controlAdministrative,
  ),
  ppe(
    rank: 5,
    nameEn: 'PPE (Personal Protective Equipment)',
    nameUr: 'ذاتی حفاظتی آلات (PPE)',
    descEn: 'Protect the individual worker with safety gear (Last line of defense)',
    descUr: 'ورکر کو حفاظتی سامان پہنا کر محفوظ کرنا (آخری دفاعی لائن)',
    color: AppColors.controlPPE,
  );

  final int rank;
  final String nameEn;
  final String nameUr;
  final String descEn;
  final String descUr;
  final Color color;

  const ControlLevel({
    required this.rank,
    required this.nameEn,
    required this.nameUr,
    required this.descEn,
    required this.descUr,
    required this.color,
  });

  String getName(AppLanguage language) => language == AppLanguage.urdu ? nameUr : nameEn;
  String getDescription(AppLanguage language) => language == AppLanguage.urdu ? descUr : descEn;

  static ControlLevel fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'elimination':
        return ControlLevel.elimination;
      case 'substitution':
        return ControlLevel.substitution;
      case 'engineering':
        return ControlLevel.engineering;
      case 'administrative':
        return ControlLevel.administrative;
      case 'ppe':
      default:
        return ControlLevel.ppe;
    }
  }
}
