import '../../quiz/domain/question_model.dart';

class ReviewItemModel {
  final String questionId;
  final QuestionModel question;
  final String conceptId;
  final int correctCount;
  final int incorrectCount;
  final String status; // 'review' | 'mastered'
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  const ReviewItemModel({
    required this.questionId,
    required this.question,
    required this.conceptId,
    required this.correctCount,
    required this.incorrectCount,
    required this.status,
    required this.nextReviewAt,
    required this.lastReviewedAt,
  });

  bool get isDue => nextReviewAt.isBefore(DateTime.now()) && correctCount < 2;
  bool get isMastered => correctCount >= 2 || status == 'mastered';
  bool get isUpcoming => !isDue && !isMastered;

  int get stage {
    if (correctCount >= 2) return 3;
    if (correctCount == 1) return 2;
    return 1;
  }

  String get stageLabelEn {
    switch (stage) {
      case 1:
        return 'Stage 1 (Interval: 1 Day)';
      case 2:
        return 'Stage 2 (Interval: 3 Days)';
      default:
        return 'Graduated (Mastered)';
    }
  }

  String get stageLabelUr {
    switch (stage) {
      case 1:
        return 'مرحلہ 1 (وقفہ: 1 دن)';
      case 2:
        return 'مرحلہ 2 (وقفہ: 3 دن)';
      default:
        return 'کامیاب (مکمل مہارت)';
    }
  }

  factory ReviewItemModel.fromJson(Map<String, dynamic> json, QuestionModel question) {
    return ReviewItemModel(
      questionId: json['question_id'] as String? ?? question.id,
      question: question,
      conceptId: json['concept_id'] as String? ?? question.conceptId,
      correctCount: json['correct_count'] as int? ?? 0,
      incorrectCount: json['incorrect_count'] as int? ?? 1,
      status: json['status'] as String? ?? 'review',
      nextReviewAt: json['next_review_at'] != null
          ? DateTime.tryParse(json['next_review_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastReviewedAt: json['last_reviewed_at'] != null
          ? DateTime.tryParse(json['last_reviewed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'concept_id': conceptId,
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
      'status': status,
      'next_review_at': nextReviewAt.toIso8601String(),
      'last_reviewed_at': lastReviewedAt.toIso8601String(),
    };
  }

  ReviewItemModel copyWith({
    int? correctCount,
    int? incorrectCount,
    String? status,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
  }) {
    return ReviewItemModel(
      questionId: questionId,
      question: question,
      conceptId: conceptId,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      status: status ?? this.status,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}
