import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/seed_data_provider.dart';
import '../domain/question_model.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

class QuizRepository {
  Future<List<QuestionModel>> getQuestions({String? categoryId, int limit = 10}) async {
    final cacheKey = 'questions_${categoryId ?? "all"}';

    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        var query = SupabaseService.client!.from('questions').select();
        if (categoryId != null) {
          query = query.eq('category_id', categoryId);
        }
        final response = await query.limit(limit);
        final list = (response as List).map((json) => QuestionModel.fromJson(json)).toList();
        await LocalCacheService.setCacheList(cacheKey, list.map((e) => e.toJson()).toList());
        return list;
      } catch (_) {}
    }

    final cached = LocalCacheService.getCacheList(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return cached.map((e) => QuestionModel.fromJson(e)).toList();
    }

    return SeedDataProvider.getQuestions(categoryId: categoryId);
  }

  Future<void> submitScore({
    required String? categoryId,
    required int score,
    required int totalQuestions,
    required String quizType,
  }) async {
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      final user = SupabaseService.client!.auth.currentUser;
      if (user != null) {
        try {
          await SupabaseService.client!.from('scores').insert({
            'user_id': user.id,
            'category_id': categoryId,
            'score': score,
            'total_questions': totalQuestions,
            'quiz_type': quizType,
          });
        } catch (_) {}
      }
    }
  }
}
