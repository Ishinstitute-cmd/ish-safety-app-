import '../../../core/localization/app_locale.dart';

class QuestionModel {
  final String id;
  final String categoryId;
  final String? conceptId;
  final String difficulty;
  final String questionEn;
  final String questionUr;
  final String optionAEn;
  final String optionAUr;
  final String optionBEn;
  final String optionBUr;
  final String optionCEn;
  final String optionCUr;
  final String optionDEn;
  final String optionDUr;
  final String correctOption; // 'a', 'b', 'c', 'd'
  final String explanationEn;
  final String explanationUr;

  QuestionModel({
    required this.id,
    required this.categoryId,
    this.conceptId,
    this.difficulty = 'medium',
    required this.questionEn,
    required this.questionUr,
    required this.optionAEn,
    required this.optionAUr,
    required this.optionBEn,
    required this.optionBUr,
    required this.optionCEn,
    required this.optionCUr,
    required this.optionDEn,
    required this.optionDUr,
    required this.correctOption,
    required this.explanationEn,
    required this.explanationUr,
  });

  String getQuestion(AppLanguage lang) => lang == AppLanguage.urdu ? questionUr : questionEn;
  String getOptionA(AppLanguage lang) => lang == AppLanguage.urdu ? optionAUr : optionAEn;
  String getOptionB(AppLanguage lang) => lang == AppLanguage.urdu ? optionBUr : optionBEn;
  String getOptionC(AppLanguage lang) => lang == AppLanguage.urdu ? optionCUr : optionCEn;
  String getOptionD(AppLanguage lang) => lang == AppLanguage.urdu ? optionDUr : optionDEn;
  String getExplanation(AppLanguage lang) => lang == AppLanguage.urdu ? explanationUr : explanationEn;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      conceptId: json['concept_id'] as String?,
      difficulty: json['difficulty'] as String? ?? 'medium',
      questionEn: json['question_en'] as String? ?? '',
      questionUr: json['question_ur'] as String? ?? '',
      optionAEn: json['option_a_en'] as String? ?? '',
      optionAUr: json['option_a_ur'] as String? ?? '',
      optionBEn: json['option_b_en'] as String? ?? '',
      optionBUr: json['option_b_ur'] as String? ?? '',
      optionCEn: json['option_c_en'] as String? ?? '',
      optionCUr: json['option_c_ur'] as String? ?? '',
      optionDEn: json['option_d_en'] as String? ?? '',
      optionDUr: json['option_d_ur'] as String? ?? '',
      correctOption: (json['correct_option'] as String? ?? 'a').toLowerCase(),
      explanationEn: json['explanation_en'] as String? ?? '',
      explanationUr: json['explanation_ur'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'concept_id': conceptId,
      'difficulty': difficulty,
      'question_en': questionEn,
      'question_ur': questionUr,
      'option_a_en': optionAEn,
      'option_a_ur': optionAUr,
      'option_b_en': optionBEn,
      'option_b_ur': optionBUr,
      'option_c_en': optionCEn,
      'option_c_ur': optionCUr,
      'option_d_en': optionDEn,
      'option_d_ur': optionDUr,
      'correct_option': correctOption,
      'explanation_en': explanationEn,
      'explanation_ur': explanationUr,
    };
  }
}
