import '../../../core/localization/app_locale.dart';

class InterviewQuestionModel {
  final String id;
  final String role; // 'HSE Officer', 'Safety Supervisor'
  final String questionEn;
  final String questionUr;
  final String modelAnswerEn;
  final String modelAnswerUr;
  final List<String> keyTakeawaysEn;
  final List<String> keyTakeawaysUr;
  bool isBookmarked;

  InterviewQuestionModel({
    required this.id,
    required this.role,
    required this.questionEn,
    required this.questionUr,
    required this.modelAnswerEn,
    required this.modelAnswerUr,
    required this.keyTakeawaysEn,
    required this.keyTakeawaysUr,
    this.isBookmarked = false,
  });

  String getQuestion(AppLanguage lang) => lang == AppLanguage.urdu ? questionUr : questionEn;
  String getModelAnswer(AppLanguage lang) => lang == AppLanguage.urdu ? modelAnswerUr : modelAnswerEn;
  List<String> getKeyTakeaways(AppLanguage lang) => lang == AppLanguage.urdu ? keyTakeawaysUr : keyTakeawaysEn;

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'HSE Officer',
      questionEn: json['question_en'] as String? ?? '',
      questionUr: json['question_ur'] as String? ?? '',
      modelAnswerEn: json['model_answer_en'] as String? ?? '',
      modelAnswerUr: json['model_answer_ur'] as String? ?? '',
      keyTakeawaysEn: (json['key_takeaways_en'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      keyTakeawaysUr: (json['key_takeaways_ur'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'question_en': questionEn,
      'question_ur': questionUr,
      'model_answer_en': modelAnswerEn,
      'model_answer_ur': modelAnswerUr,
      'key_takeaways_en': keyTakeawaysEn,
      'key_takeaways_ur': keyTakeawaysUr,
      'is_bookmarked': isBookmarked,
    };
  }
}
