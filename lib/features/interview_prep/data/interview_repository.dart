import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/seed_data_provider.dart';
import '../domain/interview_question_model.dart';

final interviewRepositoryProvider = Provider<InterviewRepository>((ref) {
  return InterviewRepository();
});

class InterviewRepository {
  bool isBookmarked(String questionId) {
    try {
      if (Hive.isBoxOpen(HiveBoxes.bookmarks)) {
        return Hive.box(HiveBoxes.bookmarks).get('interview_$questionId', defaultValue: false) as bool;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> toggleBookmark(String questionId) async {
    final current = isBookmarked(questionId);
    final newState = !current;

    try {
      if (Hive.isBoxOpen(HiveBoxes.bookmarks)) {
        await Hive.box(HiveBoxes.bookmarks).put('interview_$questionId', newState);
      }
    } catch (_) {}

    // Sync with Supabase if online and logged in
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      final user = SupabaseService.client!.auth.currentUser;
      if (user != null) {
        try {
          if (newState) {
            await SupabaseService.client!.from('bookmarks').upsert({
              'user_id': user.id,
              'item_type': 'interview',
              'item_id': questionId,
            });
          } else {
            await SupabaseService.client!
                .from('bookmarks')
                .delete()
                .eq('user_id', user.id)
                .eq('item_type', 'interview')
                .eq('item_id', questionId);
          }
        } catch (_) {}
      }
    }

    return newState;
  }

  Future<List<InterviewQuestionModel>> getQuestions({String? role, bool bookmarkedOnly = false}) async {
    List<InterviewQuestionModel> questions = [];
    final cacheKey = 'interview_questions_${role ?? "all"}';

    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        var query = SupabaseService.client!.from('interview_questions').select();
        if (role != null) {
          query = query.eq('role', role);
        }
        final response = await query.order('order_index', ascending: true);
        questions = (response as List).map((json) => InterviewQuestionModel.fromJson(json)).toList();
        await LocalCacheService.setCacheList(cacheKey, questions.map((e) => e.toJson()).toList());
      } catch (_) {}
    }

    if (questions.isEmpty) {
      final cached = LocalCacheService.getCacheList(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        questions = cached.map((e) => InterviewQuestionModel.fromJson(e)).toList();
      } else {
        questions = SeedDataProvider.getInterviewQuestions();
        if (role != null) {
          questions = questions.where((q) => q.role == role).toList();
        }
      }
    }

    // Attach bookmark states
    for (final q in questions) {
      q.isBookmarked = isBookmarked(q.id);
    }

    if (bookmarkedOnly) {
      return questions.where((q) => q.isBookmarked).toList();
    }

    return questions;
  }
}
