import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/seed_data_provider.dart';
import '../../../core/utils/spaced_repetition.dart';
import '../../quiz/domain/question_model.dart';
import '../domain/review_item_model.dart';

final reviewQueueRepositoryProvider = Provider<ReviewQueueRepository>((ref) {
  return ReviewQueueRepository();
});

final reviewQueueItemsProvider = FutureProvider<List<ReviewItemModel>>((ref) async {
  final repo = ref.watch(reviewQueueRepositoryProvider);
  return repo.getReviewItems();
});

class ReviewQueueRepository {
  Future<List<ReviewItemModel>> getReviewItems() async {
    // 1. Fetch all known questions to map
    final allQuestions = SeedDataProvider.getQuestions();
    final questionMap = {for (var q in allQuestions) q.id: q};

    // 2. Read from LocalCache
    final localEntries = LocalCacheService.getReviewQueue();

    // 3. If online and authenticated, read from Supabase user_mastery
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      final user = SupabaseService.client!.auth.currentUser;
      if (user != null) {
        try {
          final response = await SupabaseService.client!
              .from('user_mastery')
              .select()
              .eq('user_id', user.id);
          
          if (response is List && response.isNotEmpty) {
            final List<ReviewItemModel> remoteItems = [];
            for (final row in response) {
              final qId = row['question_id'] as String? ?? '';
              final question = questionMap[qId] ?? _fallbackQuestion(qId, row['concept_id'] as String? ?? '');
              remoteItems.add(
                ReviewItemModel(
                  questionId: qId,
                  question: question,
                  conceptId: row['concept_id'] as String? ?? question.conceptId,
                  correctCount: (row['correct_count'] as int?) ?? 0,
                  incorrectCount: (row['incorrect_count'] as int?) ?? 1,
                  status: (row['status'] as String?) ?? 'review',
                  nextReviewAt: DateTime.tryParse(row['next_review_at'] as String? ?? '') ?? DateTime.now(),
                  lastReviewedAt: DateTime.tryParse(row['last_reviewed_at'] as String? ?? '') ?? DateTime.now(),
                ),
              );
            }
            if (remoteItems.isNotEmpty) {
              return remoteItems;
            }
          }
        } catch (_) {}
      }
    }

    // 4. Return local items if present
    if (localEntries.isNotEmpty) {
      final items = <ReviewItemModel>[];
      for (final json in localEntries) {
        final qId = json['question_id'] as String? ?? '';
        final q = questionMap[qId] ?? _fallbackQuestion(qId, json['concept_id'] as String? ?? '');
        items.add(ReviewItemModel.fromJson(json, q));
      }
      return items;
    }

    // 5. Default realistic seed items for immediate demonstration
    final seedItems = _getSeedReviewItems(questionMap);
    for (final item in seedItems) {
      await LocalCacheService.addToReviewQueue(item.questionId, item.toJson());
    }
    return seedItems;
  }

  Future<void> recordAnswer({
    required String questionId,
    required bool isCorrect,
    required int currentCorrectCount,
  }) async {
    final nextConsecutive = isCorrect ? (currentCorrectCount + 1) : 0;
    final nextReview = SpacedRepetitionHelper.calculateNextReview(
      consecutiveCorrect: nextConsecutive,
      isAnswerCorrect: isCorrect,
    );
    final status = SpacedRepetitionHelper.calculateStatus(
      consecutiveCorrect: nextConsecutive,
      isAnswerCorrect: isCorrect,
    );

    final updatedData = {
      'question_id': questionId,
      'correct_count': nextConsecutive,
      'incorrect_count': isCorrect ? 0 : 1,
      'status': status,
      'next_review_at': nextReview.toIso8601String(),
      'last_reviewed_at': DateTime.now().toIso8601String(),
    };

    // Save locally
    await LocalCacheService.addToReviewQueue(questionId, updatedData);

    // Save remotely if Supabase is active
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      final user = SupabaseService.client!.auth.currentUser;
      if (user != null) {
        try {
          await SupabaseService.client!.from('user_mastery').upsert({
            'user_id': user.id,
            'question_id': questionId,
            'correct_count': nextConsecutive,
            'status': status,
            'next_review_at': nextReview.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    }
  }

  QuestionModel _fallbackQuestion(String id, String conceptId) {
    return QuestionModel(
      id: id,
      categoryId: '11111111-1111-1111-1111-111111111101',
      conceptId: conceptId.isNotEmpty ? conceptId : '22222222-2222-2222-2222-222222222201',
      difficulty: 'medium',
      questionEn: 'Workplace Safety Drill Question',
      questionUr: 'کام کی جگہ پر سیفٹی کا سوال',
      optionAEn: 'Option A',
      optionAUr: 'آپشن اے',
      optionBEn: 'Option B (Correct)',
      optionBUr: 'آپشن بی (درست)',
      optionCEn: 'Option C',
      optionCUr: 'آپشن سی',
      optionDEn: 'Option D',
      optionDUr: 'آپشن ڈی',
      correctOption: 'b',
      explanationEn: 'Review the concept lesson to reinforce this safety standard.',
      explanationUr: 'اس سیفٹی اصول کو پختہ کرنے کے لیے متعلقہ کارڈ کا مطالعہ کریں۔',
    );
  }

  List<ReviewItemModel> _getSeedReviewItems(Map<String, QuestionModel> questionMap) {
    final now = DateTime.now();
    final q1 = questionMap['33333333-3333-3333-3333-333333333301'] ?? _fallbackQuestion('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222201');
    final q2 = questionMap['33333333-3333-3333-3333-333333333304'] ?? _fallbackQuestion('33333333-3333-3333-3333-333333333304', '22222222-2222-2222-2222-222222222204');
    final q3 = questionMap['33333333-3333-3333-3333-333333333302'] ?? _fallbackQuestion('33333333-3333-3333-3333-333333333302', '22222222-2222-2222-2222-222222222202');

    return [
      // Due Today (Stage 1 - 0 consecutive correct, next review in the past/today)
      ReviewItemModel(
        questionId: q1.id,
        question: q1,
        conceptId: q1.conceptId,
        correctCount: 0,
        incorrectCount: 1,
        status: 'review',
        nextReviewAt: now.subtract(const Duration(hours: 2)),
        lastReviewedAt: now.subtract(const Duration(days: 1)),
      ),
      // Upcoming (Stage 2 - 1 consecutive correct, next review in 2 days)
      ReviewItemModel(
        questionId: q2.id,
        question: q2,
        conceptId: q2.conceptId,
        correctCount: 1,
        incorrectCount: 1,
        status: 'review',
        nextReviewAt: now.add(const Duration(days: 2)),
        lastReviewedAt: now.subtract(const Duration(days: 1)),
      ),
      // Mastered (2 consecutive correct - Graduated!)
      ReviewItemModel(
        questionId: q3.id,
        question: q3,
        conceptId: q3.conceptId,
        correctCount: 2,
        incorrectCount: 0,
        status: 'mastered',
        nextReviewAt: now.add(const Duration(days: 6)),
        lastReviewedAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
