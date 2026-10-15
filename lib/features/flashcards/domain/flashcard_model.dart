import '../../../core/localization/app_locale.dart';

class FlashcardModel {
  final String id;
  final String categoryId;
  final String categoryTitleEn;
  final String categoryTitleUr;
  final String termEn;
  final String termUr;
  final String definitionEn;
  final String definitionUr;
  final String? exampleEn;
  final String? exampleUr;
  bool isMastered;

  FlashcardModel({
    required this.id,
    required this.categoryId,
    required this.categoryTitleEn,
    required this.categoryTitleUr,
    required this.termEn,
    required this.termUr,
    required this.definitionEn,
    required this.definitionUr,
    this.exampleEn,
    this.exampleUr,
    this.isMastered = false,
  });

  String getTerm(AppLanguage lang) => lang == AppLanguage.urdu ? termUr : termEn;
  String getDefinition(AppLanguage lang) => lang == AppLanguage.urdu ? definitionUr : definitionEn;
  String? getExample(AppLanguage lang) => lang == AppLanguage.urdu ? exampleUr : exampleEn;

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      categoryTitleEn: json['category_title_en'] as String? ?? 'General Safety',
      categoryTitleUr: json['category_title_ur'] as String? ?? 'عمومی سیفٹی',
      termEn: json['term_en'] as String? ?? '',
      termUr: json['term_ur'] as String? ?? '',
      definitionEn: json['definition_en'] as String? ?? '',
      definitionUr: json['definition_ur'] as String? ?? '',
      exampleEn: json['example_en'] as String?,
      exampleUr: json['example_ur'] as String?,
      isMastered: json['is_mastered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_title_en': categoryTitleEn,
      'category_title_ur': categoryTitleUr,
      'term_en': termEn,
      'term_ur': termUr,
      'definition_en': definitionEn,
      'definition_ur': definitionUr,
      'example_en': exampleEn,
      'example_ur': exampleUr,
      'is_mastered': isMastered,
    };
  }
}
